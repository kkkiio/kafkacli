///|
test "DescribeConfigsRequest v1 encode decode" {
  let resource = DescribeConfigsRequestResource::{
    version: 1,
    resource_type: 2,
    resource_name: "users",
    configuration_keys: None,
  }
  let request = DescribeConfigsRequest::{
    version: 1,
    resources: [resource],
    include_synonyms: false,
    include_documentation: false,
  }
  let bytes = encode_only_body(request)
  inspect(bytes, content=(
    #|b"\x00\x00\x00\x01\x02\x00\x05users\xff\xff\xff\xff\x00"
  ))
  let decoded : DescribeConfigsRequest = decode_only_body(
    bytes,
    request.version(),
    DescribeConfigsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}

///|
test "DescribeConfigsRequest v4 encode decode" {
  let resource = DescribeConfigsRequestResource::{
    version: 4,
    resource_type: 2,
    resource_name: "orders",
    configuration_keys: Some(["cleanup.policy", "compression.type"]),
  }
  let request = DescribeConfigsRequest::{
    version: 4,
    resources: [resource],
    include_synonyms: true,
    include_documentation: true,
  }
  let bytes = encode_only_body(request)
  inspect(bytes, content=(
    #|b"\x02\x02\x07orders\x03\x0fcleanup.policy\x11compression.type\x00\x01\x01\x00"
  ))
  let decoded : DescribeConfigsRequest = decode_only_body(
    bytes,
    request.version(),
    DescribeConfigsRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
}
