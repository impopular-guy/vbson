module vbson

fn f32_bits(f f32) u32 {
	p := *unsafe { &u32(&f) }
	return p
}

fn f32_from_bits(b u32) f32 {
	p := *unsafe { &f32(&b) }
	return p
}

fn f64_bits(f f64) u64 {
	p := *unsafe { &u64(&f) }
	return p
}

fn f64_from_bits(b u64) f64 {
	p := *unsafe { &f64(&b) }
	return p
}

// https://babbage.cs.qc.cuny.edu/ieee-754.old/decimal.html
[inline]
fn f64_to_f32(v f64) f32 {
	ui_64 := f64_bits(v)
	e := u32(int((ui_64 >> 52) & 0x7FF) - 1023 + 127)
	ui_32 := u32((ui_64 >> 29) & 0x7FFFFF) | u32((e << 23) & 0x7F800000) | u32((ui_64 >> 32) & 0x80000000)
	return f32_from_bits(ui_32)
}

fn convert_to_bsondoc<T>(data T) ?BsonDoc {
	mut doc := BsonDoc{}
	$for field in T.fields {
		if !('bsonskip' in field.attrs) {
			$if field.typ is string {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is bool {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is int {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is i64 {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is f32 {
				doc.elements[field.name] = BsonAny(f64(data.$(field.name)))
			} $else $if field.typ is f64 {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is []string {
				mut sa := []BsonAny{}
				for v in data.$(field.name) { sa << BsonAny(v) }
				doc.elements[field.name] = sa
			} $else $if field.typ is []bool {
				mut ba := []BsonAny{}
				for v in data.$(field.name) { ba << BsonAny(v) }
				doc.elements[field.name] = ba
			} $else $if field.typ is []int {
				mut ia := []BsonAny{}
				for v in data.$(field.name) { ia << BsonAny(v) }
				doc.elements[field.name] = ia
			} $else $if field.typ is []i64 {
				mut i6a := []BsonAny{}
				for v in data.$(field.name) { i6a << BsonAny(v) }
				doc.elements[field.name] = i6a
			} $else $if field.typ is []f32 {
				mut f3a := []BsonAny{}
				for v in data.$(field.name) { f3a << BsonAny(f64(v)) }
				doc.elements[field.name] = f3a
			} $else $if field.typ is []f64 {
				mut fa := []BsonAny{}
				for v in data.$(field.name) { fa << BsonAny(v) }
				doc.elements[field.name] = fa
			} $else $if field.typ is Null {
				doc.elements[field.name] = BsonAny(data.$(field.name))
			} $else $if field.typ is ObjectID {
				doc.elements[field.name] = BsonAny(data.$(field.name))
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
				sa := elem as []BsonAny
				for v in sa { res.$(field.name) << v as string }
			} $else $if field.typ is []bool {
				ba := elem as []BsonAny
				for v in ba { res.$(field.name) << v as bool }
			} $else $if field.typ is []int {
				ia := elem as []BsonAny
				for v in ia { res.$(field.name) << v as int }
			} $else $if field.typ is []i64 {
				i6a := elem as []BsonAny
				for v in i6a { res.$(field.name) << v as i64 }
			} $else $if field.typ is []f32 {
				f3a := elem as []BsonAny
				for v in f3a { res.$(field.name) << f64_to_f32(v as f64) }
			} $else $if field.typ is []f64 {
				fa := elem as []BsonAny
				for v in fa { res.$(field.name) << v as f64 }
			} $else $if field.typ is Null {
				res.$(field.name) = elem as Null
			} $else $if field.typ is ObjectID {
				res.$(field.name) = elem as ObjectID
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
