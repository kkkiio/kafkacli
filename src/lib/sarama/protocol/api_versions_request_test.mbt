///|
test "TestApiVersionsRequest" {
  let req = ApiVersionsRequest::default()
  let bytes = encode_only_body(req)
  @json.inspect(bytes)
  let req2 : ApiVersionsRequest = decode_only_body(bytes, req.version(), ApiVersionsRequest::decode)
  assert_eq(req.to_json(), req2.to_json())
}

///|
test "TestApiVersionsRequestV3" {
  let req = ApiVersionsRequest::{
    version: 3,
    client_software_name: "sarama",
    client_software_version: "0.10.0",
  }
  let bytes = encode_only_body(req)
  @json.inspect(bytes, content="\\x07sarama\\x070.10.0\\x00")
  let req2 : ApiVersionsRequest = decode_only_body(bytes, req.version(), ApiVersionsRequest::decode)
  assert_eq(req.to_json(), req2.to_json())
}
