///|
let apiVersionResponse : Bytes = [
  0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x03, 0x00, 0x02, 0x00, 0x01,
]

///|
let apiVersionResponseV3 : Bytes = [
  0x00, 0x00, // no error
   0x02, // compact array length 1
   0x00, 0x03, 0x00, 0x02, 0x00, 0x01, 0x00, // tagged fields
   0x00, 0x00, 0x00, 0x00, // throttle time
   0x01, 0x01, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // tagged fields (empty SupportedFeatures)
]

///|
test "TestApiVersionsResponse" {
  let response = ApiVersionsResponse::default()
  versioned_decode(apiVersionResponse, response, 0)
  assert_eq(response.error_code, ErrNoError)
  assert_eq(response.api_keys[0].api_key, 0x03)
  assert_eq(response.api_keys[0].min_version, 0x02)
  assert_eq(response.api_keys[0].max_version, 0x01)
}

///|
test "TestApiVersionsResponseV3" {
  let response = ApiVersionsResponse::default()
  response.version = 3
  versioned_decode(apiVersionResponseV3, response, 3)
  assert_eq(response.error_code, ErrNoError)
  assert_eq(response.api_keys[0].api_key, 0x03)
  assert_eq(response.api_keys[0].min_version, 0x02)
  assert_eq(response.api_keys[0].max_version, 0x01)
}
