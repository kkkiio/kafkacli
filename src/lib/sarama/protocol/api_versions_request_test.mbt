///|
test "TestApiVersionsRequest" {
  let req = ApiVersionsRequest::new(0)
  let (packet, body_offset) = encode_request(req)
  @json.inspect(packet[body_offset:].to_bytes())
  test_request_decode(req, packet)
}

///|
test "TestApiVersionsRequestV3" {
  let req = ApiVersionsRequest::{
    version: 3,
    client_software_name: "sarama",
    client_software_version: "0.10.0",
  }
  let (packet, body_offset) = encode_request(req)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\x07sarama\\x070.10.0\\x00",
  )
  test_request_decode(req, packet)
}
