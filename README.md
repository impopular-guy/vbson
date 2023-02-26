# vbson

Independent BSON implementation in V programming language.

> NOTE: This is an experimental library and is meant for learning purpose. It is not a complete implementation of BSON. Not recommended for professional use.

### Installation
```
v install impopular-guy.vbson
```

### TODO

- [x] Encoding
- [ ] Decoding
- [x] Basic JSON/BSON conversion
- [ ] Search one or more keys in BSON
- [ ] Update one or more keys in BSON
- [ ] Delete one or more keys from BSON
- [ ] Stream decoding
- [ ] Advanced searching (search by values, etc)

### Quickstart

[docs](https://github.com/impopular-guy/vbson/blob/main/_docs/vbson.md)

> Generate docs using the command `v doc -no-timestamp -f md -m vbson .\src\`

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
    d := SomeStruct{
		a: true
		b: 120
		c: i64(8589934592)
		d: f64(-922.337)
		e: 'data'
	}
    
    enc := vbson.encode(d)!
    dec := vbson.decode[SomeStruct](enc)!
}
```

### Reference

[bsonspec.org](https://bsonspec.org/spec.html)