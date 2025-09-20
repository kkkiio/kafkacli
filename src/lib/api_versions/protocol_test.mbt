///|
/// Unit tests for api_versions protocol encoding
pub fn hex(bs : Bytes) -> String {
  @crypto.bytes_to_hex_string(bs)
}

///|
pub fn starts_with_uvarint_zero(bs : Bytes) -> Bool {
  // check first uvarint is 0
  // uvarint 0 is single byte 0x00
  return bs.length() > 0 && bs[0].to_uint() == 0
}

///|
test "api_versions protocol encoding" {
  let req = encode_api_versions_request(1, "rdkafka", "librdkafka", "2.0.2")
  inspect(
    req,
    content=(
      #|b"\x00\x00\x00\x24\x00\x12\x00\x03\x00\x00\x00\x01\x00\x07\x72\x64\x6b\x61\x66\x6b\x61\x00\x0b\x6c\x69\x62\x72\x64\x6b\x61\x66\x6b\x61\x06\x32\x2e\x30\x2e\x32\x00"
    ),
  )
}
