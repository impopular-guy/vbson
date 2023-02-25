# module vbson




## Contents
- [raw_decode](#raw_decode)
- [map_to_bson](#map_to_bson)
- [encode](#encode)
- [raw_encode_struct](#raw_encode_struct)
- [Any](#Any)
- [Decimal128](#Decimal128)
- [MinKey](#MinKey)
- [Null](#Null)
- [ObjectID](#ObjectID)
- [Binary](#Binary)
- [MaxKey](#MaxKey)
- [JSCode](#JSCode)
- [Regex](#Regex)

## raw_decode
```v
fn raw_decode(data string) !map[string]Any
```

`raw_decode` takes in bson string input and returns
`map[string]Any` as output.  
It returns error if encoded data is incorrect.  

[[Return to contents]](#Contents)

## map_to_bson
```v
fn map_to_bson(m map[string]Any) string
```


[[Return to contents]](#Contents)

## encode
```v
fn encode[T](data T) !string
```

`encode` takes only struct as input and returns encoded bson as string or
returns error for failed encoding.  

Use attribute `bsonskip` to skip encoding of any field from a struct.  
Use attribute `bson_id` to specify a string field as mongo-style object id.  
TODO: Use attribute `bson:custom_name` to replace field name with a custom name.  

It cannot encode variables of fixed length arrays.  

[[Return to contents]](#Contents)

## raw_encode_struct
```v
fn raw_encode_struct[T](data T) !map[string]Any
```

`raw_encode_struct` is a pseudo encoder, encodes struct to a map for easier
encoding to bson.  

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

## Decimal128
```v
struct Decimal128 {
	bytes []u8
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

## JSCode
```v
struct JSCode {
	code string
}
```


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

#### Powered by vdoc.
