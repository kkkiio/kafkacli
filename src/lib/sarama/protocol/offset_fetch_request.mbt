///|
/// OffsetFetch request topic info with partition indexes
pub(all) struct OffsetFetchRequestTopic {
  name : String
  partition_indexes : Array[Int]
} derive(Show, ToJson)

///|
/// Kafka OffsetFetch request structure (versions 1-7 supported)
pub(all) struct OffsetFetchRequest {
  mut version : Int16
  group_id : String
  mut topics : Array[OffsetFetchRequestTopic]?
  mut require_stable : Bool
} derive(Show, ToJson)

///|
/// Construct a request with explicit version and group id
pub fn OffsetFetchRequest::new(
  version : Int16,
  group_id : String,
) -> OffsetFetchRequest {
  { version, group_id, topics: None, require_stable: false }
}

///|
/// Convenience constructor using default version 7 (Kafka 2.3+)
pub fn OffsetFetchRequest::default(group_id : String) -> OffsetFetchRequest {
  OffsetFetchRequest::new(7, group_id)
}

///|
/// Set topic/partition filters for the request (`None` fetches all topics)
pub fn OffsetFetchRequest::set_topics(
  self : OffsetFetchRequest,
  topics : Array[OffsetFetchRequestTopic]?,
) -> Unit {
  self.topics = topics
}

///|
/// Set require_stable flag (available since version 7)
pub fn OffsetFetchRequest::set_require_stable(
  self : OffsetFetchRequest,
  require_stable : Bool,
) -> Unit {
  self.require_stable = require_stable
}

///|
fn encode_offset_fetch_request_topics_v1_5(
  topics : Array[OffsetFetchRequestTopic]?,
  pe : &PacketEncoder,
) -> Unit raise {
  match topics {
    None => pe.put_array_length(-1)
    Some(items) => {
      pe.put_array_length(items.length())
      for topic in items {
        pe.put_string(topic.name)
        pe.put_array_length(topic.partition_indexes.length())
        for partition in topic.partition_indexes {
          pe.put_int(partition)
        }
      }
    }
  }
}

///|
fn encode_offset_fetch_request_topics_v6_7(
  topics : Array[OffsetFetchRequestTopic]?,
  pe : &PacketEncoder,
) -> Unit raise {
  match topics {
    None => pe.put_compact_array_length(-1)
    Some(items) => {
      pe.put_compact_array_length(items.length())
      for topic in items {
        pe.put_compact_string(topic.name)
        pe.put_compact_array_length(topic.partition_indexes.length())
        for partition in topic.partition_indexes {
          pe.put_int(partition)
        }
        pe.put_empty_tagged_field_array()
      }
    }
  }
}

///|
/// Encode OffsetFetch request into Kafka packet encoder
pub impl KafkaEncoder for OffsetFetchRequest with encode(self, pe) {
  if self.version < 1 || self.version > 7 {
    raise PacketEncodingError(
      "invalid or unsupported OffsetFetchRequest version field",
    )
  }
  if self.version >= 6 {
    pe.put_compact_string(self.group_id)
    encode_offset_fetch_request_topics_v6_7(self.topics, pe)
    if self.version >= 7 {
      pe.put_bool(self.require_stable)
    }
    pe.put_empty_tagged_field_array()
  } else {
    pe.put_string(self.group_id)
    encode_offset_fetch_request_topics_v1_5(self.topics, pe)
    if self.version >= 2 && self.topics is None {
      // Versions 2-5 allow null topics to fetch all offsets; nothing extra to encode.
      ()
    }
  }
}

///|
fn[T : PacketDecoder] decode_offset_fetch_request_topics_v1_5(
  pd : T,
) -> Array[OffsetFetchRequestTopic]? raise PacketDecodingError {
  let length = pd.get_array_length()
  if length < 0 {
    return None
  }
  let topics = Array::new()
  if length > 0 {
    topics.reserve_capacity(length)
    for _ in 0..<length {
      let name = pd.get_string()
      let partitions_len = pd.get_array_length()
      let partition_indexes = Array::new()
      if partitions_len > 0 {
        partition_indexes.reserve_capacity(partitions_len)
        for _ in 0..<partitions_len {
          partition_indexes.push(pd.get_int())
        }
      }
      topics.push({ name, partition_indexes })
    }
  }
  Some(topics)
}

///|
fn[T : PacketDecoder] decode_offset_fetch_request_topics_v6_7(
  pd : T,
) -> Array[OffsetFetchRequestTopic]? raise PacketDecodingError {
  let length = pd.get_compact_array_length()
  if length == 0 {
    return None
  }
  let topics = Array::new()
  topics.reserve_capacity(length)
  for _ in 0..<length {
    let name = pd.get_compact_string()
    let partitions_len = pd.get_compact_array_length()
    let partition_indexes = Array::new()
    if partitions_len > 0 {
      partition_indexes.reserve_capacity(partitions_len)
      for _ in 0..<partitions_len {
        partition_indexes.push(pd.get_int())
      }
    }
    topics.push({ name, partition_indexes })
    ignore(pd.get_empty_tagged_field_array())
  }
  Some(topics)
}

///|
/// Decode OffsetFetch request for testing scenarios
pub fn[T : PacketDecoder] OffsetFetchRequest::decode(
  pd : T,
  version : Int16,
) -> OffsetFetchRequest raise PacketDecodingError {
  let group_id = if version >= 6 {
    pd.get_compact_string()
  } else {
    pd.get_string()
  }
  let topics = if version >= 6 {
    decode_offset_fetch_request_topics_v6_7(pd)
  } else {
    decode_offset_fetch_request_topics_v1_5(pd)
  }
  let require_stable = if version >= 7 { pd.get_bool() } else { false }
  if version >= 6 {
    ignore(pd.get_empty_tagged_field_array())
  }
  { version, group_id, topics, require_stable }
}

///|
pub impl ProtocolBody for OffsetFetchRequest with key(_) {
  ApiKeyOffsetFetch
}

///|
pub impl ProtocolBody for OffsetFetchRequest with version(self) {
  self.version
}

///|
pub fn OffsetFetchRequest::header_version(version : Int16) -> Int16 {
  if version >= 6 {
    2
  } else {
    1
  }
}

///|
pub impl ProtocolBody for OffsetFetchRequest with header_version(self) {
  OffsetFetchRequest::header_version(self.version)
}

///|
pub impl ProtocolBody for OffsetFetchRequest with is_valid_version(self) {
  self.version >= 1 && self.version <= 7
}

///|
pub impl ProtocolBody for OffsetFetchRequest with required_version(self) {
  match self.version {
    7 => v2_3_0_0
    6 => v2_1_0_0
    5 => v0_11_0_0
    4 => v0_10_2_0
    3 => v0_10_1_0
    2 => v0_9_0_0
    1 => v0_8_2_0
    _ => v2_3_0_0
  }
}
