module vbson

import math
import time
import encoding.binary

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
	if data[cur] == 0x00 {
		return '', 1
	}
	mut n := 0
	for data[cur + n] != 0x00 {
		n += 1
	}
	return data[cur..(cur + n)], n + 1
}

fn decode_string(data string, cur int) !(string, int) {
	str_len := decode_int(data, cur)
	if str_len <= 0 {
		return error('decode error: corrupt BSON : non-positive string length.')
	}
	return data[(cur + 4)..(cur + 4 + str_len - 1)], str_len + 4
}

fn decode_objectid(data string, cur int) ObjectID {
	return ObjectID{data[cur..(cur + 12)]}
}

fn decode_utc(data string, cur int) time.Time {
	u := decode_i64(data, cur)
	return time.unix2(i64(u / 1000), int(u % 1000) * 1000)
}

fn decode_element(data string, cur int, e_type ElementType) !(Any, int) {
	match e_type {
		.e_double {
			return decode_f64(data, cur), 8
		}
		.e_string {
			str, dcur := decode_string(data, cur)!
			return Any(str), dcur
		}
		.e_js_code {
			str, dcur := decode_string(data, cur)!
			return JSCode{str}, dcur
		}
		.e_document {
			dcur := decode_int(data, cur)
			elem := decode_document(data, cur + 4, cur + dcur)!
			return elem, dcur
		}
		.e_array {
			mut b := []Any{}
			dcur := decode_int(data, cur)
			elem := decode_document(data, cur + 4, cur + dcur)!
			for _, v in elem {
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
		.e_minkey {
			return MinKey{}, 0
		}
		.e_maxkey {
			return MaxKey{}, 0
		}
		.e_regex {
			pattern, dcur := decode_cstring(data, cur)
			options, dcur1 := decode_cstring(data, cur + dcur)
			return Regex{pattern, options}, dcur + dcur1
		}
		.e_object_id {
			return decode_objectid(data, cur), 12
		}
		.e_utc_datetime {
			return decode_utc(data, cur), 8
		}
		.e_binary {
			b_size := decode_int(data, cur)
			if b_size < 0 {
				return error('decode error: corrupt BSON : negative data length.')
			}
			mut elem := Binary{}
			elem.b_type = u8(data[cur + 4])
			if elem.b_type in deprecated_bin_types {
				return error('decode error: unsupported binary subtype `${elem.b_type}`.')
			}
			elem.data = data[(cur + 5)..(cur + 5 + b_size)].bytes()
			return elem, 4 + 1 + b_size
		}
		.e_timestamp {
			return decode_u64(data, cur), 8
		}
		.e_decimal128 {
			d128 := data[cur..(cur + 16)].bytes()
			return Decimal128{d128}, 16
		}
		else {
			return error('decode error: unsupported ElementType `${int(e_type)}`.')
		}
	}
}

fn decode_document(data string, start int, end int) !map[string]Any {
	mut cur := start
	mut doc := map[string]Any{}
	for cur < end {
		if data[cur] == 0x00 {
			break
		}
		if int(data[cur]) in deprecated_types {
			return error('decode error: unsupported ElementType `${data[cur]}` (deprecated).')
		}
		e_type := unsafe {
			ElementType(data[cur])
		}
		cur++

		name, dcur := decode_cstring(data, cur)
		if name.contains('.') {
			return error('decode error: keys cannot contain "." : `${name}`')
		}
		if name.starts_with('$') {
			return error('decode error: keys cannot begin with "$" : `${name}`')
		}
		cur += dcur
		elem, dcur1 := decode_element(data, cur, e_type)!
		cur += dcur1
		doc[name] = elem
	}
	if cur != end - 1 {
		return error('decode error: corrupt BSON.')
	}
	return doc
}

fn validate_string(data string) !int {
	if data.len <= 4 {
		return error('decode error: corrupt BSON : Data must be more than 4 bytes.')
	}
	length := decode_int(data, 0)
	if length != data.len {
		return error('decode error: corrupt BSON : data length mismatch.')
	}
	return length
}

// `bson_to_map` takes in bson string input and returns
// `map[string]Any` as output.
// It returns error if encoded data is incorrect.
pub fn bson_to_map(data string) !map[string]Any {
	length := validate_string(data)!
	if length == 5 {
		return map[string]Any{}
	}
	return decode_document(data, 4, length)!
}
