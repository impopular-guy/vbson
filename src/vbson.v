module vbson

import time

// Reference: [bsonspec.org](https://bsonspec.org/spec.html)
enum ElementType {
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
const (
	unused_types = [0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xFF, 0x7F]
)

// Any should be only the types supported by bson
type Any = Binary
	| Null
	| ObjectID
	| []Any
	| bool
	| f64
	| i64
	| int
	| map[string]Any
	| string
	| time.Time

// `Null` struct is used for Option type to represent none or nil reference.
struct Null {
	is_null bool = true
}

// ObjectID is a wrapper for mongo-style onjectID
struct ObjectID {
	id string
}

// `Binary` is a wrapper for binary data. Binary sub-type is stored in `b_type` and data is in the form of a byte array.
struct Binary {
mut:
	b_type int
	data   []u8
}

// encode takes struct as input and returns encoded bson as string or
// returns error for failed encoding.
// Use attribute [bsonskip] to skip encoding of any field from a struct.
// Use attribute [bson_id] to specify a string field as mongo-style object id.
// It cannot encode variables of `fixed length arrays`.
pub fn encode[T](data T) !string {
	$if T is $Struct {
		map_data := p_encode_struct[T](data)!
		return encode_document(map_data).bytestr()
	} $else {
		return error('Input must of type `struct`, not `${typeof(data).name}`.')
	}
}

fn p_encode_struct[T](data T) !map[string]Any {
	mut res := map[string]Any{}
	$for field in T.fields {
		if 'bsonskip' !in field.attrs {
			field_name := field.name

			$if field.is_array {
				x := data.$(field.name)
				res[field_name] = p_encode_array(x)!
			} $else $if field.is_struct {
				x := data.$(field.name)
				res[field_name] = p_encode_struct(x)!
			} $else $if field.is_map {
				// TODO
				return error('Map not supported yet. Use attr [bsonskip] to ignore this field.')
			} $else $if field.typ is string {
				if 'bson_id' in field.attrs {
					res[field_name] = ObjectID{data.$(field.name)}
				} else {
					res[field_name] = Any(data.$(field.name))
				}
			} $else $if field.typ is time.Time {
				// TODO
				return error('time.Time not supported yet. Use attr [bsonskip] to ignore this field.')
			} $else $if field.is_chan {
				return error('`chan` not supported. Use attr [bsonskip] to ignore this field.')
			} $else $if field.typ in [bool, f32, f64, i8, i16, int, i64, u8, u16, u32, u64] {
				x := data.$(field.name)
				res[field_name] = p_encode_any(x)!
			} $else {
				return error('Unsupported type for `${field.name}` for encoding. Use attr [bsonskip] to ignore this field.')
			}
		}
	}
	return res
}

fn p_encode_array[T](arr []T) ![]Any {
	mut res := []Any{}
	for a in arr {
		$if a is $Array {
			// TODO this should be p_encode_array
			res << p_encode_any(a)!
		} $else $if a is $Struct {
			res << p_encode_struct(a)!
		} $else {
			res << p_encode_any(a)!
		}
	}
	return res
}

fn p_encode_any[T](data T) !Any {
	$if T is bool {
		return data
	} $else $if T is string {
		return data
	} $else $if T in [f32, f64] {
		return f64(data)
	} $else $if T in [i8, u8, i16, u16, int, u32] {
		return int(data)
	} $else $if T in [i64, u64] {
		return i64(data)
	} $else $if T is time.Time {
		// TODO
		return error('time.Time not supported yet. Use attr [bsonskip] to ignore this field.')
	} $else {
		return error('Unsupported type `${typeof(data).name}` for encoding')
	}
}

// fn validate_string(data string) ?int {
// 	if data.len <= 4 {
// 		return error('decode error: Data must be more than 4 bytes.')
// 	}
// 	length := decode_int(data, 0)
// 	if length != data.len {
// 		return error('decode error: BSON data length mismatch.')
// 	}
// 	return length
// }

// // decode_to_bsondoc takes in bson string input and returns
// // `vbson.BsonDoc` as output.
// // It returns error if encoded data is incorrect.
// pub fn decode_to_bsondoc(data string) ?BsonDoc {
// 	length := validate_string(data) or { return err }
// 	if length == 5 {
// 		return BsonDoc{}
// 	}
// 	doc := decode_document(data, 4, length) or { return err }
// 	return doc
// }

// // decode takes bson string as input and returns value of struct `T`.
// // `T` should comply with given encoded string else it returns error
// pub fn decode[T](data string) ?T {
// 	length := validate_string(data) or { return err }
// 	if length == 5 {
// 		return T{}
// 	}
// 	doc := decode_document(data, 4, length) or { return err }
// 	res := convert_from_bsondoc[T](doc)?
// 	return res
// }
