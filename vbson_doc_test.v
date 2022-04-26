module vbson

fn check(b BsonDoc) ? {
	enc := encode_bsondoc(b)
	db := decode_to_bsondoc(enc) ?
	assert b == db
}

fn test_vbson() ? {
	mut e1 := map[string]ElemSumType{}
	e1['key1'] = 4321
	b1 := BsonDoc{1, e1}
	check(b1) ?

	e1['key2'] = "data"
	b2 := BsonDoc{2, e1}
	check(b2) ?
	
	mut e2 := map[string]ElemSumType{}
	e2['key3'] = b2
	e2['key4'] = f64(-543.321)
	b3 := BsonDoc{2, e2}
	check(b3) ?

	mut e3 := map[string]ElemSumType{}
	e3['key5'] = b2
	mut f1 := []ElemSumType{}
	f1 << ElemSumType(1234.123456)
	f1 << ElemSumType(-132)
	f1 << ElemSumType('data')
	f1 << ElemSumType(true)
	e3['key6'] = f1
	b4 := BsonDoc{2, e3}
	check(b4) ?
}
