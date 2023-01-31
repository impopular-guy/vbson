module vbson

import encoding.binary
import math
import time

// ElementType is a list of element types that are currently supported in this module.
// Reference: [bsonspec.org](https://bsonspec.org/spec.html)
pub enum ElementType {
	e_double = 0x01
	e_string = 0x02
	e_document
	e_array
	e_binary
	e_object_id = 0x07
	e_bool = 0x08
	e_utc_datetime
	e_null = 0x0A
	e_int = 0x10
	e_timestamp
	e_i64 = 0x12
	e_decimal128
}

// List of unsupported/deprecated element types and binary sub types.
pub const (
	unused_types = [0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xFF, 0x7F]
)

// BsonAny is a SumType used to store multiple BsonElement types in single array.
pub type BsonAny = Binary
	| BsonDoc
	| Null
	| ObjectID
	| []BsonAny
	| bool
	| f64
	| i64
	| int
	| string
	| time.Time

// BsonDoc is a helper struct to decode/encode bson data. Can be used in situations where input
// in specific format is converted into a `BsonDoc`.
pub struct BsonDoc {
pub mut:
	n_elems int
	// no. of elements in the document
	elements map[string]BsonAny
	// array of elements of the document
}

pub struct Null {
}

// ObjectID is a wrapper for mongo-style onjectID
pub struct ObjectID {
	id string
}

// Binary is a wrapper for binary data. Binary sub-type is stored in `b_type` and data is in the form of a byte array.
pub struct Binary {
pub mut:
	b_type int
	data   []u8
}

fn encode_int(val int) []u8 {
	mut b := []u8{len: 4, init: 0}
	binary.little_endian_put_u32(mut b, u32(val))
	return b
}

fn encode_i64(val i64) []u8 {
	mut b := []u8{len: 8, init: 0}
	binary.little_endian_put_u64(mut b, u64(val))
	return b
}

fn encode_u64(val u64) []u8 {
	mut b := []u8{len: 8, init: 0}
	binary.little_endian_put_u64(mut b, val)
	return b
}

fn encode_f64(val f64) []u8 {
	u_val := math.f64_bits(val)
	return encode_u64(u_val)
}

fn encode_cstring(str string) []u8 {
	mut b := []u8{}
	b << str.bytes()
	b << u8(0x00)
	return b
}

fn encode_string(str string) []u8 {
	mut b := []u8{}
	b << str.bytes()
	b << u8(0x00)
	b.prepend(encode_int(b.len))
	return b
}

fn encode_array(elem []BsonAny) []u8 {
	mut doc := BsonDoc{}
	for i, v in elem {
		doc.elements['${i}'] = v
	}
	doc.n_elems = elem.len
	return encode_document(doc)
}

fn encode_objectid(elem ObjectID) []u8 {
	return elem.id.bytes()
}

fn encode_utc(elem time.Time) []u8 {
	return encode_i64(elem.unix_time_milli())
}

fn encode_binary(elem Binary) []u8 {
	mut buf := []u8{}
	buf << encode_int(elem.data.len)
	buf << u8(elem.b_type)
	buf << elem.data
	return buf
}

fn (elem BsonAny) get_e_type() ElementType {
	return match elem {
		f64 { .e_double }
		string { .e_string }
		BsonDoc { .e_document }
		[]BsonAny { .e_array }
		bool { .e_bool }
		int { .e_int }
		i64 { .e_i64 }
		Null { .e_null }
		ObjectID { .e_object_id }
		time.Time { .e_utc_datetime }
		Binary { .e_binary }
	}
}

fn (elem BsonAny) encode() []u8 {
	return match elem {
		f64 { encode_f64(elem) }
		string { encode_string(elem) }
		BsonDoc { encode_document(elem) }
		[]BsonAny { encode_array(elem) }
		bool { [u8(elem)] }
		int { encode_int(int(elem)) }
		i64 { encode_i64(elem) }
		Null { []u8{} }
		ObjectID { encode_objectid(elem) }
		time.Time { encode_utc(elem) }
		Binary { encode_binary(elem) }
	}
}

fn encode_document(doc BsonDoc) []u8 {
	mut buf := []u8{}
	for name, elem in doc.elements {
		buf << u8(elem.get_e_type())
		buf << encode_cstring(name)
		buf << elem.encode()
	}
	buf << u8(0x00)
	buf.prepend(encode_int(buf.len + 4))
	return buf
}

// encode_bsondoc takes struct `vbson.BsonDoc` as input and
// returns a bson in string format
pub fn encode_bsondoc(doc BsonDoc) string {
	return encode_document(doc).bytestr()
}

// Decode logic
fn decode_int(data string, cur int) int {
	b := data[cur..(cur + 4)].bytes()
	return int(binary.little_endian_u32(b))
}

fn decode_i64(data string, cur int) i64 {
	b := data[cur..(cur + 8)].bytes()
	return i64(binary.little_endian_u64(b))
}

fn decode_u64(data string, cur int) u64 {
	b := data[cur..(cur + 8)].bytes()
	return binary.little_endian_u64(b)
}

fn decode_f64(data string, cur int) f64 {
	u_val := decode_u64(data, cur)
	return math.f64_from_bits(u_val)
}

fn decode_cstring(data string, cur int) (string, int) {
	mut n := 0
	for data[cur + n] != 0x00 {
		n += 1
	}
	return data[cur..(cur + n)], n + 1
}

fn decode_string(data string, cur int) (string, int) {
	str_len := decode_int(data, cur)
	return data[(cur + 4)..(cur + 4 + str_len - 1)], str_len + 4
}

fn decode_objectid(data string, cur int) ObjectID {
	return ObjectID{data[cur..(cur + 12)]}
}

fn decode_utc(data string, cur int) time.Time {
	u := decode_i64(data, cur)
	return time.unix2(i64(u / 1000), int(u % 1000) * 1000)
}

fn decode_element(data string, cur int, e_type ElementType) ?(BsonAny, int) {
	match e_type {
		.e_double {
			return decode_f64(data, cur), 8
		}
		.e_string {
			str, dcur := decode_string(data, cur)
			return BsonAny(str), dcur
		}
		.e_document {
			dcur := decode_int(data, cur)
			elem := decode_document(data, cur + 4, cur + dcur)?
			return elem, dcur
		}
		.e_array {
			mut b := []BsonAny{}
			dcur := decode_int(data, cur)
			elem := decode_document(data, cur + 4, cur + dcur)?
			for _, v in elem.elements {
				b << v
			}
			return b, dcur
		}
		.e_bool {
			return data[cur] == 0x01, 1
		}
		.e_int {
			return decode_int(data, cur), 4
		}
		.e_i64 {
			return decode_i64(data, cur), 8
		}
		.e_null {
			return Null{}, 0
		}
		.e_object_id {
			return decode_objectid(data, cur), 12
		}
		.e_utc_datetime {
			return decode_utc(data, cur), 8
		}
		.e_binary {
			b_size := decode_int(data, cur)
			mut elem := Binary{}
			elem.b_type = int(data[cur + 4])
			elem.data = data[(cur + 5)..(cur + 5 + b_size)].bytes()
			return elem, 4 + 1 + b_size
		}
		else {
			return error('decode error: ${e_type} is not supported')
		}
	}
}

fn decode_document(data string, start int, end int) ?BsonDoc {
	mut cur := start
	mut doc := BsonDoc{}
	for cur < end {
		if data[cur] == 0x00 {
			break
		}
		if int(data[cur]) in vbson.unused_types {
			return error('decode error: ElementType type `${data[cur]}` is not supported.')
		}
		e_type := unsafe {
			ElementType(data[cur])
		}
		cur++

		name, dcur := decode_cstring(data, cur)
		cur += dcur
		elem, dcur1 := decode_element(data, cur, e_type)?
		cur += dcur1
		doc.elements[name] = elem
		doc.n_elems++
	}
	if cur < end - 1 {
		return error('decode error: Corrupted data.')
	}
	return doc
}

fn validate_string(data string) ?int {
	if data.len <= 4 {
		return error('decode error: Data must be more than 4 bytes.')
	}
	length := decode_int(data, 0)
	if length != data.len {
		return error('decode error: BSON data length mismatch.')
	}
	return length
}

// decode_to_bsondoc takes in bson string input and returns
// `vbson.BsonDoc` as output.
// It returns error if encoded data is incorrect.
pub fn decode_to_bsondoc(data string) ?BsonDoc {
	length := validate_string(data) or { return err }
	if length == 5 {
		return BsonDoc{}
	}
	doc := decode_document(data, 4, length) or { return err }
	return doc
}

fn convert_to_bsondoc[T](data T) ?BsonDoc {
	mut doc := BsonDoc{}
	$for field in T.fields {
		if 'bsonskip' !in field.attrs {
			$if field.typ is string {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is bool {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is int {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is i64 {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is f32 {
				doc.elements[field.name] = BsonAny(f64(data.$(field.name)))
			} $else $if field.typ is f64 {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is []string {
				mut sa := []BsonAny{}
				for s in data.$(field.name) {
					sa << BsonAny(s)
				}
				doc.elements[field.name] = sa
			} $else $if field.typ is []bool {
				mut ba := []BsonAny{}
				for b in data.$(field.name) {
					ba << BsonAny(b)
				}
				doc.elements[field.name] = ba
			} $else $if field.typ is []int {
				mut ia := []BsonAny{}
				for i in data.$(field.name) {
					ia << BsonAny(i)
				}
				doc.elements[field.name] = ia
			} $else $if field.typ is []i64 {
				mut i6a := []BsonAny{}
				for i6 in data.$(field.name) {
					i6a << BsonAny(i6)
				}
				doc.elements[field.name] = i6a
			} $else $if field.typ is []f32 {
				mut f3a := []BsonAny{}
				for f3 in data.$(field.name) {
					f3a << BsonAny(f64(f3))
				}
				doc.elements[field.name] = f3a
			} $else $if field.typ is []f64 {
				mut fa := []BsonAny{}
				for f in data.$(field.name) {
					fa << BsonAny(f)
				}
				doc.elements[field.name] = fa
			} $else $if field.typ is Null {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is ObjectID {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is time.Time {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is Binary {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else {
				return error('encode error: Unsupported Type: `${field.name}` Use attr [bsonskip] to ignore this field.')
			}
			doc.n_elems++
		}
	}
	return doc
}

// encode takes struct `T` as input where `T` can be any user-defined struct.
// Use attribute [bsonskip] to skip encoding of any field from a struct.
// It cannot encode variables of `fixed length arrays`.
pub fn encode[T](data T) ?string {
	mut doc := BsonDoc{}
	doc = convert_to_bsondoc[T](data)?
	return encode_document(doc).bytestr()
}

fn convert_from_bsondoc[T](doc BsonDoc) ?T {
	mut res := T{}
	$for field in T.fields {
		if field.name in doc.elements {
			elem := doc.elements[field.name] or { return error('Failed to get element.') }
			$if field.typ is string {
				res.$(field.name) = elem as string
			} $else $if field.typ is bool {
				res.$(field.name) = elem as bool
			} $else $if field.typ is int {
				res.$(field.name) = elem as int
			} $else $if field.typ is i64 {
				res.$(field.name) = elem as i64
			} $else $if field.typ is f32 {
				f := elem as f64
				res.$(field.name) = f32(f)
			} $else $if field.typ is f64 {
				res.$(field.name) = elem as f64
			} $else $if field.typ is []string {
				sa := elem as []BsonAny
				for v in sa {
					res.$(field.name) << v as string
				}
			} $else $if field.typ is []bool {
				ba := elem as []BsonAny
				for v in ba {
					res.$(field.name) << v as bool
				}
			} $else $if field.typ is []int {
				ia := elem as []BsonAny
				for v in ia {
					res.$(field.name) << v as int
				}
			} $else $if field.typ is []i64 {
				i6a := elem as []BsonAny
				for v in i6a {
					res.$(field.name) << v as i64
				}
			} $else $if field.typ is []f32 {
				f3a := elem as []BsonAny
				for v in f3a {
					res.$(field.name) << f32(v as f64)
				}
			} $else $if field.typ is []f64 {
				fa := elem as []BsonAny
				for v in fa {
					res.$(field.name) << v as f64
				}
			} $else $if field.typ is Null {
				res.$(field.name) = elem as Null
			} $else $if field.typ is ObjectID {
				res.$(field.name) = elem as ObjectID
			} $else $if field.typ is time.Time {
				res.$(field.name) = elem as time.Time
			} $else $if field.typ is Binary {
				res.$(field.name) = elem as Binary
			} $else {
				return error('decode error: Key `${field.name}` not supported')
			}
		} else if 'bsonskip' in field.attrs {
		} else {
			return error('decode error: Key `${field.name}` not found.')
		}
	}
	return res
}

// decode takes bson string as input and returns value of struct `T`.
// `T` should comply with given encoded string else it returns error
pub fn decode[T](data string) ?T {
	length := validate_string(data) or { return err }
	if length == 5 {
		return T{}
	}
	doc := decode_document(data, 4, length) or { return err }
	res := convert_from_bsondoc[T](doc)?
	return res
}
