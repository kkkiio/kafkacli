///|
/// Group data structure for extended group information in ListGroups response
pub(all) struct ListGroupsGroupData {
  mut group_state : String
  mut group_type : String
} derive(Show, ToJson)

///|
/// Create a new group data with default values
pub fn ListGroupsGroupData::new() -> ListGroupsGroupData {
  { group_state: "", group_type: "" }
}

///|
/// ListGroups response structure for listing consumer groups from Kafka cluster
pub(all) struct ListGroupsResponse {
  mut version : Int16
  mut throttle_time_ms : Int
  mut error : Int16
  mut groups : Map[String, String]
  mut groups_data : Map[String, ListGroupsGroupData]
} derive(Show, ToJson)

///|
/// Create a new list groups response with default values
pub fn ListGroupsResponse::new() -> ListGroupsResponse {
  {
    version: 0,
    throttle_time_ms: 0,
    error: ErrNoError,
    groups: Map::new(),
    groups_data: Map::new(),
  }
}

///|
/// Create a new list groups response with specified version
pub fn ListGroupsResponse::with_version(version : Int16) -> ListGroupsResponse {
  let response = ListGroupsResponse::new()
  response.version = version
  response
}

///|
/// Add a group to the response
pub fn ListGroupsResponse::add_group(
  self : ListGroupsResponse,
  group_id : String,
  protocol_type : String,
) -> Unit {
  self.groups[group_id] = protocol_type
}

///|
/// Add a group with extended data to the response
pub fn ListGroupsResponse::add_group_with_data(
  self : ListGroupsResponse,
  group_id : String,
  protocol_type : String,
  group_data : ListGroupsGroupData,
) -> Unit {
  self.groups[group_id] = protocol_type
  self.groups_data[group_id] = group_data
}

///|
/// Encode list groups response to packet encoder
pub impl Encoder for ListGroupsResponse with encode(self, pe) {
  if self.version < 0 || self.version > 5 {
    raise PacketEncodingError(
      "invalid or unsupported ListGroupsResponse version field",
    )
  }

  // Encode throttle time for versions 1+
  if self.version >= 1 {
    pe.put_int(self.throttle_time_ms)
  }

  // Encode error code
  pe.put_int16(self.error)

  // Encode groups
  if self.version <= 2 {
    // Versions 0-2: use regular array encoding
    pe.put_array_length(self.groups.length())
    for group_id, protocol_type in self.groups {
      pe.put_string(group_id)
      pe.put_string(protocol_type)
    }
  } else {
    // Versions 3+: use compact array encoding
    pe.put_compact_array_length(self.groups.length())
    for group_id, protocol_type in self.groups {
      pe.put_compact_string(group_id)
      pe.put_compact_string(protocol_type)

      // Encode group state for versions 4+
      if self.version >= 4 {
        let group_data = self.groups_data
          .get(group_id)
          .unwrap_or(ListGroupsGroupData::new())
        pe.put_compact_string(group_data.group_state)
      }

      // Encode group type for versions 5+
      if self.version >= 5 {
        let group_data = self.groups_data
          .get(group_id)
          .unwrap_or(ListGroupsGroupData::new())
        pe.put_compact_string(group_data.group_type)
      }

      // Add tagged fields for each group in versions 3+
      pe.put_empty_tagged_field_array()
    }
  }

  // Add top-level tagged fields for versions 3+
  if self.version >= 3 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode list groups response from packet decoder
pub fn[T : PacketDecoder] ListGroupsResponse::decode(
  pd : T,
  version : Int16,
) -> ListGroupsResponse raise PacketDecodingError {

  // Decode throttle time for versions 1+
  let throttle_time_ms = if version >= 1 { pd.get_int() } else { 0 }

  // Decode error code
  let error = pd.get_int16()

  // Decode groups
  let group_count = if version <= 2 {
    pd.get_array_length()
  } else {
    pd.get_compact_array_length()
  }
  let groups = Map::new()
  let groups_data = Map::new()
  if group_count > 0 {
    for _ in 0..<group_count {
      let (group_id, protocol_type) = if version <= 2 {
        let group_id = pd.get_string()
        let protocol_type = pd.get_string()
        (group_id, protocol_type)
      } else {
        let group_id = pd.get_compact_string()
        let protocol_type = pd.get_compact_string()
        (group_id, protocol_type)
      }
      groups[group_id] = protocol_type

      // Decode extended data for versions 4+
      if version >= 4 {
        let group_state = pd.get_compact_string()
        let group_type = if version >= 5 { pd.get_compact_string() } else { "" }
        let group_data = { group_state, group_type }
        groups_data[group_id] = group_data
      }

      // Skip tagged fields for each group in versions 3+
      if version >= 3 {
        ignore(pd.get_empty_tagged_field_array())
      }
    }
  }

  // Skip top-level tagged fields for versions 3+
  if version >= 3 {
    ignore(pd.get_empty_tagged_field_array())
  }
  { version, throttle_time_ms, error, groups, groups_data }
}

///|
/// Get API key for list groups response
pub impl ProtocolBody for ListGroupsResponse with key(_) {
  ApiKeyListGroups
}

///|
/// Get version of list groups response
pub impl ProtocolBody for ListGroupsResponse with version(self) {
  self.version
}

///|
pub fn ListGroupsResponse::header_version(version : Int16) -> Int16 {
  if version >= 3 {
    1
  } else {
    0
  }
}

///|
/// Get header version based on response version
pub impl ProtocolBody for ListGroupsResponse with header_version(self) {
  ListGroupsResponse::header_version(self.version)
}

///|
/// Check if version is valid
pub impl ProtocolBody for ListGroupsResponse with is_valid_version(self) {
  self.version >= 0 && self.version <= 5
}

///|
/// Get required Kafka version for response version
pub impl ProtocolBody for ListGroupsResponse with required_version(self) {
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
