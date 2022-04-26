module vbson

fn check2<T>(d T) ? {
	enc := encode<T>(d) ?
	dd := decode<T>(enc) or { panic(err) }
	assert d == dd
}

struct Document0 {}

struct Document1 {
	var_int int
}

struct Document2 {
	var_int int
	var_i64 i64
}

struct Document3 {
	a bool
	b bool
	c int
	d i64
	e string
}

struct Document4 {
	b f64
	c f64
}

struct Document5 {
	a []int
	b []f64
	c []string
	d []bool
	// e [2]int // fails
}

fn test_basic() ? {
	d0 := Document0{}
	check2<Document0>(d0) ?

	d1 := Document1{120}
	check2<Document1>(d1) ?

	d2 := Document2{120, 8589934592}
	check2<Document2>(d2) ?

	d3 := Document3{true, false, 120, 8589934592, "9223372036854776808"}
	check2<Document3>(d3) ?

	d4 := Document2{-2147483648, -9223372036854775808}
	check2<Document2>(d4) ?

	d5 := Document2{2147483647, 9223372036854775807}
	check2<Document2>(d5) ?

	d6 := Document4{1234.123456, -1324356.2345}
	check2<Document4>(d6) ?

	d7 := Document4{12343453.134534523456, -1323453454356.23534534545}
	check2<Document4>(d7) ?

	d9 := Document5{[120,130], [1234.123456, -1324356.2345], ["data1", "data2"], [true, false]}
	check2<Document5>(d9) ?
}

fn test_encode() ? {
	/*
	This type testing is incorrect. When bson encoding is correct
	but order of variables is different, below assertions will fail.
	It is implemented only for initial testing purpose.
	*/

	d1 := Document1{120}
	enc1 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
	de1 := encode<Document1>(d1) ?
	assert de1 == enc1

	d2 := Document2{120, 8589934592}
	enc2 := '#\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x12var_i64\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00'
	de2 := encode<Document2>(d2) ?
	assert de2 == enc2

	d3 := Document3{true, false, 120, 8589934592, "9223372036854776808"}
	enc3 := ':\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02e\x00\x14\x00\x00\x009223372036854776808\x00\x00'
	de3 := encode<Document3>(d3) ?
	assert de3 == enc3
}

fn test_decode() ? {
	/*
	This type testing is incorrect. When bson encoding is correct
	but order of variables is different, below assertions will fail.
	It is implemented only for initial testing purpose.
	*/

	// enc1 := '\x05\x00\x00'
	// d1 := decode<Document1>(enc1) ?
	// should return error

	enc2 := '\x05\x00\x00\x00\x00'
	d2 := decode<Document1>(enc2) ?
	assert d2 == Document1{}

	enc3 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
	d3 := decode<Document1>(enc3) ?
	assert d3 == Document1{120}

	enc4 := ':\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02e\x00\x14\x00\x00\x009223372036854776808\x00\x00'
	d4 := decode<Document3>(enc4) ?
	assert d4 == Document3{true, false, 120, 8589934592, "9223372036854776808"}

	// enc5 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00'
	// d5 := decode<Document1>(enc5) ?
	// should return error
}
