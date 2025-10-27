///|
/// Partition level data in OffsetFetch response
pub(all) struct OffsetFetchResponsePartition {
  partition_index : Int
  committed_offset : Int64
  committed_leader_epoch : Int
  metadata : String?
  error_code : Int16
} derive(Show, ToJson)

///|
/// Topic level data grouping partition offsets
pub(all) struct OffsetFetchResponseTopic {
  name : String
  partitions : Array[OffsetFetchResponsePartition]
} derive(Show, ToJson)

///|
/// OffsetFetch response supporting versions 1-7
pub(all) struct OffsetFetchResponse {
  mut version : Int16
  mut throttle_time_ms : Int
  mut topics : Array[OffsetFetchResponseTopic]
  mut error_code : Int16
} derive(Show, ToJson)

///|
/// Create response with version
pub fn OffsetFetchResponse::with_version(
  version : Int16,
) -> OffsetFetchResponse {
  {
    version,
    throttle_time_ms: 0,
    topics: [],
    error_code: ErrNoError,
  }
}

///|
/// Add topic entry into response
pub fn OffsetFetchResponse::add_topic(
  self : OffsetFetchResponse,
  topic : OffsetFetchResponseTopic,
) -> Unit {
  self.topics.push(topic)
}

///|
fn encode_offset_fetch_response_topics_v1_2(
  topics : Array[OffsetFetchResponseTopic],
  pe : &PacketEncoder,
) -> Unit raise {
  pe.put_array_length(topics.length())
  for topic in topics {
    pe.put_string(topic.name)
    pe.put_array_length(topic.partitions.length())
    for partition in topic.partitions {
      pe.put_int(partition.partition_index)
      pe.put_int64(partition.committed_offset)
      pe.put_nullable_string(partition.metadata)
      pe.put_int16(partition.error_code)
    }
  }
}

///|
fn encode_offset_fetch_response_topics_v6_7(
  topics : Array[OffsetFetchResponseTopic],
  pe : &PacketEncoder,
  version : Int16,
) -> Unit raise {
  pe.put_compact_array_length(topics.length())
  for topic in topics {
    pe.put_compact_string(topic.name)
    pe.put_compact_array_length(topic.partitions.length())
    for partition in topic.partitions {
      pe.put_int(partition.partition_index)
      pe.put_int64(partition.committed_offset)
      if version >= 5 {
        pe.put_int(partition.committed_leader_epoch)
      }
      pe.put_nullable_compact_string(partition.metadata)
      pe.put_int16(partition.error_code)
      pe.put_empty_tagged_field_array()
    }
    pe.put_empty_tagged_field_array()
  }
}

///|
fn encode_offset_fetch_response_topics_v3_5(
  topics : Array[OffsetFetchResponseTopic],
  pe : &PacketEncoder,
  version : Int16,
) -> Unit raise {
  pe.put_array_length(topics.length())
  for topic in topics {
    pe.put_string(topic.name)
    pe.put_array_length(topic.partitions.length())
    for partition in topic.partitions {
      pe.put_int(partition.partition_index)
      pe.put_int64(partition.committed_offset)
      if version >= 5 {
        pe.put_int(partition.committed_leader_epoch)
      }
      pe.put_nullable_string(partition.metadata)
      pe.put_int16(partition.error_code)
    }
  }
}

///|
pub impl KafkaEncoder for OffsetFetchResponse with encode(self, pe) {
  if self.version < 1 || self.version > 7 {
    raise PacketEncodingError(
      "invalid or unsupported OffsetFetchResponse version field",
    )
  }

  if self.version >= 3 {
    pe.put_int(self.throttle_time_ms)
  }

  if self.version >= 6 {
    encode_offset_fetch_response_topics_v6_7(self.topics, pe, self.version)
  } else if self.version >= 3 {
    encode_offset_fetch_response_topics_v3_5(self.topics, pe, self.version)
  } else {
    encode_offset_fetch_response_topics_v1_2(self.topics, pe)
  }

  if self.version >= 2 {
    pe.put_int16(self.error_code)
  }

  if self.version >= 6 {
    pe.put_empty_tagged_field_array()
  }
}

///|
fn[T : PacketDecoder] decode_offset_fetch_response_topics_v1_2(
  pd : T,
) -> Array[OffsetFetchResponseTopic] raise PacketDecodingError {
  let topics_len = pd.get_array_length()
  let topics = Array::new()
  if topics_len > 0 {
    topics.reserve_capacity(topics_len)
  }
  for _ in 0..<topics_len {
    let name = pd.get_string()
    let partitions_len = pd.get_array_length()
    let partitions = Array::new()
    if partitions_len > 0 {
      partitions.reserve_capacity(partitions_len)
    }
    for _ in 0..<partitions_len {
      let partition_index = pd.get_int()
      let committed_offset = pd.get_int64()
      let metadata = pd.get_nullable_string()
      let error_code = pd.get_int16()
      partitions.push({
        partition_index,
        committed_offset,
        committed_leader_epoch: -1,
        metadata,
        error_code,
      })
    }
    topics.push({ name, partitions })
  }
  topics
}

///|
fn[T : PacketDecoder] decode_offset_fetch_response_topics_v3_5(
  pd : T,
  version : Int16,
) -> Array[OffsetFetchResponseTopic] raise PacketDecodingError {
  let topics_len = pd.get_array_length()
  let topics = Array::new()
  if topics_len > 0 {
    topics.reserve_capacity(topics_len)
  }
  for _ in 0..<topics_len {
    let name = pd.get_string()
    let partitions_len = pd.get_array_length()
    let partitions = Array::new()
    if partitions_len > 0 {
      partitions.reserve_capacity(partitions_len)
    }
    for _ in 0..<partitions_len {
      let partition_index = pd.get_int()
      let committed_offset = pd.get_int64()
      let committed_leader_epoch = if version >= 5 { pd.get_int() } else { -1 }
      let metadata = pd.get_nullable_string()
      let error_code = pd.get_int16()
      partitions.push({
        partition_index,
        committed_offset,
        committed_leader_epoch,
        metadata,
        error_code,
      })
    }
    topics.push({ name, partitions })
  }
  topics
}

///|
fn[T : PacketDecoder] decode_offset_fetch_response_topics_v6_7(
  pd : T,
  version : Int16,
) -> Array[OffsetFetchResponseTopic] raise PacketDecodingError {
  let topics_len = pd.get_compact_array_length()
  let topics = Array::new()
  if topics_len > 0 {
    topics.reserve_capacity(topics_len)
  }
  for _ in 0..<topics_len {
    let name = pd.get_compact_string()
    let partitions_len = pd.get_compact_array_length()
    let partitions = Array::new()
    if partitions_len > 0 {
      partitions.reserve_capacity(partitions_len)
    }
    for _ in 0..<partitions_len {
      let partition_index = pd.get_int()
      let committed_offset = pd.get_int64()
      let committed_leader_epoch = if version >= 5 { pd.get_int() } else { -1 }
      let metadata = pd.get_compact_nullable_string()
      let error_code = pd.get_int16()
      partitions.push({
        partition_index,
        committed_offset,
        committed_leader_epoch,
        metadata,
        error_code,
      })
      ignore(pd.get_empty_tagged_field_array())
    }
    topics.push({ name, partitions })
    ignore(pd.get_empty_tagged_field_array())
  }
  topics
}

///|
pub fn[T : PacketDecoder] OffsetFetchResponse::decode(
  pd : T,
  version : Int16,
) -> OffsetFetchResponse raise PacketDecodingError {
  let throttle_time_ms = if version >= 3 { pd.get_int() } else { 0 }
  let topics = if version >= 6 {
    decode_offset_fetch_response_topics_v6_7(pd, version)
  } else if version >= 3 {
    decode_offset_fetch_response_topics_v3_5(pd, version)
  } else {
    decode_offset_fetch_response_topics_v1_2(pd)
  }
  let error_code = if version >= 2 { pd.get_int16() } else { ErrNoError }
  if version >= 6 {
    ignore(pd.get_empty_tagged_field_array())
  }
  { version, throttle_time_ms, topics, error_code }
}

///|
pub impl ProtocolBody for OffsetFetchResponse with key(_) {
  ApiKeyOffsetFetch
}

///|
pub impl ProtocolBody for OffsetFetchResponse with version(self) {
  self.version
}

///|
pub fn OffsetFetchResponse::header_version(version : Int16) -> Int16 {
  if version >= 6 {
    1
  } else {
    0
  }
}

///|
pub impl ProtocolBody for OffsetFetchResponse with header_version(self) {
  OffsetFetchResponse::header_version(self.version)
}

///|
pub impl ProtocolBody for OffsetFetchResponse with is_valid_version(self) {
  self.version >= 1 && self.version <= 7
}

///|
pub impl ProtocolBody for OffsetFetchResponse with required_version(self) {
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
