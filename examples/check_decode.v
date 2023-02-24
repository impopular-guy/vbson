module main

import os
import vbson

fn main() {
	mut e := 0
	skip := [25, 40, 41, 46, 47, 52, 54, 57]
	for i in 1 .. 59 {
		if i in skip {
			e++
			println('\ntest${i}.bson: SKIPPED')
			continue
		}
		f := 'C:\\Users\\dhrit\\.vmodules\\vbson\\src\\test_binaries\\binary\\test${i}.bson'
		if os.exists(f) && os.is_file(f) {
			data := os.read_file(f)!
			dec := vbson.raw_decode(data) or {
				if !err.str().contains('deprecated') {
					e++
					println('\nERROR${i} (len:${data.len}): ${err}')
					continue
				}
				map[string]vbson.Any{}
			}
			if data.len > 5 && dec.len < 1 {
				e++
				println('\nERROR${i} (len:${data.len}): EMPTY ${dec}')
				continue
			}
			println('\ntest${i}.bson (len:${data.len}): ${dec}')
		}
	}
	println('Total Failed: ${e}')
}
