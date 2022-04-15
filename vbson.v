module vbson

import encoding.binary

// This enum is a list of element types that are currently supported in this module.
// Reference: [bsonspec.org](https://bsonspec.org/spec.html)
pub enum ElementType {
	// e_00 = 0x00
	// e_double = 0x01
	e_string = 0x02
	// e_document
	// e_array
	// e_binary
	// e_object_id = 0x07
	e_bool = 0x08
	// e_utc_datetime
	// e_null = 0x0A
	e_int = 0x10
	// e_timestamp
	e_i64 = 0x12
	// e_decimal128
}

// This enum contains currently supported binary subtypes.
pub enum BinarySubType {
	s_generic = 0x00
	s_uuid = 0x04
	s_md5
}

// List of unsupported/deprecated element types and binary sub types.
pub const (
	unused_types = [0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xFF, 0x7F]
	unused_subtypes = [0x01, 0x02, 0x03, 0x06, 0x80]
)

// Helper struct to decode/encode bson data. Can be used in situations where input
// in specific format is converted into a `BsonDoc`.
pub struct BsonDoc{
pub mut:
	n_elems u32 // no. of elements in the document
	elem_pos map[string]u32 // stores position of elements for easier search
	elements []ElemSumType // array of elements of the document
}

// SumType used to store multiple BsonElement types in single array.
// There will be total 7 basic types: `bool, int, i64, u64, f64, Uint128, string`
pub type ElemSumType = BsonElement<string> | BsonElement<bool> | BsonElement<int> | BsonElement<i64>

// Helper struct for storing different element types.
// `T` can be one of the following types only `bool, int, i64, u64, f64, Uint128, string`.
// NOTE: `Uint128` can be used by importing `math.unsigned`
pub struct BsonElement<T> {
pub mut:
	name string // key name
	e_type ElementType
	value T
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

fn (field ElemSumType) encode() []u8 {
	return match field {
		BsonElement<string> { encode_string(field.value) }
		BsonElement<bool> { [u8(field.value)] }
		BsonElement<int> { encode_int(int(field.value)) }
		BsonElement<i64> { encode_i64(field.value) }
	}
}

fn encode_document(doc BsonDoc) []u8 {
	mut buf := []u8{}
	for i := 0; i < doc.n_elems; i++ {
		field := doc.elements[i]
		buf << u8(field.e_type)
		buf << encode_cstring(field.name)
		buf << field.encode()
	}
	buf << u8(0x00)
	buf.prepend(encode_int(buf.len + 4))
	return buf
}

pub fn encode_bson_doc(doc BsonDoc) string {
	return encode_document(doc).bytestr()
}

// `T` can be any user-defined struct or `map[string]<T1>` where `T1` is any supported type.
pub fn encode<T>(data T) string {
	mut doc := BsonDoc{}
	if typeof(data).name.contains('map[string]') {

	} else {
		$for field in T.fields {
			doc.n_elems++
			$if field.typ is string {
				doc.elements << BsonElement<string>{field.name, .e_string, data.$(field.name)}
			} $else $if field.typ is bool {
				doc.elements << BsonElement<bool>{field.name, .e_bool, data.$(field.name)}
			} $else $if field.typ is int {
				doc.elements << BsonElement<int>{field.name, .e_int, data.$(field.name)}
			} $else $if field.typ is i64 {
				doc.elements << BsonElement<i64>{field.name, .e_i64, data.$(field.name)}
			}
		}
	}
	return encode_document(doc).bytestr()
}

// Decode logic
fn decode_int(data string, cur int) int {
	b := data[cur .. (cur+4)].bytes()
	return int(binary.little_endian_u32(b))
}

fn decode_i64(data string, cur int) i64 {
	b := data[cur .. (cur+8)].bytes()
	return i64(binary.little_endian_u64(b))
}

fn decode_u64(data string, cur int) u64 {
	b := data[cur .. (cur+8)].bytes()
	return binary.little_endian_u64(b)
}

fn decode_cstring(data string, cur int) (string, int) {
	mut n := 0
	for data[cur + n] != 0x00 {
		n += 1
	}
	return data[cur..(cur + n)], (n+1)
}

fn decode_string(data string, cur int) (string, int) {
	str_len := decode_int(data, cur)
	return data[(cur + 4)..(cur + 4 + str_len-1)], (str_len + 4)
}

fn (mut field ElemSumType) decode(data string, cur int) int {
	mut dcur := 0
	match mut field {
		BsonElement<string> {
			field.value, dcur = decode_string(data, cur)
		}
		BsonElement<bool> {
			field.value = (data[cur] == 0x01)
			dcur = 1
		}
		BsonElement<int> {
			field.value = decode_int(data, cur)
			dcur = 4
		}
		BsonElement<i64> {
			field.value = decode_i64(data, cur)
			dcur = 8
		}
	}
	return dcur
}

fn decode_document(data string, length int, cursor int) ?BsonDoc {
	mut cur := cursor
	mut doc := BsonDoc{}
	for cur < length {
		if data[cur] == 0x00 {
			break
		}
		e_type := ElementType(data[cur])
		if int(e_type) in unused_types {
			return error('ElementType type "${data[cur]}" is not supported.')
		}
		cur++

		name, dcur := decode_cstring(data, cur)
		cur += dcur
		mut field := match e_type {
			.e_string { ElemSumType(BsonElement<string>{}) }
			.e_bool { ElemSumType(BsonElement<bool>{}) }
			.e_int { ElemSumType(BsonElement<int>{}) }
			.e_i64 { ElemSumType(BsonElement<i64>{}) }
		}
		field.name = name
		field.e_type = e_type
		cur += field.decode(data, cur)
		doc.elements << field
		doc.elem_pos[name] = doc.n_elems
		doc.n_elems++
	}
	if cur < length-1 {
		return error("Corrupted data.")
	}
	return doc
}

fn validate_string(data string) ?int {
	if data.len <= 4 {
		return error('Data must be more than 4 bytes.')
	}
	length := decode_int(data, 0)
	if length != data.len {
		return error('BSON data length mismatch.')
	}
	return length
}

// Returns error if encoded data is incorrect.
pub fn decode_to_bson_doc(data string) ?BsonDoc {
	length := validate_string(data) or { return err }
	if length == 5 {
		return BsonDoc{}
	}
	doc := decode_document(data, length, 4) or { return err }
	return doc
}

// `T` should comply with given encoded string.
pub fn decode<T>(data string) ?T {
	length := validate_string(data) or { return err }
	if length == 5 {
		return T{}
	}
	doc := decode_document(data, length, 4) or { return err }
	mut res := T{}
	if typeof(res).name.contains('map[string]') {

	} else {
		$for field in T.fields {
			if field.name in doc.elem_pos {
				i := doc.elem_pos[field.name]
				$if field.typ is string {
					b_field := doc.elements[i] as BsonElement<string>
					res.$(field.name) = b_field.value
				} $else $if field.typ is bool {
					b_field := doc.elements[i] as BsonElement<bool>
					res.$(field.name) = b_field.value
				} $else $if field.typ is int {
					b_field := doc.elements[i] as BsonElement<int>
					res.$(field.name) = b_field.value
				} $else $if field.typ is i64 {
					b_field := doc.elements[i] as BsonElement<i64>
					res.$(field.name) = b_field.value
				}
			} else {
				return error('Key "$field.name" not found.')
			}
		}
	}
	return res
}
