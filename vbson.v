module vbson

import encoding.binary

enum Element {
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

enum SubType {
	s_generic = 0x00
	s_uuid = 0x04
	s_md5
}

const (
	unused_types = [0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xFF, 0x7F]
	unused_subtypes = [0x01, 0x02, 0x03, 0x06, 0x80]
)

pub struct BsonField<T> {
pub mut:
	name string
	e_type Element
	value T
}

type SumField = BsonField<string> | BsonField<bool> | BsonField<int> | BsonField<i64>

pub struct BsonRow{
pub mut:
	n_fields u32
	field_pos map[string]u32
	fields []SumField
}

// 32
fn encode_int(val int) []byte {
	mut b := []byte{len: 4, init: 0}
	binary.little_endian_put_u32(mut b, u32(val))
	return b
}

// 64
fn encode_i64(val i64) []byte {
	mut b := []byte{len: 8, init: 0}
	binary.little_endian_put_u64(mut b, u64(val))
	return b
}

fn encode_u64(val u64) []byte {
	mut b := []byte{len: 8, init: 0}
	binary.little_endian_put_u64(mut b, val)
	return b
}

fn encode_cstring(str string) []byte {
	mut b := []byte{}
	b << str.bytes()
	b << byte(0x00)
	return b
}

fn encode_string(str string) []byte {
	mut b := []byte{}
	b << str.bytes()
	b << byte(0x00)
	b.prepend(encode_int(b.len))
	return b
}

fn (field SumField) encode() []byte {
	return match field {
		BsonField<string> { encode_string(field.value) }
		BsonField<bool> { [byte(field.value)] }
		BsonField<int> { encode_int(int(field.value)) }
		BsonField<i64> { encode_i64(field.value) }
	}
}

pub fn encode_bson_row(row BsonRow) []byte {
	mut buf := []byte{}
	for i := 0; i < row.n_fields; i++ {
		field := row.fields[i]
		buf << byte(field.e_type)
		buf << encode_cstring(field.name)
		buf << field.encode()
	}
	buf << byte(0x00)
	buf.prepend(encode_int(buf.len + 4))
	return buf
}

pub fn encode<T>(data T) string {
	mut row := BsonRow{}
	if typeof(data).name.contains('map[string]') {

	} else {
		$for field in T.fields {
			row.n_fields++
			$if field.typ is string {
				row.fields << BsonField<string>{field.name, .e_string, data.$(field.name)}
			} $else $if field.typ is bool {
				row.fields << BsonField<bool>{field.name, .e_bool, data.$(field.name)}
			} $else $if field.typ is int {
				row.fields << BsonField<int>{field.name, .e_int, data.$(field.name)}
			} $else $if field.typ is i64 {
				row.fields << BsonField<i64>{field.name, .e_i64, data.$(field.name)}
			}
		}
	}
	return encode_bson_row(row).bytestr()
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

fn (mut field SumField) decode(data string, cur int) int {
	mut dcur := 0
	match mut field {
		BsonField<string> {
			field.value, dcur = decode_string(data, cur)
		}
		BsonField<bool> {
			field.value = (data[cur] == 0x01)
			dcur = 1
		}
		BsonField<int> {
			field.value = decode_int(data, cur)
			dcur = 4
		}
		BsonField<i64> {
			field.value = decode_i64(data, cur)
			dcur = 8
		}
	}
	return dcur
}

fn decode_to_bson_row(data string, length int, cursor int) ?BsonRow {
	mut cur := cursor
	mut row := BsonRow{}
	for cur < length {
		if data[cur] == 0x00 {
			break
		}
		e_type := Element(data[cur])
		if int(e_type) in unused_types {
			return error('Element type "${data[cur]}" is not supported.')
		}
		cur++

		name, dcur := decode_cstring(data, cur)
		cur += dcur
		mut field := match e_type {
			.e_string { SumField(BsonField<string>{}) }
			.e_bool { SumField(BsonField<bool>{}) }
			.e_int { SumField(BsonField<int>{}) }
			.e_i64 { SumField(BsonField<i64>{}) }
		}
		field.name = name
		field.e_type = e_type
		cur += field.decode(data, cur)
		row.fields << field
		row.field_pos[name] = row.n_fields
		row.n_fields++
	}
	if cur < length-1 {
		return error("Corrupted data.")
	}
	return row
}

pub fn decode<T>(data string) ?T {
	if data.len <= 4 {
		return error('Data must be more than 4 bytes.')
	}
	length := decode_int(data, 0)
	if length == 5 {
		return T{}
	}
	if length != data.len {
		return error('BSON data length mismatch.')
	}
	row := decode_to_bson_row(data, length, 4) or { return err }
	mut res := T{}
	if typeof(res).name.contains('map[string]') {

	} else {
		$for field in T.fields {
			if field.name in row.field_pos {
				i := row.field_pos[field.name]
				$if field.typ is string {
					b_field := row.fields[i] as BsonField<string>
					res.$(field.name) = b_field.value
				} $else $if field.typ is bool {
					b_field := row.fields[i] as BsonField<bool>
					res.$(field.name) = b_field.value
				} $else $if field.typ is int {
					b_field := row.fields[i] as BsonField<int>
					res.$(field.name) = b_field.value
				} $else $if field.typ is i64 {
					b_field := row.fields[i] as BsonField<i64>
					res.$(field.name) = b_field.value
				}
			} else {
				return error('Key "$field.name" not found.')
			}
		}
	}

	return res
}
