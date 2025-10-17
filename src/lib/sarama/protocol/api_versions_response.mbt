///|
/// ApiVersionsResponseKey contains the APIs supported by the broker.
pub(all) struct ApiVersionsResponseKey {
  /// Version defines the protocol version to use for encode and decode
  mut version : Int16
  /// ApiKey contains the API index.
  mut api_key : Int16
  /// MinVersion contains the minimum supported version, inclusive.
  mut min_version : Int16
  /// MaxVersion contains the maximum supported version, inclusive.
  mut max_version : Int16
} derive(Show, ToJson, Default)

///|
pub fn[E : PacketEncoder] ApiVersionsResponseKey::encode(
  self : ApiVersionsResponseKey,
  pe : E,
  version : Int16,
) -> Unit {
  self.version = version
  pe.put_int16(self.api_key)
  pe.put_int16(self.min_version)
  pe.put_int16(self.max_version)
  if version >= 3 {
    pe.put_empty_tagged_field_array()
  }
}

///|
pub impl VersionedDecoder for ApiVersionsResponseKey with decode(
  self,
  pd,
  version,
) {
  self.version = version
  self.api_key = pd.get_int16()
  self.min_version = pd.get_int16()
  self.max_version = pd.get_int16()
  if version >= 3 {
    pd.get_empty_tagged_field_array() |> ignore
  }
}

///|
pub(all) struct ApiVersionsResponse {
  /// Version defines the protocol version to use for encode and decode
  mut version : Int16
  /// ErrorCode contains the top-level error code.
  mut error_code : Int16
  // ApiKeys contains the APIs supported by the broker.
  mut api_keys : Array[ApiVersionsResponseKey]
  /// ThrottleTimeMs contains the duration in milliseconds for which the request was throttled due to a quota violation, or zero if the request did not violate any quota.
  mut throttle_time_ms : Int
} derive(Show, Default, ToJson)

///|
pub impl ProtocolBody for ApiVersionsResponse with set_version(self, version) {
  self.version = version
}

///|
pub impl Encoder for ApiVersionsResponse with encode(self, pe) {
  pe.put_int16(self.error_code)
  if self.version >= 3 {
    pe.put_compact_array_length(self.api_keys.length())
  } else {
    pe.put_array_length(self.api_keys.length())
  }
  for _, block in self.api_keys {
    block.encode(pe, self.version)
  }
  if self.version >= 1 {
    pe.put_int(self.throttle_time_ms)
  }
  if self.version >= 3 {
    pe.put_empty_tagged_field_array()
  }
}

///|
pub impl VersionedDecoder for ApiVersionsResponse with decode(self, pd, version) {
  self.version = version
  self.error_code = pd.get_int16()
  let numApiKeys = if self.version >= 3 {
    pd.get_compact_array_length()
  } else {
    pd.get_array_length()
  }
  self.api_keys = Array::new(capacity=numApiKeys)
  for i in 0..<numApiKeys {
    let block = ApiVersionsResponseKey::default()
    block.decode(pd, self.version)
    self.api_keys.push(block)
  }
  if self.version >= 1 {
    self.throttle_time_ms = pd.get_int()
  }
  if self.version >= 3 {
    pd.get_empty_tagged_field_array() |> ignore
  }
}

///|
pub impl ProtocolBody for ApiVersionsResponse with key(self) {
  return ApiKeyApiVersions
}

///|
pub impl ProtocolBody for ApiVersionsResponse with version(self) {
  return self.version
}

///|
pub impl EncoderWithHeader for ApiVersionsResponse with header_version(self) {
  // ApiVersionsResponse always includes a v0 header.
  // See KIP-511 for details
  return 0
}

///|
pub impl ProtocolBody for ApiVersionsResponse with is_valid_version(self) {
  return self.version >= 0 && self.version <= 3
}

///|
pub impl ProtocolBody for ApiVersionsResponse with required_version(self) {
  match self.version {
    3 => v2_4_0_0
    2 => v2_0_0_0
    1 => v0_11_0_0
    0 => v0_10_0_0
    _ => v2_4_0_0
  }
}

///|
pub fn ApiVersionsResponse::throttle_time(
  self : ApiVersionsResponse,
) -> Milliseconds {
  self.throttle_time_ms.to_int64()
}
