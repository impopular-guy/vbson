module vbson

import x.json2 as json
import time
import strings

pub fn json_to_bson(j_data string) !string {
	json_map := json.raw_decode(j_data)!
	bson_map := jmap_to_bmap(json_map.as_map())
	return map_to_bson(bson_map)
}

pub fn bson_to_json(b_data string) !string {
	bson_map := bson_to_map(b_data)!
	return bson_map.to_json()!
}

fn jmap_to_bmap(jmap map[string]json.Any) map[string]Any {
	mut res := map[string]Any{}
	for k, jv in jmap {
		res[k] = match jv {
			json.Null { Any(Null{}) }
			bool { jv }
			f32, f64 { f64(jv) }
			i8, u8, i16, u16, int, u32 { int(jv) }
			i64, u64 { i64(jv) }
			map[string]json.Any { jmap_to_bmap(jv) }
			string { jv }
			time.Time { jv }
			[]json.Any { jarr_to_barr(jv) }
		}
	}
	return res
}

fn jarr_to_barr(ja []json.Any) []Any {
	temp := jmap_to_bmap(json.Any(ja).as_map())
	mut ba := []Any{}
	for _, v in temp {
		ba << v
	}
	return ba
}

// TODO may not be correct
pub fn (doc map[string]Any) to_json() !string {
	mut sb := strings.new_builder(4096)
	defer {
		unsafe { sb.free() }
	}

	sb.write([u8(`{`)])!
	l := doc.len
	mut i := 0
	for k, v in doc {
		s, wr := v.to_json()!
		if wr {
			sb.write('"${k}":'.bytes())!
			sb.write(s.bytes())!
			if i < l - 1 {
				sb.write([u8(`,`)])!
			}
		}

		i++
	}
	sb.write([u8(`}`)])!
	return sb.str()
}

pub fn (arr []Any) to_json() !string {
	mut sb := strings.new_builder(1024)
	defer {
		unsafe { sb.free() }
	}

	sb.write([u8(`[`)])!
	l := arr.len
	for i, v in arr {
		s, wr := v.to_json()!
		if wr {
			sb.write(s.bytes())!
			if i < l - 1 {
				sb.write([u8(`,`)])!
			}
		}
	}
	sb.write([u8(`]`)])!
	return sb.str()
}

fn (v Any) to_json() !(string, bool) {
	return match v {
		Null { 'null', true }
		string { '"${v}"', true }
		time.Time { '"${v}"', true }
		bool, int, i64, u64, f64 { v.str(), true }
		ObjectID { '"${v.id}"', true }
		map[string]Any { v.to_json()!, true }
		[]Any { v.to_json()!, true }
		MinKey, MaxKey, Regex, JSCode, Binary, Decimal128 { '', false }
	}
}
