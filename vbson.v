module vbson

enum Element {
	e_bool
	e_int
	e_i64
	e_u64
}

fn reverse_map(m map[Element]byte) map[byte]Element {
	mut res := map[byte]Element{}
	for k, v in m {
		res[v] = k
	}
	return res
}

const (
	end  = byte(0x00)
	keys = {
		Element.e_bool: byte(0x08)
		Element.e_int:  byte(0x10)
		Element.e_i64:  byte(0x12)
		Element.e_u64:  byte(0x11)
	}
	rkeys = reverse_map(keys)
)

// 32
fn encode_int(val int) []byte {
	mut b := []byte{len: 4, init: 0}
	for i := 3; i >= 0; i -= 1 {
		b[i] = byte((val >> (8 * i)) & 0xff)
	}
	return b
}

// 64
fn encode_i64(val i64) []byte {
	mut b := []byte{len: 8, init: 0}
	for i := 7; i >= 0; i -= 1 {
		b[i] = byte((val >> (8 * i)) & 0xff)
	}
	return b
}

fn encode_u64(val u64) []byte {
	mut b := []byte{len: 8, init: 0}
	for i := 7; i >= 0; i -= 1 {
		b[i] = byte((val >> (8 * i)) & 0xff)
	}
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
	mut d := 0
	for i := 0; i < 4; i += 1 {
		// notice: shifting value in signed data
		d = d | (int(data[cur + i]) << (8 * i))
	}
	return d
}

fn decode_i64(data string, cur int) i64 {
	mut d := i64(0)
	for i := 0; i < 8; i += 1 {
		// notice: shifting value in signed data
		d = d | (i64(data[cur + i]) << (8 * i))
	}
	return d
}

fn decode_u64(data string, cur int) u64 {
	mut d := u64(0)
	for i := 0; i < 8; i += 1 {
		d = d | (u64(data[cur + i]) << (8 * i))
	}
	return d
}

fn decode_element<T>(t voidptr, name string, data string, cur int, ele_type Element) ?int {
	mut tt := &T(t)
	$for field in T.fields {
		if field.name == name {
			match ele_type {
				.e_bool {
					vb := (data[cur] == 0x01)
					tt.$(field.name) = vb
					return 1
				}
				.e_int {
					vi := decode_int(data, cur)
					tt.$(field.name) = vi
					return 4
				}
				.e_i64 {
					vi64 := decode_i64(data, cur)
					tt.$(field.name) = vi64
					return 8
				}
				.e_u64 {
					vu64 := decode_u64(data, cur)
					tt.$(field.name) = vu64
					return 8
				}
			}
		}
	}
	return error('Failed to decode element at pos: $cur')
}

fn decode_object<T>(data string, length int, cursor int) ?T {
	mut cur := cursor
	mut res := T{}
	mut ele_type := Element(0)
	for cur < length {
		if data[cur] == 0x00 {
			break
		}
		ele_type = rkeys[data[cur]]
		cur++

		mut n := cur
		for data[n] != 0x00 {
			n += 1
		}
		name := data[cur..n]
		cur = n + 1

		cur += decode_element<T>(res, name, data, cur, ele_type) or { return err }
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
