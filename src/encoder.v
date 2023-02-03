module vbson

import encoding.binary
import math

struct Encoder {
pub mut:
	max_size int  = 16 * 1024 * 1024
	buf      []u8 = []u8{cap: 64}
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

fn encode_array(elem []Any) []u8 {
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

fn (elem Any) get_e_type() ElementType {
	return match elem {
		f64 { .e_double }
		string { .e_string }
		BsonDoc { .e_document }
		[]Any { .e_array }
		bool { .e_bool }
		int { .e_int }
		i64 { .e_i64 }
		Null { .e_null }
		ObjectID { .e_object_id }
		time.Time { .e_utc_datetime }
		Binary { .e_binary }
	}
}

fn (elem Any) encode() []u8 {
	return match elem {
		f64 { encode_f64(elem) }
		string { encode_string(elem) }
		BsonDoc { encode_document(elem) }
		[]Any { encode_array(elem) }
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

fn raw_encode[T](data T) !map[string]Any {
	mut res := map[string]Any{}
	$for field in T.fields {
		if 'bsonskip' !in field.attrs {
			$if field.typ is string {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is bool {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is int {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is i64 {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is f32 {
				res[field.name] = Any(f64(data.$(field.name)))
			} $else $if field.typ is f64 {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is []string {
				mut sa := []Any{}
				for s in data.$(field.name) {
					sa << Any(s)
				}
				res[field.name] = sa
			} $else $if field.typ is []bool {
				mut ba := []Any{}
				for b in data.$(field.name) {
					ba << Any(b)
				}
				res[field.name] = ba
			} $else $if field.typ is []int {
				mut ia := []Any{}
				for i in data.$(field.name) {
					ia << Any(i)
				}
				res[field.name] = ia
			} $else $if field.typ is []i64 {
				mut i6a := []Any{}
				for i6 in data.$(field.name) {
					i6a << Any(i6)
				}
				res[field.name] = i6a
			} $else $if field.typ is []f32 {
				mut f3a := []Any{}
				for f3 in data.$(field.name) {
					f3a << Any(f64(f3))
				}
				res[field.name] = f3a
			} $else $if field.typ is []f64 {
				mut fa := []Any{}
				for f in data.$(field.name) {
					fa << Any(f)
				}
				res[field.name] = fa
			} $else $if field.typ is Null {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is ObjectID {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is time.Time {
				res[field.name] = Any(data.$(field.name))
			} $else $if field.typ is Binary {
				res[field.name] = Any(data.$(field.name))
			} $else {
				return error('encode error: Unsupported Type: `${field.name}` Use attr [bsonskip] to ignore this field.')
			}
		}
	}
	return res
}
