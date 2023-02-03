module vbson

fn check(b BsonDoc) ? {
	enc := encode_bsondoc(b)
	db := decode_to_bsondoc(enc)?
	assert b == db
}

fn get_object_id() ObjectID {
	return ObjectID{'0123456789ab'}
}

fn test_vbson() ? {
	mut e1 := map[string]BsonAny{}
	e1['key1'] = 4321
	b1 := BsonDoc{1, e1}
	check(b1)?

	e1['key2'] = 'data'
	b2 := BsonDoc{2, e1}
	check(b2)?

	mut e2 := map[string]BsonAny{}
	e2['key3'] = b2
	e2['key4'] = f64(-543.321)
	b3 := BsonDoc{2, e2}
	check(b3)?

	mut e3 := map[string]BsonAny{}
	e3['key5'] = b2
	mut f1 := []BsonAny{}
	f1 << BsonAny(1234.123456)
	f1 << BsonAny(-132)
	f1 << BsonAny('data')
	f1 << BsonAny(true)
	e3['key6'] = f1
	b4 := BsonDoc{2, e3}
	check(b4)?

	b := Binary{0x00, 'zaewsxredcrfvtgbyn'.bytes()}
	mut e4 := map[string]BsonAny{}
	e4['key7'] = get_object_id()
	e4['key8'] = Null{}
	e4['key9'] = b
	b5 := BsonDoc{3, e4}
	check(b5)?
}
