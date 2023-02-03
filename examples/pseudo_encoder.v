module main

import time

struct SubDoc {
	aa int = 123
}

struct Document0 {
	a  int
	a1 u32
	b  f64
	c  string         [bson_id]
	c1 string
	d  []bool
	f  []string
	g  map[string]int [bsonskip]
	h  SubDoc
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
	} $else $if T is f32 {
		return f64(data)
	} $else $if T is f64 {
		return data
	} $else $if T is i16 {
		return int(data)
	} $else $if T is i64 {
		return data
	} $else $if T is i8 {
		return int(data)
	} $else $if T is int {
		return data
	} $else $if T is string {
		return data
	} $else $if T is u16 {
		return int(data)
	} $else $if T is u32 {
		return i64(data)
	} $else $if T is u64 {
		return i64(data)
	} $else $if T is u8 {
		return int(data)
	} $else $if T is $Struct {
		return encode_struct[T](data)!
	} $else $if T is $Map {
		// TODO
		return error('Map not supported yet')
	} $else $if T is $Array {
		return error('To encode array, use `encode_array` function. Caution, higher dimension arrays not supported.')
	} $else {
		return error('Unsupported type `${typeof(data).name}` for encoding')
	}
}

fn encode_struct[T](data T) !map[string]Any {
	mut res := map[string]Any{}
	$for field in T.fields {
		if 'bsonskip' !in field.attrs {
			$if field.is_array {
				arr := data.$(field.name)
				res[field.name] = encode_array(arr)!
			} $else $if field.is_struct {
				st := data.$(field.name)
				res[field.name] = encode_struct(st)!
			} $else $if field.is_map {
				// TODO
				return error('Map not supported yet')
			} $else $if field.typ is string {
				if 'bson_id' in field.attrs {
					res[field.name] = ObjectID{data.$(field.name)}
				} else {
					res[field.name] = Any(data.$(field.name))
				}
			} $else {
				x := data.$(field.name)
				res[field.name] = encode_any(x)!
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
