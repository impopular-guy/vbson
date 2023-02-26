module vbson

import os

fn test_map_encode_decode() {
	enc1 := '\x05\x00\x00\x00\x00'
	enc2 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
	enc3 := ':\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x02e\x00\x14\x00\x00\x009223372036854776808\x00\x00'

	r_dec1 := bson_to_map(enc1)!
	r_dec2 := bson_to_map(enc2)!
	r_dec3 := bson_to_map(enc3)!

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

	r_enc1 := map_to_bson(dec1)
	r_enc2 := map_to_bson(dec2)
	r_enc3 := map_to_bson(dec3)

	assert enc1 == r_enc1
	assert enc2 == r_enc2
	assert enc3 == r_enc3
	println('done')
}

fn test_binaries() {
	// $if linux {
	// 	// fails in CI as unable to list files
	// 	return
	// }
	err_map := {
		'binary_deprecated.bson':  'unsupported'
		'cdriver2269.bson':        'corrupt'
		'codewscope.bson':         'unsupported'
		'code_w_empty_scope.bson': 'unsupported'
		'dollarquery.bson':        'cannot begin'
		'dotquery.bson':           'cannot contain'
		'overflow1.bson':          'corrupt'
		'overflow2.bson':          'corrupt'
		'overflow3.bson':          'corrupt'
		'overflow4.bson':          'corrupt'
		'stream.bson':             'corrupt'
		'stream_corrupt.bson':     'corrupt'
		'test25.bson':             'unsupported'
		'test28.bson':             'unsupported'
		'test31.bson':             'unsupported'
		'test32.bson':             'unsupported'
		'test40.bson':             'corrupt'
		'test41.bson':             'corrupt'
		'test42.bson':             'unsupported'
		'test43.bson':             'unsupported'
		'test44.bson':             'unsupported'
		'test45.bson':             'unsupported'
		'test46.bson':             'corrupt'
		'test47.bson':             'corrupt'
		'test48.bson':             'unsupported'
		'test49.bson':             'unsupported'
		'test50.bson':             'unsupported'
		'test51.bson':             'unsupported'
		'test52.bson':             'corrupt'
		'test53.bson':             'unsupported'
		'test54.bson':             'corrupt'
		'test55.bson':             'corrupt'
		'test57.bson':             'unsupported'
		'test59.bson':             'cannot contain'
	}

	dirs := ['.vmodules', 'vbson', 'src', 'test_binaries', 'binary']
	dir := if os.home_dir().starts_with('/home/runner') {
		'/home/runner/work/vbson/vbson/vbson/src/test_binaries/binary/'
	} else {
		os.join_path(os.home_dir(), ...dirs) + os.path_separator
	}
	files := os.ls(dir)!
	for file in files {
		if file in ['stackoverflow.bson', 'trailingnull.bson'] {
			println('SKIPPED')
			continue
		}
		data := os.read_file(dir + file)!
		dec := bson_to_map(data) or {
			err_type := err_map[file] or { 'RANDOM' }
			assert err.str().contains(err_type)
			continue
			map[string]Any{}
		}
		enc := map_to_bson(dec)
		assert data == enc
	}
	println('done')
}
