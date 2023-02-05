# module vbson




## Contents
- [encode](#encode)
- [Any](#Any)
- [Null](#Null)
- [ObjectID](#ObjectID)
- [Binary](#Binary)

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

## Any
```v
type Any = Binary
	| Null
	| ObjectID
	| []Any
	| bool
	| f64
	| i64
	| int
	| map[string]Any
	| string
	| time.Time
```

`Any` consists of only the types supported by bson

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

#### Powered by vdoc.
