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

fn decode_element(data string, cur int, e_type ElementType) !(Any, int) {
	match e_type {
		.e_double {
			return decode_f64(data, cur), 8
		}
		.e_string {
			str, dcur := decode_string(data, cur)
			return Any(str), dcur
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
		.e_object_id {
			return decode_objectid(data, cur), 12
		}
		.e_utc_datetime {
			return decode_utc(data, cur), 8
		}
		.e_binary {
			b_size := decode_int(data, cur)
			mut elem := Binary{}
			elem.b_type = u8(data[cur + 4])
			elem.data = data[(cur + 5)..(cur + 5 + b_size)].bytes()
			return elem, 4 + 1 + b_size
		}
		else {
			return error('decode error: ${e_type} is not supported')
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
		if int(data[cur]) in unused_types {
			return error('decode error: ElementType type `${data[cur]}` is not supported.')
		}
		e_type := unsafe {
			ElementType(data[cur])
		}
		cur++

		name, dcur := decode_cstring(data, cur)
		cur += dcur
		elem, dcur1 := decode_element(data, cur, e_type)!
		cur += dcur1
		doc[name] = elem
	}
	if cur < end - 1 {
		return error('decode error: Corrupted data.')
	}
	return doc
}

// fn convert_from_bsondoc[T](doc BsonDoc) !T {
// 	mut res := T{}
// 	$for field in T.fields {
// 		if field.name in doc.elements {
// 			elem := doc.elements[field.name] or { return error('Failed to get element.') }
// 			$if field.typ is string {
// 				res.$(field.name) = elem as string
// 			} $else $if field.typ is bool {
// 				res.$(field.name) = elem as bool
// 			} $else $if field.typ is int {
// 				res.$(field.name) = elem as int
// 			} $else $if field.typ is i64 {
// 				res.$(field.name) = elem as i64
// 			} $else $if field.typ is f32 {
// 				f := elem as f64
// 				res.$(field.name) = f32(f)
// 			} $else $if field.typ is f64 {
// 				res.$(field.name) = elem as f64
// 			} $else $if field.typ is []string {
// 				sa := elem as []Any
// 				for v in sa {
// 					res.$(field.name) << v as string
// 				}
// 			} $else $if field.typ is []bool {
// 				ba := elem as []Any
// 				for v in ba {
// 					res.$(field.name) << v as bool
// 				}
// 			} $else $if field.typ is []int {
// 				ia := elem as []Any
// 				for v in ia {
// 					res.$(field.name) << v as int
// 				}
// 			} $else $if field.typ is []i64 {
// 				i6a := elem as []Any
// 				for v in i6a {
// 					res.$(field.name) << v as i64
// 				}
// 			} $else $if field.typ is []f32 {
// 				f3a := elem as []Any
// 				for v in f3a {
// 					res.$(field.name) << f32(v as f64)
// 				}
// 			} $else $if field.typ is []f64 {
// 				fa := elem as []Any
// 				for v in fa {
// 					res.$(field.name) << v as f64
// 				}
// 			} $else $if field.typ is Null {
// 				res.$(field.name) = elem as Null
// 			} $else $if field.typ is ObjectID {
// 				res.$(field.name) = elem as ObjectID
// 			} $else $if field.typ is time.Time {
// 				res.$(field.name) = elem as time.Time
// 			} $else $if field.typ is Binary {
// 				res.$(field.name) = elem as Binary
// 			} $else {
// 				return error('decode error: Key `${field.name}` not supported')
// 			}
// 		} else if 'bsonskip' in field.attrs {
// 		} else {
// 			return error('decode error: Key `${field.name}` not found.')
// 		}
// 	}
// 	return res
// }
