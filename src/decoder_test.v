module vbson

fn test_raw_decode() {
	enc1 := '\x05\x00\x00\x00\x00'
	enc2 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
	enc3 := ':\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02e\x00\x14\x00\x00\x009223372036854776808\x00\x00'

	r_dec1 := raw_decode(enc1)!
	r_dec2 := raw_decode(enc2)!
	r_dec3 := raw_decode(enc3)!

	dec1 := map[string]Any{}
	assert dec1 == r_dec1

	dec2 := {
		'var_int': Any(120)
	}
	assert dec2 == r_dec2

	dec3 := {
		'a': Any(true)
		'b': Any(false)
		'c': Any(120)
		'd': Any(i64(8589934592))
		'e': Any('9223372036854776808')
	}
	assert dec3 == r_dec3
}
