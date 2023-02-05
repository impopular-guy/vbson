# module vbson




## Contents
- [encode](#encode)

## encode
```v
fn encode[T](data T) !string
```

`encode` takes struct as input and returns encoded bson as string or
returns error for failed encoding.  
Use attribute [bsonskip] to skip encoding of any field from a struct.  
Use attribute [bson_id] to specify a string field as mongo-style object id.  
It cannot encode variables of fixed length arrays.  

[[Return to contents]](#Contents)

#### Powered by vdoc.
