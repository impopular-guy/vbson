module vbson

fn check2<T>(d T) {
    enc := encode<T>(d)
    dd := decode<T>(enc) or { panic(err) }
    assert d == dd
}

struct Document0{}

struct Document1 {
    var_int int
}

struct Document2 {
    var_int int
    var_i64 i64
}

struct Document3 {
    a bool
    b bool
    c int
    d i64
    e u64
}


fn test_basic() {
    d0 := Document0{}
    check2<Document0>(d0)

    d1 := Document1{120}
    check2<Document1>(d1)

    d2 := Document2{120, 8589934592}
    check2<Document2>(d2)

    d3 := Document3{true,false,120,8589934592,9223372036854776808}
    check2<Document3>(d3)

    d4 := Document2{-2147483648,-9223372036854775808}
    check2<Document2>(d4)

    d5 := Document2{2147483647,9223372036854775807}
    check2<Document2>(d5)
}

fn test_encode(){
    d1 := Document1{120}
    enc1 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
    assert encode<Document1>(d1) == enc1

    d2 := Document2{120, 8589934592}
    enc2 := '#\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x12var_i64\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00'
    assert encode<Document2>(d2) == enc2

    d3 := Document3{true,false,120,8589934592,9223372036854776808}
    enc3 := '*\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x11e\x00\xe8\x03\x00\x00\x00\x00\x00\x80\x00'
    assert encode<Document3>(d3) == enc3
}

fn test_decode() ? {
    // enc1 := '\x05\x00\x00'
    // d1 := decode<Document1>(enc1) ?
    // should return error

    enc2 := '\x05\x00\x00\x00\x00'
    d2 := decode<Document1>(enc2) ?
    assert d2 == Document1{}

    enc3 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00\x00\x00'
    d3 := decode<Document1>(enc3) ?
    assert d3 == Document1{120}

    enc4 := '*\x00\x00\x00\x08a\x00\x01\x08b\x00\x00\x10c\x00x\x00\x00\x00\x12d\x00\x00\x00\x00\x00\x02\x00\x00\x00\x11e\x00\xe8\x03\x00\x00\x00\x00\x00\x80\x00'
    d4 := decode<Document3>(enc4) ?
    assert d4 == Document3{true,false,120,8589934592,9223372036854776808}

    // enc5 := '\x12\x00\x00\x00\x10var_int\x00x\x00\x00'
    // d5 := decode<Document1>(enc5) ?
    // should return error
}
