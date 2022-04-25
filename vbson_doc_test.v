module vbson

fn check(b BsonDoc) ? {
	enc := encode_bsondoc(b)
	db := decode_to_bsondoc(enc) ?
	assert b == db
}

fn test_vbson() ? {
	e1 := BsonElement<int>{'key1', ElementType.e_int, 4321}
	b1 := BsonDoc{1, {'key1':0}, [e1]}
	check(b1) ?

	e2 := BsonElement<string>{'key2', ElementType.e_string, "data"}
	b2 := BsonDoc{2, {'key1':0, 'key2':1}, [e1, e2]}
	check(b2) ?
	
	e3 := BsonElement<BsonDoc>{'key3', ElementType.e_document, b1}
	e4 := BsonElement<BsonDoc>{'key4', ElementType.e_document, b2}
	b3 := BsonDoc{4, {'key1':0, 'key2':1, 'key3':2, 'key4':3}, [e1, e2, e3, e4]}
	check(b3) ?	
}