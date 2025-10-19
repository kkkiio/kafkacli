///|
test "TestApiVersionsResponse" {
  let response = ApiVersionsResponse::default()
  let apiVersionResponse : Bytes = [
    0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x03, 0x00, 0x02, 0x00, 0x01,
  ]
  versioned_decode(apiVersionResponse, response, 0)
  @json.inspect(response, content={
    "version": 0,
    "error_code": 0,
    "api_keys": [
      { "version": 0, "api_key": 3, "min_version": 2, "max_version": 1 },
    ],
    "throttle_time_ms": 0,
  })
}

///|
test "TestApiVersionsResponseV3" {
  let response = ApiVersionsResponse::default()
  response.version = 3
  let apiVersionResponseV3 : Bytes = [
    0x00, 0x00, // no error
     0x02, // compact array length 1
     0x00, 0x03, 0x00, 0x02, 0x00, 0x01, 0x00, // tagged fields
     0x00, 0x00, 0x00, 0x00, // throttle time
     0x01, 0x01, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // tagged fields (empty SupportedFeatures)
  ]
  versioned_decode(apiVersionResponseV3, response, 3)
  @json.inspect(response, content={
    "version": 3,
    "error_code": 0,
    "api_keys": [
      { "version": 3, "api_key": 3, "min_version": 2, "max_version": 1 },
    ],
    "throttle_time_ms": 0,
  })
}
