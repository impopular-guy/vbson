module main

import time

struct SubDoc {
	aa int = 123
}

struct Document0 {
	a  int
	a1 u32
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

struct ObjectID {
	id string
}

type Any = ObjectID
	| []Any
	| bool
	| f32
	| f64
	| i16
	| i64
	| i8
	| int
	| map[string]Any
	| string
	| time.Time
	| u16
	| u32
	| u64
	| u8

fn encode_any[T](data T) !Any {
	$if T is bool {
		return data
	} $else $if T in [f32, f64] {
		return data
	} $else $if T in [i8, i16, int, i64] {
		return data
	} $else $if T in [u8, u16, u32, u64] {
		return data
	} $else $if T is string {
		return data
	} $else $if T is time.Time {
		// TODO
		return error('time.Time not supported yet. Use attr [bsonskip] to ignore this field.')
	} $else {
		return error('Unsupported type `${typeof(data).name}` for encoding')
	}
}

fn encode_struct[T](data T) !map[string]Any {
	mut res := map[string]Any{}
	$for field in T.fields {
		if 'bsonskip' !in field.attrs {
			field_name := field.name

			$if field.is_array {
				x := data.$(field.name)
				res[field_name] = encode_array(x)!
			} $else $if field.is_struct {
				x := data.$(field.name)
				res[field_name] = encode_struct(x)!
			} $else $if field.is_map {
				// TODO
				return error('Map not supported yet. Use attr [bsonskip] to ignore this field.')
			} $else $if field.typ is string {
				if 'bson_id' in field.attrs {
					res[field_name] = ObjectID{data.$(field.name)}
				} else {
					res[field_name] = Any(data.$(field.name))
				}
			} $else $if field.typ is time.Time {
				// TODO
				return error('time.Time not supported yet. Use attr [bsonskip] to ignore this field.')
			} $else $if field.is_chan {
				return error('`chan` not supported. Use attr [bsonskip] to ignore this field.')
			} $else $if field.typ in [bool, f32, f64, i8, i16, int, i64, u8, u16, u32, u64] {
				x := data.$(field.name)
				res[field_name] = encode_any(x)!
			} $else {
				return error('Unsupported type for `${field.name}` for encoding. Use attr [bsonskip] to ignore this field.')
			}
		}
	}
	return res
}

fn encode_array[T](arr []T) ![]Any {
	mut res := []Any{}
	for a in arr {
		$if a is $Array {
			// TODO this should be encode_array
			res << encode_any(a)!
		} $else $if a is $Struct {
			res << encode_struct(a)!
		} $else {
			res << encode_any(a)!
		}
	}
	return res
}

fn main() {
	d := Document0{
		a: 1
		b: 1.1
		c: 'qwerty'
		d: [true, false]
		f: ['qqq', 'aaa']
		g: {
			'one': 1
			'two': 2
		}
		h1: []SubDoc{len: 2}
	}
	println(d)
	map_data := encode_struct(d)!
	pretty_print(map_data, '')
}

fn pretty_print(data map[string]Any, tab string) {
	println('{')
	for k, v in data {
		print('${tab}    ${k}: ')
		match v {
			ObjectID { print('ObjectID{ id: \'${v.id}\' }') }
			// []Any { print('${v}') }
			map[string]Any { pretty_print(v, tab + '    ') }
			else { print('${v}') }
		}
		println('')
	}
	println('${tab}}')
}
