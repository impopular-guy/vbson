module vbson

import math

fn convert_to_bsondoc<T>(data T) ?BsonDoc {
	mut doc := BsonDoc{}
	$for field in T.fields {
		if !('bsonskip' in field.attrs) {
			$if field.typ is string {
				doc.elements << BsonElement<string>{field.name, .e_string, data.$(field.name)}
			} $else $if field.typ is bool {
				doc.elements << BsonElement<bool>{field.name, .e_bool, data.$(field.name)}
			} $else $if field.typ is int {
				doc.elements << BsonElement<int>{field.name, .e_int, data.$(field.name)}
			} $else $if field.typ is i64 {
				doc.elements << BsonElement<i64>{field.name, .e_i64, data.$(field.name)}
			} $else $if field.typ is f32 {
				doc.elements << BsonElement<f64>{field.name, .e_double, data.$(field.name)}
			} $else $if field.typ is f64 {
				doc.elements << BsonElement<f64>{field.name, .e_double, data.$(field.name)}
			} $else {
				return error("Unsupported Type: ${field.name}. Use attr [bsonskip] to ignore this field.")
			}
			doc.elem_pos[field.name] = doc.n_elems++
		}
	}
	return doc
}

// `T` can be any user-defined struct or `map[string]<T1>` where `T1` is any supported type.
// Use attribute [bsonskip] to skip encoding of any field from a struct
pub fn encode<T>(data T) ?string {
	mut doc := BsonDoc{}
	if typeof(data).name.contains('map[string]') {

	} else {
		doc = convert_to_bsondoc<T>(data) ?
	}
	return encode_document(doc).bytestr()
}

// https://babbage.cs.qc.cuny.edu/ieee-754.old/decimal.html
[inline]
fn f64_to_f32(v f64) f32 {
	ui_64 := math.f64_bits(v)
	e := u32(int((ui_64 >> 52) & 0x7FF) - 1023 + 127)
	ui_32 := u32((ui_64 >> 29) & 0x7FFFFF) | u32((e << 23) & 0x7F800000) | u32((ui_64 >> 32) & 0x80000000)
	return math.f32_from_bits(ui_32)
}

fn convert_from_bsondoc<T>(doc BsonDoc) ?T {
	mut res := T{}
	$for field in T.fields {
		if field.name in doc.elem_pos {
			i := doc.elem_pos[field.name]
			$if field.typ is string {
				b_elem := doc.elements[i] as BsonElement<string>
				res.$(field.name) = b_elem.value
			} $else $if field.typ is bool {
				b_elem := doc.elements[i] as BsonElement<bool>
				res.$(field.name) = b_elem.value
			} $else $if field.typ is int {
				b_elem := doc.elements[i] as BsonElement<int>
				res.$(field.name) = b_elem.value
			} $else $if field.typ is i64 {
				b_elem := doc.elements[i] as BsonElement<i64>
				res.$(field.name) = b_elem.value
			} $else $if field.typ is f32 {
				b_elem := doc.elements[i] as BsonElement<f64>
				res.$(field.name) = f64_to_f32(b_elem.value)
			} $else $if field.typ is f64 {
				b_elem := doc.elements[i] as BsonElement<f64>
				res.$(field.name) = b_elem.value
			} $else {
				return error('Key "$field.name" not supported')
			}
		} else if 'bsonskip' in field.attrs {
		} else {
			return error('Key "$field.name" not found.')
		}
	}
	return res
}

// `T` should comply with given encoded string.
pub fn decode<T>(data string) ?T {
	length := validate_string(data) or { return err }
	if length == 5 {
		return T{}
	}
	doc := decode_document(data, 4, length) or { return err }
	mut res := T{}
	if typeof(res).name.contains('map[string]') {

	} else {
		res = convert_from_bsondoc<T>(doc) ?
	}
	return res
}
