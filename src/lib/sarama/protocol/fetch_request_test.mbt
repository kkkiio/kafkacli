///|
test "TestFetchRequestNoBlocks" {
  let req = FetchRequest::new()
  let bytes = encode_only_body(req)
  @json.inspect(
    bytes,
    content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00",
  )
  let req2 : FetchRequest = decode_only_body(bytes, req.version())
  assert_eq(req.to_json(), req2.to_json())
}

///|
test "TestFetchRequestWithProperties" {
  let request = FetchRequest::new()
  request.max_wait_time = 0x20
  request.min_bytes = 0xEF
  let bytes = encode_only_body(request)
  @json.inspect(
    bytes,
    content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00 \\x00\\x00\\x00\\xef\\x00\\x00\\x00\\x00",
  )
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "TestFetchRequestOneBlock" {
  let request = FetchRequest::new()
  request.max_wait_time = 0
  request.min_bytes = 0
  request.add_block("topic", 0x12, 0x34, 0x56, -1)
  let bytes = encode_only_body(request)
  @json.inspect(
    bytes,
    content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x01\\x00\\x05topic\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x12\\x00\\x00\\x00\\x00\\x00\\x00\\x004\\x00\\x00\\x00V",
  )
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "TestFetchRequestOneBlockV4" {
  let request = FetchRequest::with_version(4)
  request.max_bytes = 0xFF
  request.isolation_level = ReadCommitted
  request.add_block("topic", 0x12, 0x34, 0x56, -1)
  let bytes = encode_only_body(request)
  @json.inspect(
    bytes,
    content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xff\\x01\\x00\\x00\\x00\\x01\\x00\\x05topic\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x12\\x00\\x00\\x00\\x00\\x00\\x00\\x004\\x00\\x00\\x00V",
  )
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "TestFetchRequestOneBlockV11" {
  let request = FetchRequest::with_version(11)
  request.max_bytes = 0xFF
  request.isolation_level = ReadCommitted
  request.session_id = 0xAA
  request.session_epoch = 0xEE
  request.add_block("topic", 0x12, 0x34, 0x56, 0x66)
  request.rack_id = "rack01"
  let bytes = encode_only_body(request)
  @json.inspect(
    bytes,
    content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xff\\x01\\x00\\x00\\x00\\xaa\\x00\\x00\\x00\\xee\\x00\\x00\\x00\\x01\\x00\\x05topic\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x12\\x00\\x00\\x00f\\x00\\x00\\x00\\x00\\x00\\x00\\x004\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00V\\x00\\x00\\x00\\x00\\x00\\x06rack01",
  )
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "TestFetchRequestVersion7" {
  let request = FetchRequest::with_version(7)
  request.session_id = 0x123
  request.session_epoch = 0x456
  request.add_block("test", 0, 100, 1024, 0)
  let bytes = encode_only_body(request)
  // Verify that session fields are encoded
  assert_eq(bytes.length(), 67) // Includes session metadata and forgotten array
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "TestFetchRequestVersion3" {
  let request = FetchRequest::with_version(3)
  request.max_bytes = 1024
  request.add_block("test", 0, 100, 512, 0)
  let bytes = encode_only_body(request)
  // Version 3 should include max_bytes field
  assert_eq(bytes.length(), 46) // Includes max_bytes and partition block
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "TestFetchRequestMultipleBlocks" {
  let request = FetchRequest::new()
  request.add_block("topic1", 0, 100, 1024, 0)
  request.add_block("topic1", 1, 200, 2048, 0)
  request.add_block("topic2", 0, 300, 4096, 0)
  let bytes = encode_only_body(request)
  let decoded : FetchRequest = decode_only_body(bytes, request.version())
  assert_eq(request.to_json(), decoded.to_json())

  // Verify decoded request has correct blocks
  assert_eq(request.blocks.length(), 2)
  assert_eq(request.blocks["topic1"].length(), 2)
  assert_eq(request.blocks["topic2"].length(), 1)
}
