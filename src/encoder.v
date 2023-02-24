module vbson

import encoding.binary
import math
import time

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
	mut doc := map[string]Any{}
	for i, v in elem {
		doc['${i}'] = v
	}
	return encode_document(doc)
}

fn encode_objectid(elem ObjectID) []u8 {
	// TODO check if id.len <= 12
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

fn encode_regex(elem Regex) []u8 {
	mut buf := []u8{}
	buf << encode_cstring(elem.pattern)
	buf << encode_cstring(elem.options)
	return buf
}

fn encode_i128(elem Decimal128) []u8 {
	return elem.bytes
}

fn (elem Any) get_e_type() ElementType {
	return match elem {
		f64 { .e_double }
		string { .e_string }
		map[string]Any { .e_document }
		[]Any { .e_array }
		bool { .e_bool }
		int { .e_int }
		i64 { .e_i64 }
		u64 { .e_timestamp }
		Null { .e_null }
		ObjectID { .e_object_id }
		time.Time { .e_utc_datetime }
		Binary { .e_binary }
		Regex { .e_regex }
		MinKey { .e_minkey }
		MaxKey { .e_maxkey }
		Decimal128 { .e_decimal128 }
	}
}

fn (elem Any) encode() []u8 {
	return match elem {
		f64 { encode_f64(elem) }
		string { encode_string(elem) }
		map[string]Any { encode_document(elem) }
		[]Any { encode_array(elem) }
		bool { [u8(elem)] }
		int { encode_int(int(elem)) }
		i64 { encode_i64(elem) }
		u64 { encode_u64(elem) }
		Null, MinKey, MaxKey { []u8{} }
		ObjectID { encode_objectid(elem) }
		time.Time { encode_utc(elem) }
		Binary { encode_binary(elem) }
		Regex { encode_regex(elem) }
		Decimal128 { encode_i128(elem) }
	}
}

fn encode_document(doc map[string]Any) []u8 {
	mut buf := []u8{}
	for name, elem in doc {
		buf << u8(elem.get_e_type())
		buf << encode_cstring(name)
		buf << elem.encode()
	}
	buf << u8(0x00)
	buf.prepend(encode_int(buf.len + 4))
	return buf
}
