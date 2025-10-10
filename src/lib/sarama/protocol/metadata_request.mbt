///|
/// UUID type for metadata requests (16 bytes)
pub typealias FixedArray[Byte] as Uuid

///|
/// Null UUID constant for metadata requests
pub let null_uuid : Uuid = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

///|
/// Metadata request structure for fetching topic metadata from Kafka cluster
pub(all) struct MetadataRequest {
  mut version : Int16
  mut topics : Array[String]
  mut allow_auto_topic_creation : Bool
  mut include_cluster_authorized_operations : Bool
  mut include_topic_authorized_operations : Bool
} derive(Show, ToJson)

///|
/// Create a new metadata request with appropriate version based on Kafka version
pub fn MetadataRequest::new(
  version : KafkaVersion,
  topics : Array[String],
) -> MetadataRequest {
  let mut request_version = 0
  if version.is_at_least(v2_8_0_0) {
    request_version = 10
  } else if version.is_at_least(v2_4_0_0) {
    request_version = 9
  } else if version.is_at_least(v2_3_0_0) {
    request_version = 8
  } else if version.is_at_least(v2_1_0_0) {
    request_version = 7
  } else if version.is_at_least(v2_0_0_0) {
    request_version = 6
  } else if version.is_at_least(v1_0_0_0) {
    request_version = 5
  } else if version.is_at_least(v0_11_0_0) {
    request_version = 4
  } else if version.is_at_least(v0_10_1_0) {
    request_version = 2
  } else if version.is_at_least(v0_10_0_0) {
    request_version = 1
  }
  {
    version: request_version.to_int16(),
    topics,
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
}

///|
/// Encode metadata request to packet encoder
pub impl Encoder for MetadataRequest with encode(self, pe) {
  if self.version < 0 || self.version > 10 {
    raise PacketEncodingError(
      "invalid or unsupported MetadataRequest version field",
    )
  }

  // Handle topics array encoding based on version
  if self.version == 0 || self.topics.length() > 0 {
    if self.version < 9 {
      // Versions 0-8: use regular array encoding
      pe.put_array_length(self.topics.length())
      for topic in self.topics {
        pe.put_string(topic)
      }
    } else if self.version == 9 {
      // Version 9: use compact array with empty tagged fields
      pe.put_compact_array_length(self.topics.length())
      for topic_name in self.topics {
        pe.put_compact_string(topic_name)
        pe.put_empty_tagged_field_array()
      }
    } else {
      // Version 10: use compact array with UUID and nullable topic name
      pe.put_compact_array_length(self.topics.length())
      for topic_name in self.topics {
        pe.put_raw_bytes(null_uuid |> Bytes::from_fixedarray)
        pe.put_nullable_compact_string(Some(topic_name))
        pe.put_empty_tagged_field_array()
      }
    }
    // No topics requested - encode null array
  } else if self.version < 9 {
    pe.put_int32(-1)
  } else {
    pe.put_compact_array_length(-1)
  }

  // Encode allow_auto_topic_creation for versions 4+
  if self.version > 3 {
    pe.put_bool(self.allow_auto_topic_creation)
  }

  // Encode authorization flags for versions 8+
  if self.version > 7 {
    pe.put_bool(self.include_cluster_authorized_operations)
    pe.put_bool(self.include_topic_authorized_operations)
  }

  // Add tagged fields for versions 9+
  if self.version > 8 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode metadata request from packet decoder
pub impl VersionedDecoder for MetadataRequest with decode(self, pd, version) {
  self.version = version

  // Decode topics array based on version
  if self.version < 9 {
    // Versions 0-8: regular array decoding
    let size = pd.get_int32()
    if size > 0 {
      self.topics = Array::new(capacity=size)
      for _ in 0..<size {
        let topic = pd.get_string()
        self.topics.push(topic)
      }
    }
  } else if self.version == 9 {
    // Version 9: compact array with tagged fields
    let size = pd.get_compact_array_length()
    if size > 0 {
      self.topics = Array::new(capacity=size)
    }
    for _ in 0..<size {
      let topic = pd.get_compact_string()
      self.topics.push(topic)
      ignore(pd.get_empty_tagged_field_array())
    }
  } else {
    // Version 10+: compact array with UUID and nullable topic name
    let size = pd.get_compact_array_length()
    if size > 0 {
      self.topics = Array::new(capacity=size)
    }
    for _ in 0..<size {
      ignore(pd.get_raw_bytes(16)) // skip UUID
      let topic = pd.get_compact_nullable_string()
      match topic {
        Some(t) => self.topics.push(t)
        None => () // handle null topic name
      }
      ignore(pd.get_empty_tagged_field_array())
    }
  }

  // Decode allow_auto_topic_creation for versions 4+
  if self.version >= 4 {
    self.allow_auto_topic_creation = pd.get_bool()
  }

  // Decode authorization flags for versions 8+
  if self.version > 7 {
    self.include_cluster_authorized_operations = pd.get_bool()
    self.include_topic_authorized_operations = pd.get_bool()
  }

  // Skip tagged fields for versions 9+
  if self.version > 8 {
    ignore(pd.get_empty_tagged_field_array())
  }
}

///|
/// Get API key for metadata request
pub impl ProtocolBody for MetadataRequest with key(self) {
  ApiKeyMetadata
}

///|
/// Get version of metadata request
pub impl ProtocolBody for MetadataRequest with version(self) {
  self.version
}

///|
/// Set version of metadata request
pub impl ProtocolBody for MetadataRequest with set_version(self, version) {
  self.version = version
}

///|
/// Get header version based on request version
pub impl ProtocolBody for MetadataRequest with header_version(self) {
  if self.version >= 9 {
    2
  } else {
    1
  }
}

///|
/// Check if version is valid
pub impl ProtocolBody for MetadataRequest with is_valid_version(self) {
  self.version >= 0 && self.version <= 10
}

///|
/// Get required Kafka version for request version
pub impl ProtocolBody for MetadataRequest with required_version(self) {
  match self.version {
    10 => v2_8_0_0
    9 => v2_4_0_0
    8 => v2_3_0_0
    7 => v2_1_0_0
    6 => v2_0_0_0
    5 => v1_0_0_0
    3 | 4 => v0_11_0_0
    2 => v0_10_1_0
    1 => v0_10_0_0
    0 => v0_8_2_0
    _ => v2_8_0_0
  }
}
