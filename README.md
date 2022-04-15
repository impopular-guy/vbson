# vbson

Independent BSON implementation in V programming language.

> NOTE: This library is primarily meant to be used inside "nosqlite" only. Although people may use it as they see fit.

### Quickstart

```v
import vbson

struct SomeStruct {
    a bool
    b int
    c i64
    d u64
}

fn main() {
    d := SomeStruct{true,120,8589934592,9223372036854776808}
    
    enc := vbson.encode<SomeStruct>(d)
    assert typeof(enc).name == 'string'

    dec := vbson.decode<SomeStruct>(enc) ?
    assert d == dec
}
```
