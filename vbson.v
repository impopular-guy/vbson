module vbson

import encoding.binary

enum Element {
	e_bool
	e_int
	e_i64
	e_u64
}

const (
	end  = byte(0x00)
	keys = {
		Element.e_bool: byte(0x08)
		Element.e_int:  byte(0x10)
		Element.e_i64:  byte(0x12)
		Element.e_u64:  byte(0x11)
	}
)

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

fn encode_element<T>(name string, val T, ele Element) []byte {
	mut buf := []byte{}
	buf << keys[ele]
	buf << name.bytes()
	buf << end
	buf << match ele {
		.e_bool { [byte(val)] }
		.e_int { encode_int(val) }
		.e_i64 { encode_i64(val) }
		.e_u64 { encode_u64(val) }
	}
	return buf
}

fn encode_object<T>(dd T) []byte {
	mut buf := []byte{}
	$for field in T.fields {
		$if field.typ is bool {
			buf << encode_element<bool>(field.name, dd.$(field.name), .e_bool)
		} $else $if field.typ is int {
			buf << encode_element<int>(field.name, dd.$(field.name), .e_int)
		} $else $if field.typ is i64 {
			buf << encode_element<i64>(field.name, dd.$(field.name), .e_i64)
		} $else $if field.typ is u64 {
			buf << encode_element<u64>(field.name, dd.$(field.name), .e_u64)
		}
	}
	buf << end
	buf.prepend(encode_int(buf.len + 4))
	return buf
}

pub fn encode<T>(data T) string {
	// check if T is a struct else fail
	return encode_object<T>(data).bytestr()
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

fn decode_element<T>(t voidptr, name string, data string, cur int) ?int {
	mut res := &T(t)
	$for field in T.fields {
		$if field.typ is bool {
			if field.name == name {
				res.$(field.name) = (data[cur] == 0x01)
				return 1
			}
		} $else $if field.typ is int {
			if field.name == name {
				res.$(field.name) = decode_int(data, cur)
				return 4
			}				
		} $else $if field.typ is i64 {
			if field.name == name {
				res.$(field.name) = decode_i64(data, cur)
				return 8
			}				
		} $else $if field.typ is u64 {
			if field.name == name {
				res.$(field.name) = decode_u64(data, cur)
				return 8
			}				
		}
	}
	return error('Failed to decode element at pos: $cur')
}

fn decode_object<T>(data string, length int, cursor int) ?T {
	mut cur := cursor
	mut res := T{}
	for cur < length {
		if data[cur] == 0x00 {
			break
		}
		cur++

		mut n := cur
		for data[n] != 0x00 {
			n += 1
		}
		name := data[cur..n]
		cur = n + 1

		cur += decode_element<T>(res, name, data, cur) or { return err }
	}
	return res
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
	return decode_object<T>(data, length, 4) or { return err }
}
