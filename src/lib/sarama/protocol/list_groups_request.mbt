///|
/// ListGroups request structure for listing consumer groups from Kafka cluster
pub(all) struct ListGroupsRequest {
  mut version : Int16
  mut states_filter : Array[String]
  mut types_filter : Array[String]
} derive(Show, ToJson)

///|
/// Create a new list groups request with default version 0
pub fn ListGroupsRequest::new() -> ListGroupsRequest {
  { version: 0, states_filter: [], types_filter: [] }
}

///|
/// Create a new list groups request with specified version
pub fn ListGroupsRequest::with_version(version : Int16) -> ListGroupsRequest {
  let request = ListGroupsRequest::new()
  request.version = version
  request
}

///|
/// Default implementation returns version 0 request with empty filters
pub impl Default for ListGroupsRequest with default() {
  ListGroupsRequest::new()
}

///|
/// Encode list groups request to packet encoder
pub impl Encoder for ListGroupsRequest with encode(self, pe) {
  if self.version < 0 || self.version > 5 {
    raise PacketEncodingError(
      "invalid or unsupported ListGroupsRequest version field",
    )
  }

  // Encode states filter for versions 4+
  if self.version >= 4 {
    pe.put_compact_array_length(self.states_filter.length())
    for filter in self.states_filter {
      pe.put_compact_string(filter)
    }
  }

  // Encode types filter for versions 5+
  if self.version >= 5 {
    pe.put_compact_array_length(self.types_filter.length())
    for filter in self.types_filter {
      pe.put_compact_string(filter)
    }
  }

  // Add tagged fields for versions 3+
  if self.version >= 3 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode list groups request from packet decoder
pub fn[T : PacketDecoder] ListGroupsRequest::decode(
  pd : T,
  version : Int16,
) -> ListGroupsRequest raise PacketDecodingError {
  // Decode states filter for versions 4+
  let states_filter = Array::new()
  if version >= 4 {
    let filter_len = pd.get_compact_array_length()
    if filter_len > 0 {
      states_filter.reserve_capacity(filter_len)
      for _ in 0..<filter_len {
        let filter = pd.get_compact_string()
        states_filter.push(filter)
      }
    }
  }

  // Decode types filter for versions 5+
  let types_filter = Array::new()
  if version >= 5 {
    let filter_len = pd.get_compact_array_length()
    if filter_len > 0 {
      types_filter.reserve_capacity(filter_len)
      for _ in 0..<filter_len {
        let filter = pd.get_compact_string()
        types_filter.push(filter)
      }
    }
  }

  // Skip tagged fields for versions 3+
  if version >= 3 {
    ignore(pd.get_empty_tagged_field_array())
  }
  { version, states_filter, types_filter }
}

///|
/// Get API key for list groups request
pub impl ProtocolBody for ListGroupsRequest with key(_) {
  ApiKeyListGroups
}

///|
/// Get version of list groups request
pub impl ProtocolBody for ListGroupsRequest with version(self) {
  self.version
}

///|
/// Get header version based on request version
pub fn ListGroupsRequest::header_version(version : Int16) -> Int16 {
  if version >= 3 {
    2
  } else {
    1
  }
}

///|
/// Get header version based on request version
pub impl ProtocolBody for ListGroupsRequest with header_version(self) {
  ListGroupsRequest::header_version(self.version)
}

///|
/// Check if version is valid
pub impl ProtocolBody for ListGroupsRequest with is_valid_version(self) {
  self.version >= 0 && self.version <= 5
}

///|
/// Get required Kafka version for request version
pub impl ProtocolBody for ListGroupsRequest with required_version(self) {
  match self.version {
    5 => v3_8_0_0
    4 => v2_6_0_0
    3 => v2_4_0_0
    2 => v2_0_0_0
    1 => v0_11_0_0
    0 => v0_9_0_0
    _ => v2_6_0_0
  }
}
