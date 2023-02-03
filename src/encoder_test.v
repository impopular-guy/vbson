module vbson

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

struct SubDoc {
	aa int = 123
}

struct Document4 {
	a  int
	a1 u32
	a2 i64
	b  f64
	b1 f32
	c  string         [bson_id]
	c1 string
	d  []bool
	f  []string
	g  map[string]int [bsonskip]
	h  SubDoc
	h1 []SubDoc
	t  chan int       [bsonskip]
}

fn test_basic() ? {
	e0 := [u8(5), 0, 0, 0, 0].bytestr()
	// TODO find actual bson data
	e1 := [u8(176), 0, 0, 0, 16, 97, 0, 0, 0, 0, 0, 16, 97, 49, 0, 0, 0, 0, 0, 18, 97, 50, 0, 0,
		0, 0, 0, 0, 0, 0, 128, 1, 98, 0, 196, 67, 129, 145, 63, 66, 115, 194, 1, 98, 49, 0, 0,
		0, 0, 160, 19, 139, 103, 65, 7, 99, 0, 113, 119, 101, 114, 116, 121, 2, 99, 49, 0, 1, 0,
		0, 0, 0, 4, 100, 0, 13, 0, 0, 0, 8, 48, 0, 1, 8, 49, 0, 0, 0, 4, 102, 0, 27, 0, 0, 0, 2,
		48, 0, 4, 0, 0, 0, 113, 113, 113, 0, 2, 49, 0, 4, 0, 0, 0, 97, 97, 97, 0, 0, 3, 104, 0,
		13, 0, 0, 0, 16, 97, 97, 0, 123, 0, 0, 0, 0, 4, 104, 49, 0, 37, 0, 0, 0, 3, 48, 0, 13,
		0, 0, 0, 16, 97, 97, 0, 123, 0, 0, 0, 0, 3, 49, 0, 13, 0, 0, 0, 16, 97, 97, 0, 123, 0,
		0, 0, 0, 0, 0].bytestr()

	println('enc0: ${e0}')
	println('enc1: ${e1}')

	d0 := Document0{}
	assert e0 == encode(d0)!

	d1 := Document4{
		a: 8589934592
		a2: -9223372036854775808
		b: -1323453454356.23534534545
		b1: 12343453.134534523456
		c: 'qwerty'
		d: [true, false]
		f: ['qqq', 'aaa']
		g: {
			'one': 1
			'two': 2
		}
		h1: []SubDoc{len: 2}
	}
	assert e1 == encode(d1)!
}

fn test_encode() ? {
	/*
	This type testing is incorrect. When bson encoding is correct
	but order of variables is different, below assertions will fail.
	It is implemented only for initial testing purpose.
	*/

	d1 := Document1{120}
	enc1 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
	de1 := encode(d1)!
	assert de1 == enc1

	d2 := Document2{120, 8589934592}
	enc2 := '#\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x12var_i64\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00'
	de2 := encode(d2)!
	assert de2 == enc2

	d3 := Document3{true, false, 120, 8589934592, '9223372036854776808'}
	enc3 := ':\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02e\x00\x14\x00\x00\x009223372036854776808\x00\x00'
	de3 := encode(d3)!
	assert de3 == enc3
}
