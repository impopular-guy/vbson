module vbson

fn test_json() {
	j1 := '{"name":"Bob","age":20,"birthday":"2022-03-11T13:54:25.000Z","a":[3,4,5]}'
	b1 := json_to_bson(j1)!
	jj1 := bson_to_json(b1)!
	assert j1 == jj1
}
