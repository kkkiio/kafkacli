///|
async test "TestApiVersionsRequest" {
  let apiVersionRequest : Bytes = b""
  let request = ApiVersionsRequest::new(0)
  test_request("basic", request, apiVersionRequest)
}

///|
async test "TestApiVersionsRequestV3" {
  let apiVersionRequestV3 : Bytes = Bytes::from_array([
    0x07, 's', 'a', 'r', 'a', 'm', 'a', 0x07, '0', '.', '1', '0', '.', '0', 0x00,
  ])
  let request = ApiVersionsRequest::{
    version: 3,
    client_software_name: "sarama",
    client_software_version: "0.10.0",
  }
  test_request("v3", request, apiVersionRequestV3)
}
