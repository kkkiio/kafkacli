/// Test functions for FetchRequest

///|
test "TestFetchRequestNoBlocks" {
  let request = FetchRequest::new()
  let (packet, body_offset) = encode_test_request(request)
  // Expected: replica_id(-1) + max_wait_time(0) + min_bytes(0) + empty blocks
  @json.inspect(packet[body_offset:].to_bytes(), content=("\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00"))
  test_request_decode(request, packet)
}

///|
test "TestFetchRequestWithProperties" {
  let request = FetchRequest::new()
  request.max_wait_time = 0x20
  request.min_bytes = 0xEF
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content=("\\xff\\xff\\xff\\xff\\x00\\x00\\x00 \\x00\\x00\\x00\\xef\\x00\\x00\\x00\\x00"))
  test_request_decode(request, packet)
}

///|
test "TestFetchRequestOneBlock" {
  let request = FetchRequest::new()
  request.max_wait_time = 0
  request.min_bytes = 0
  request.add_block("topic", 0x12, 0x34, 0x56, -1)
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content=("\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x01\\x00\\x05topic\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x12\\x00\\x00\\x00\\x00\\x00\\x00\\x004\\x00\\x00\\x00V"))
  test_request_decode(request, packet)
}

///|
test "TestFetchRequestOneBlockV4" {
  let request = FetchRequest::with_version(4)
  request.max_bytes = 0xFF
  request.isolation_level = ReadCommitted
  request.add_block("topic", 0x12, 0x34, 0x56, -1)
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content=("\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xff\\x01\\x00\\x00\\x00\\x01\\x00\\x05topic\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x12\\x00\\x00\\x00\\x00\\x00\\x00\\x004\\x00\\x00\\x00V"))
  test_request_decode(request, packet)
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
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content=("\\xff\\xff\\xff\\xff\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\xff\\x01\\x00\\x00\\x00\\xaa\\x00\\x00\\x00\\xee\\x00\\x00\\x00\\x01\\x00\\x05topic\\x00\\x00\\x00\\x01\\x00\\x00\\x00\\x12\\x00\\x00\\x00f\\x00\\x00\\x00\\x00\\x00\\x00\\x004\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00V\\x00\\x00\\x00\\x00\\x00\\x06rack01"))
  test_request_decode(request, packet)
}

///|
test "TestFetchRequestVersion7" {
  let request = FetchRequest::with_version(7)
  request.session_id = 0x123
  request.session_epoch = 0x456
  request.add_block("test", 0, 100, 1024, 0)
  let (packet, body_offset) = encode_test_request(request)
  // Verify that session fields are encoded
  let body_bytes = packet[body_offset:].to_bytes()
  assert_eq(body_bytes.length(), 67) // Includes session metadata and forgotten array
  test_request_decode(request, packet)
}

///|
test "TestFetchRequestVersion3" {
  let request = FetchRequest::with_version(3)
  request.max_bytes = 1024
  request.add_block("test", 0, 100, 512, 0)
  let (packet, body_offset) = encode_test_request(request)
  // Version 3 should include max_bytes field
  let body_bytes = packet[body_offset:].to_bytes()
  assert_eq(body_bytes.length(), 46) // Includes max_bytes and partition block
  test_request_decode(request, packet)
}

///|
test "TestFetchRequestMultipleBlocks" {
  let request = FetchRequest::new()
  request.add_block("topic1", 0, 100, 1024, 0)
  request.add_block("topic1", 1, 200, 2048, 0)
  request.add_block("topic2", 0, 300, 4096, 0)
  let (packet, body_offset) = encode_test_request(request)
  test_request_decode(request, packet)

  // Verify decoded request has correct blocks
  assert_eq(request.blocks.length(), 2)
  assert_eq(request.blocks["topic1"].length(), 2)
  assert_eq(request.blocks["topic2"].length(), 1)
}
