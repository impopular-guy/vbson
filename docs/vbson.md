# module vbson

## Contents
- [Constants](#Constants)
- [decode](#decode)
- [encode](#encode)
- [decode_to_bsondoc](#decode_to_bsondoc)
- [encode_bsondoc](#encode_bsondoc)
- [BsonAny](#BsonAny)
- [ElementType](#ElementType)
- [Binary](#Binary)
- [BsonDoc](#BsonDoc)
- [Null](#Null)
- [ObjectID](#ObjectID)

## Constants
```v
const (
	unused_types = [0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xFF, 0x7F]
)
```

List of unsupported/deprecated element types and binary sub types.  

[[Return to contents]](#Contents)

## decode
```v
fn decode<T>(data string) ?T
```

`T` should comply with given encoded string.  

[[Return to contents]](#Contents)

## encode
```v
fn encode<T>(data T) ?string
```

`T` can be any user-defined struct.  
Use attribute [bsonskip] to skip encoding of any field from a struct.  
It cannot encode variables of `fixed length arrays`.  

[[Return to contents]](#Contents)

## decode_to_bsondoc
```v
fn decode_to_bsondoc(data string) ?BsonDoc
```

Returns error if encoded data is incorrect.  

[[Return to contents]](#Contents)

## encode_bsondoc
```v
fn encode_bsondoc(doc BsonDoc) string
```


[[Return to contents]](#Contents)

## BsonAny
```v
type BsonAny = Binary
	| BsonDoc
	| Null
	| ObjectID
	| []BsonAny
	| bool
	| f64
	| i64
	| int
	| string
	| time.Time
```

SumType used to store multiple BsonElement types in single array.  

[[Return to contents]](#Contents)

## ElementType
```v
enum ElementType {
	e_double = 0x01
	e_string = 0x02
	e_document
	e_array
	e_binary
	e_object_id = 0x07
	e_bool = 0x08
	e_utc_datetime
	e_null = 0x0A
	e_int = 0x10
	e_timestamp
	e_i64 = 0x12
	e_decimal128
}
```

This enum is a list of element types that are currently supported in this module.  
Reference: [bsonspec.org](https://bsonspec.org/spec.html)

[[Return to contents]](#Contents)

## Binary
```v
struct Binary {
pub mut:
	b_type int
	data   []u8
}
```

Wrapper for binary data. Binary sub-type is stored in `b_type` and data is in the form of a byte array.  

[[Return to contents]](#Contents)

## BsonDoc
```v
struct BsonDoc {
pub mut:
	n_elems  int
	// no. of elements in the document
	elements map[string]BsonAny
	// array of elements of the document
}
```

Helper struct to decode/encode bson data. Can be used in situations where input
in specific format is converted into a `BsonDoc`.  

[[Return to contents]](#Contents)

## Null
```v
struct Null {
}
```


[[Return to contents]](#Contents)

## ObjectID
```v
struct ObjectID {
	id string
}
```

Wrapper for mongo-style onjectID

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 26 Apr 2022 19:06:50
