module vbson

import encoding.binary
import math

// This enum is a list of element types that are currently supported in this module.
// Reference: [bsonspec.org](https://bsonspec.org/spec.html)
pub enum ElementType {
	// e_00 = 0x00
	e_double = 0x01
	e_string = 0x02
	e_document
	e_array
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
	n_elems int // no. of elements in the document
	elements map[string]ElemSumType // array of elements of the document
}

// SumType used to store multiple BsonElement types in single array.
pub type ElemSumType = f64 | string | BsonDoc | bool | int | i64 | []ElemSumType

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

fn encode_array(elem []ElemSumType) []u8 {
	mut doc := BsonDoc{}
	for i, v in elem {
		doc.elements['$i'] = v
	}
	doc.n_elems = elem.len
	return encode_document(doc)
}

fn (elem ElemSumType) get_e_type() ElementType {
	return match elem {
		f64 { .e_double }
		string { .e_string }
		BsonDoc { .e_document }
		[]ElemSumType { .e_array }
		bool { .e_bool }
		int { .e_int }
		i64 { .e_i64 }
	}
}

fn (elem ElemSumType) encode() []u8 {
	return match elem {
		f64 { encode_f64(elem) }
		string { encode_string(elem) }
		BsonDoc { encode_document(elem) }
		[]ElemSumType { encode_array(elem) }
		bool { [u8(elem)] }
		int { encode_int(int(elem)) }
		i64 { encode_i64(elem) }
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

pub fn encode_bsondoc(doc BsonDoc) string {
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

fn decode_f64(data string, cur int) f64 {
	u_val := decode_u64(data, cur)
	return math.f64_from_bits(u_val)
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

fn decode_element(data string, cur int, e_type ElementType) ?(ElemSumType, int) {
	match e_type {
		.e_double {
			return decode_f64(data, cur), 8
		}
		.e_string {
			str, dcur := decode_string(data, cur)
			return ElemSumType(str), dcur
		}
		.e_document {
			dcur := decode_int(data, cur)
			elem := decode_document(data, cur+4, cur+dcur) ?
			return elem, dcur
		}
		.e_array {
			mut b := []ElemSumType{}
			dcur := decode_int(data, cur)
			elem := decode_document(data, cur+4, cur+dcur) ?
			for _,v in elem.elements {
				b << v
			}
			return b, dcur
		}
		.e_bool {
			return (data[cur] == 0x01), 1
		}
		.e_int {
			return decode_int(data, cur), 4
		}
		.e_i64 {
			return decode_i64(data, cur), 8
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
		e_type := ElementType(data[cur])
		if int(e_type) in unused_types {
			return error('decode error: ElementType type `${data[cur]}` is not supported.')
		}
		cur++

		name, dcur := decode_cstring(data, cur)
		cur += dcur
		elem, dcur1 := decode_element(data, cur, e_type) ?
		cur += dcur1
		doc.elements[name] = elem
		doc.n_elems++
	}
	if cur < end-1 {
		return error("decode error: Corrupted data.")
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

// Returns error if encoded data is incorrect.
pub fn decode_to_bsondoc(data string) ?BsonDoc {
	length := validate_string(data) or { return err }
	if length == 5 {
		return BsonDoc{}
	}
	doc := decode_document(data, 4, length) or { return err }
	return doc
}
