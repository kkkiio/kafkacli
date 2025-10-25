///|
test "ListGroupsRequest v0 - empty body" {
  let request = @protocol.ListGroupsRequest::with_version(0)
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b""
  ))
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest v1 - empty body" {
  let request = @protocol.ListGroupsRequest::with_version(1)
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b""
  ))
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest v2 - empty body" {
  let request = @protocol.ListGroupsRequest::with_version(2)
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b""
  ))
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest v3 - with tagged fields" {
  let request = @protocol.ListGroupsRequest::with_version(3)
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b"\x00"
  )) // empty tagged field array
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest v4 - empty states filter" {
  let request = @protocol.ListGroupsRequest::with_version(4)
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b"\x01\x00"
  )) // compact array length (0) + empty tagged fields
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest v4 - with states filter" {
  let request = @protocol.ListGroupsRequest::with_version(4)
  request.states_filter = ["Empty"]
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b"\x02\x06Empty\x00"
  )) // compact array length (1) + "Empty" + tagged fields
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest v5 - with states and types filter" {
  let request = @protocol.ListGroupsRequest::with_version(5)
  request.states_filter = ["Empty"]
  request.types_filter = ["Classic"]
  let bytes = encode_only_body(request)
  inspect(bytes, content=(#|b"\x02\x06Empty\x02\x08Classic\x00"
  )) // states array + types array + tagged fields
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    request.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest roundtrip v0" {
  let original = @protocol.ListGroupsRequest::with_version(0)
  let bytes = encode_only_body(original)
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    original.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(original.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest roundtrip v3" {
  let original = @protocol.ListGroupsRequest::with_version(3)
  let bytes = encode_only_body(original)
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    original.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(original.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest roundtrip v4 with filters" {
  let original = @protocol.ListGroupsRequest::with_version(4)
  original.states_filter = ["Empty", "Stable"]
  let bytes = encode_only_body(original)
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    original.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(original.to_json(), decoded.to_json())
}

///|
test "ListGroupsRequest roundtrip v5 with filters" {
  let original = @protocol.ListGroupsRequest::with_version(5)
  original.states_filter = ["Empty"]
  original.types_filter = ["Classic", "Consumer"]
  let bytes = encode_only_body(original)
  let decoded : @protocol.ListGroupsRequest = decode_only_body(
    bytes,
    original.version(),
    @protocol.ListGroupsRequest::decode,
  )
  assert_eq(original.to_json(), decoded.to_json())
}
