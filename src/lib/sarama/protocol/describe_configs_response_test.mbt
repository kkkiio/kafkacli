///|
fn[T : KafkaEncoder] encode_response_body(body : T) -> Bytes raise {
  let buf = Array::make(1024, Byte::default())
  let pe = RealEncoder::new(buf)
  body.encode(pe)
  buf[:pe.offset()].to_array() |> Bytes::from_array
}

///|
test "DescribeConfigsResponse v1 encode decode" {
  let config = DescribeConfigsConfig::{
    version: 1,
    name: "cleanup.policy",
    value: Some("delete"),
    read_only: false,
    config_source: 4,
    is_sensitive: false,
    synonyms: [],
    config_type: 0,
    documentation: None,
  }
  let resource = DescribeConfigsResource::{
    version: 1,
    error_code: 0,
    error_message: None,
    resource_type: 2,
    resource_name: "users",
    configs: [config],
  }
  let response = DescribeConfigsResponse::{
    version: 1,
    throttle_time_ms: 0,
    resources: [resource],
  }
  let bytes = encode_response_body(response)
  inspect(bytes, content=(
    #|b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\xff\xff\x02\x00\x05users\x00\x00\x00\x01\x00\x0ecleanup.policy\x00\x06delete\x00\x04\x00\x00\x00\x00\x00"
  ))
  let decoded : DescribeConfigsResponse = decode_only_body(
    bytes,
    response.version,
    DescribeConfigsResponse::decode,
  )
  assert_eq(response.to_json(), decoded.to_json())
}

///|
test "DescribeConfigsResponse v4 encode decode" {
  let synonym = DescribeConfigsSynonym::{
    version: 4,
    name: "retention.ms",
    value: Some("86400000"),
    source: 5,
  }
  let config = DescribeConfigsConfig::{
    version: 4,
    name: "retention.ms",
    value: Some("86400000"),
    read_only: false,
    config_source: 5,
    is_sensitive: false,
    synonyms: [synonym],
    config_type: 1,
    documentation: Some("Retention time in milliseconds"),
  }
  let resource = DescribeConfigsResource::{
    version: 4,
    error_code: 0,
    error_message: None,
    resource_type: 2,
    resource_name: "events",
    configs: [config],
  }
  let response = DescribeConfigsResponse::{
    version: 4,
   throttle_time_ms: 10,
   resources: [resource],
  }
  let bytes = encode_response_body(response)
  inspect(bytes, content=(
    #|b"\x00\x00\x00\x0a\x02\x00\x00\x00\x02\x07events\x02\x0dretention.ms\x0986400000\x00\x05\x00\x02\x0dretention.ms\x0986400000\x05\x00\x01\x1fRetention time in milliseconds\x00\x00\x00"
  ))
  let decoded : DescribeConfigsResponse = decode_only_body(
    bytes,
    response.version,
    DescribeConfigsResponse::decode,
  )
  assert_eq(response.to_json(), decoded.to_json())
}
