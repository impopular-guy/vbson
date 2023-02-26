# module vbson




## Contents
- [encode](#encode)
- [map_to_bson](#map_to_bson)
- [bson_to_json](#bson_to_json)
- [bson_to_map](#bson_to_map)
- [json_to_bson](#json_to_bson)
- [map[string]Any](#map[string]Any)
  - [to_json](#to_json)
- [Any](#Any)
- [[]Any](#[]Any)
  - [to_json](#to_json)
- [Decimal128](#Decimal128)
- [Binary](#Binary)
- [MaxKey](#MaxKey)
- [MinKey](#MinKey)
- [Null](#Null)
- [ObjectID](#ObjectID)
- [Regex](#Regex)
- [JSCode](#JSCode)

## encode
```v
fn encode[T](data T) !string
```

`encode` takes only struct as input and returns BSON or
returns error for failed encoding.  

Use attribute `bsonskip` to skip encoding of any field from a struct.  
Use attribute `bson_oid` to specify a string field as mongo-style object id.  
TODO: Use attribute `bson:custom_name` to replace field name with a custom name.  

NOTE: It uses x.json2 raw encoding/decoding. So fields having json related attributes
result in unexpected behaviour.  

[[Return to contents]](#Contents)

## map_to_bson
```v
fn map_to_bson(m map[string]Any) string
```


[[Return to contents]](#Contents)

## bson_to_json
```v
fn bson_to_json(b_data string) !string
```


[[Return to contents]](#Contents)

## bson_to_map
```v
fn bson_to_map(data string) !map[string]Any
```

`bson_to_map` takes in bson string input and returns
`map[string]Any` as output.  
It returns error if encoded data is incorrect.  

[[Return to contents]](#Contents)

## json_to_bson
```v
fn json_to_bson(j_data string) !string
```


[[Return to contents]](#Contents)

## map[string]Any
## to_json
```v
fn (doc map[string]Any) to_json() !string
```

TODO may not be correct

[[Return to contents]](#Contents)

## Any
```v
type Any = Binary
	| Decimal128
	| JSCode
	| MaxKey
	| MinKey
	| Null
	| ObjectID
	| Regex
	| []Any
	| bool
	| f64
	| i64
	| int
	| map[string]Any
	| string
	| time.Time
	| u64
```

`Any` consists of only the types supported by bson

[[Return to contents]](#Contents)

## []Any
## to_json
```v
fn (arr []Any) to_json() !string
```


[[Return to contents]](#Contents)

## Decimal128
```v
struct Decimal128 {
	bytes []u8
}
```


[[Return to contents]](#Contents)

## Binary
```v
struct Binary {
mut:
	b_type u8
	data   []u8
}
```

`Binary` is a wrapper for binary data as per specs in [bsonspec.org](https://bsonspec.org/spec.html).  

[[Return to contents]](#Contents)

## MaxKey
```v
struct MaxKey {
}
```


[[Return to contents]](#Contents)

## MinKey
```v
struct MinKey {
}
```


[[Return to contents]](#Contents)

## Null
```v
struct Null {
	is_null bool = true
}
```

`Null` is placeholder for null/nil values.  

[[Return to contents]](#Contents)

## ObjectID
```v
struct ObjectID {
	id string
}
```

`ObjectID` is a wrapper for mongo-style objectID.  
NOTE: Object id should be only 12 bytes long.  

[[Return to contents]](#Contents)

## Regex
```v
struct Regex {
mut:
	pattern string
	options string
}
```


[[Return to contents]](#Contents)

## JSCode
```v
struct JSCode {
	code string
}
```


[[Return to contents]](#Contents)

#### Powered by vdoc.
