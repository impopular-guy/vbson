module vbson

import math

fn convert_to_bsondoc<T>(data T) ?BsonDoc {
	mut doc := BsonDoc{}
	$for field in T.fields {
		if !('bsonskip' in field.attrs) {
			$if field.typ is string {
				doc.elements[field.name] = ElemSumType(data.$(field.name))
			} $else $if field.typ is bool {
				doc.elements[field.name] = ElemSumType(data.$(field.name))
			} $else $if field.typ is int {
				doc.elements[field.name] = ElemSumType(data.$(field.name))
			} $else $if field.typ is i64 {
				doc.elements[field.name] = ElemSumType(data.$(field.name))
			} $else $if field.typ is f32 {
				doc.elements[field.name] = ElemSumType(f64(data.$(field.name)))
			} $else $if field.typ is f64 {
				doc.elements[field.name] = ElemSumType(data.$(field.name))
			} $else $if field.typ is []string {
				mut sa := []ElemSumType{}
				for v in data.$(field.name) { sa << ElemSumType(v) }
				doc.elements[field.name] = sa
			} $else $if field.typ is []bool {
				mut ba := []ElemSumType{}
				for v in data.$(field.name) { ba << ElemSumType(v) }
				doc.elements[field.name] = ba
			} $else $if field.typ is []int {
				mut ia := []ElemSumType{}
				for v in data.$(field.name) { ia << ElemSumType(v) }
				doc.elements[field.name] = ia
			} $else $if field.typ is []i64 {
				mut i6a := []ElemSumType{}
				for v in data.$(field.name) { i6a << ElemSumType(v) }
				doc.elements[field.name] = i6a
			} $else $if field.typ is []f32 {
				mut f3a := []ElemSumType{}
				for v in data.$(field.name) { f3a << ElemSumType(f64(v)) }
				doc.elements[field.name] = f3a
			} $else $if field.typ is []f64 {
				mut fa := []ElemSumType{}
				for v in data.$(field.name) { fa << ElemSumType(v) }
				doc.elements[field.name] = fa
			} $else {
				return error("encode error: Unsupported Type: `${field.name}` Use attr [bsonskip] to ignore this field.")
			}
			doc.n_elems++
		}
	}
	return doc
}

// `T` can be any user-defined struct.
// Use attribute [bsonskip] to skip encoding of any field from a struct.
// It cannot encode variables of `fixed length arrays`.
pub fn encode<T>(data T) ?string {
	mut doc := BsonDoc{}
	doc = convert_to_bsondoc<T>(data) ?
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
		if field.name in doc.elements {
			elem := doc.elements[field.name] ?
			$if field.typ is string {
				res.$(field.name) = elem as string
			} $else $if field.typ is bool {
				res.$(field.name) = elem as bool
			} $else $if field.typ is int {
				res.$(field.name) = elem as int
			} $else $if field.typ is i64 {
				res.$(field.name) = elem as i64
			} $else $if field.typ is f32 {
				f := elem as f64
				res.$(field.name) = f64_to_f32(f)
			} $else $if field.typ is f64 {
				res.$(field.name) = elem as f64
			} $else $if field.typ is []string {
				sa := elem as []ElemSumType
				for v in sa { res.$(field.name) << v as string }
			} $else $if field.typ is []bool {
				ba := elem as []ElemSumType
				for v in ba { res.$(field.name) << v as bool }
			} $else $if field.typ is []int {
				ia := elem as []ElemSumType
				for v in ia { res.$(field.name) << v as int }
			} $else $if field.typ is []i64 {
				i6a := elem as []ElemSumType
				for v in i6a { res.$(field.name) << v as i64 }
			} $else $if field.typ is []f32 {
				f3a := elem as []ElemSumType
				for v in f3a { res.$(field.name) << f64_to_f32(v as f64) }
			} $else $if field.typ is []f64 {
				fa := elem as []ElemSumType
				for v in fa { res.$(field.name) << v as f64 }
			} $else {
				return error('decode error: Key `$field.name` not supported')
			}
		} else if 'bsonskip' in field.attrs {
		} else {
			return error('decode error: Key `$field.name` not found.')
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
	res := convert_from_bsondoc<T>(doc) ?
	return res
}
