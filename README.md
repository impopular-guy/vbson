# vbson

Independent BSON implementation in V programming language.

> NOTE: This is an experimental library and is meant for learning purpose. It is not a complete implementation of BSON. Not recommended for professional use.

### Installation
```
v install impopular-guy.vbson
```

### TODO

- [x] Encode/decode `struct` with basic datatypes and arrays
- [ ] Search one or more keys in bson document
- [ ] Update one or more keys in bson document
- [ ] Delete one or more keys from bson document
- [ ] Stream decoding

### Quickstart

[docs](https://github.com/impopular-guy/vbson/blob/main/docs/vbson.md)

```v
import impopular_guy.vbson

struct SomeStruct {
mut:
    a bool
    b int
    c i64
    d f64
    e string
}

fn main() {
    // example 1
    mut d := SomeStruct{}
    d.a = true
    d.b = 120
    d.c = i64(8589934592)
    d.d = f64(-922.337)
    d.e = 'data'
    
    enc := vbson.encode<SomeStruct>(d) or { '' }
    dec := vbson.decode<SomeStruct>(enc) or { SomeStruct{} }
    assert d == dec

    // example 2
    mut m := map[string]vbson.BsonAny{}
    m['a'] = true
    m['b'] = 120
    m['c'] = i64(8589934592)
    m['d'] = f64(-922.337)
    m['e'] = 'data'
    doc := vbson.BsonDoc{5, m}
    
    enc1 := vbson.encode_bsondoc(doc)
    assert enc == enc1

    dec1 := vbson.decode_to_bsondoc(enc1) or { vbson.BsonDoc{} }
    assert doc == dec1

    dec2 := vbson.decode<SomeStruct>(enc1) or { SomeStruct{} }
    assert d == dec2
}
```
