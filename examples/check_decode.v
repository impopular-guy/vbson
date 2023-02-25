module main

import os
import vbson

fn main() {
	mut e := map[string]string{}
	dir := 'C:\\Users\\dhrit\\.vmodules\\vbson\\src\\test_binaries\\binary\\'
	files := os.ls(dir)!
	for file in files {
		// print('\n${file} ')
		if file in ['stackoverflow.bson', 'trailingnull.bson'] {
			println('SKIPPED')
			continue
		}
		data := os.read_file(dir + file)!
		// print('(len:${data.len}): ${data.bytes()}')
		dec := vbson.raw_decode(data) or {
			e[file] = get_error(err.str())
			println(err)
			continue
			map[string]vbson.Any{}
		}
		// print(dec)
		enc := vbson.map_to_bson(dec)
		assert data.bytes() == enc.bytes()
	}
	println(e)
}

fn get_error(err string) string {
	if err.contains('corrupt') {
		return 'corrupt'
	} else if err.contains('unsupported') {
		return 'unsupported'
	} else if err.contains('cannot contain') {
		return 'cannot contain'
	} else if err.contains('cannot begin') {
		return 'cannot begin'
	}
	return ''
}
