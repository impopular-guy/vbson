# module vbson

## Contents
- [Constants](#Constants)
- [encode_bsondoc](#encode_bsondoc)
- [encode](#encode)
- [decode_to_bsondoc](#decode_to_bsondoc)
- [decode](#decode)
- [ElemSumType](#ElemSumType)
- [ElementType](#ElementType)
- [BinarySubType](#BinarySubType)
- [BsonDoc](#BsonDoc)
- [BsonElement](#BsonElement)

## Constants
```v
const (
	unused_types    = [0x06, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0xFF, 0x7F]
	unused_subtypes = [0x01, 0x02, 0x03, 0x06, 0x80]
)
```

List of unsupported/deprecated element types and binary sub types.  

[[Return to contents]](#Contents)

## encode_bsondoc
```v
fn encode_bsondoc(doc BsonDoc) string
```


[[Return to contents]](#Contents)

## encode
```v
fn encode<T>(data T) ?string
```

`T` can be any user-defined struct or `map[string]<T1>` where `T1` is any supported type.  
Use attribute [bsonskip] to skip encoding of any field from a struct

[[Return to contents]](#Contents)

## decode_to_bsondoc
```v
fn decode_to_bsondoc(data string) ?BsonDoc
```

Returns error if encoded data is incorrect.  

[[Return to contents]](#Contents)

## decode
```v
fn decode<T>(data string) ?T
```

`T` should comply with given encoded string.  

[[Return to contents]](#Contents)

## ElemSumType
```v
type ElemSumType = BsonElement<BsonDoc>
	| BsonElement<bool>
	| BsonElement<f64>
	| BsonElement<i64>
	| BsonElement<int>
	| BsonElement<string>
```

SumType used to store multiple BsonElement types in single array.  

[[Return to contents]](#Contents)

## ElementType
```v
enum ElementType {
	// e_00 = 0x00
	e_double = 0x01
	e_string = 0x02
	e_document
	// e_array
	// e_binary
	// e_object_id = 0x07
	e_bool = 0x08
	// e_utc_datetime
	// e_null = 0x0A
	e_int = 0x10
	// e_timestamp
	e_i64 = 0x12
	// e_decimal128
}
```

This enum is a list of element types that are currently supported in this module.  
Reference: [bsonspec.org](https://bsonspec.org/spec.html)

[[Return to contents]](#Contents)

## BinarySubType
```v
enum BinarySubType {
	s_generic = 0x00
	s_uuid = 0x04
	s_md5
}
```

This enum contains currently supported binary subtypes.  

[[Return to contents]](#Contents)

## BsonDoc
```v
struct BsonDoc {
pub mut:
	n_elems  int // no. of elements in the document
	elem_pos map[string]int // stores position of elements for easier search
	elements []ElemSumType  // array of elements of the document
}
```

Helper struct to decode/encode bson data. Can be used in situations where input
in specific format is converted into a `BsonDoc`.  

[[Return to contents]](#Contents)

## BsonElement
```v
struct BsonElement<T> {
pub mut:
	name   string // key name
	e_type ElementType
	value  T
}
```

Helper struct for storing different element types.  
`T` can be one of the following types only `bool, int, i64, u64, f64, string, BsonDoc, decimal128(soon)`.  

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 25 Apr 2022 09:27:35
