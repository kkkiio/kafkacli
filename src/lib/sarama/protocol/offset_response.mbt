///|
/// Response block for ListOffsets
pub struct OffsetResponseBlock {
  version : Int16
  error : KErrorCode
  offsets : Array[Int64]
  timestamp : Int64
  offset : Int64
  leader_epoch : Int
} derive(Show, ToJson)

///|
pub fn OffsetResponseBlock::new(version : Int16) -> OffsetResponseBlock {
  {
    version,
    error: 0,
    offsets: [],
    timestamp: 0L,
    offset: 0L,
    leader_epoch: -1,
  }
}

///|
/// Decode response block
pub fn OffsetResponseBlock::decode(
  pd : &PacketDecoder,
  version : Int16,
) -> OffsetResponseBlock raise PacketDecodingError {
  let error = pd.get_int16()
  if version == 0 {
    let offsets = pd.get_int64_array()
    return {
      version,
      error,
      offsets,
      timestamp: 0L,
      offset: if offsets.length() > 0 {
        offsets[0]
      } else {
        0L
      },
      leader_epoch: -1,
    }
  }
  let timestamp = pd.get_int64()
  let offset = pd.get_int64()
  let offsets = [offset]
  let leader_epoch = if version >= 4 { pd.get_int() } else { -1 }
  { version, error, offsets, timestamp, offset, leader_epoch }
}

///|
/// Encode response block based on protocol version
pub fn OffsetResponseBlock::encode(
  self : OffsetResponseBlock,
  pe : &PacketEncoder,
  version : Int16,
) -> Unit raise {
  pe.put_int16(self.error.int_value())
  if version == 0 {
    pe.put_int64_array(self.offsets)
    return
  }
  pe.put_int64(self.timestamp)
  pe.put_int64(self.offset)
  if version >= 4 {
    pe.put_int(self.leader_epoch)
  }
}

///|
/// Offset response payload
pub(all) struct OffsetResponse {
  version : Int16
  throttle_time_ms : Int
  blocks : Map[String, Map[Int, OffsetResponseBlock]]
} derive(Show, ToJson)

///|
pub fn OffsetResponse::new(version : Int16) -> OffsetResponse {
  { version, throttle_time_ms: 0, blocks: Map::new() }
}

///|
/// Decode entire response
pub fn[T : PacketDecoder] OffsetResponse::decode(
  pd : T,
  version : Int16,
) -> OffsetResponse raise PacketDecodingError {
  let throttle_time_ms = if version >= 2 { pd.get_int() } else { 0 }
  let topic_count = pd.get_array_length()
  let blocks = Map::new()
  for _ in 0..<topic_count {
    let topic = pd.get_string()
    let partition_count = pd.get_array_length()
    let partitions = Map::new()
    for _ in 0..<partition_count {
      let partition = pd.get_int()
      let block = OffsetResponseBlock::decode(pd, version)
      partitions[partition] = block
    }
    blocks[topic] = partitions
  }
  { version, throttle_time_ms, blocks }
}

///|
/// Helper to get block
pub fn OffsetResponse::get_block(
  self : OffsetResponse,
  topic : String,
  partition : Int,
) -> OffsetResponseBlock? {
  match self.blocks.get(topic) {
    Some(partitions) => partitions.get(partition)
    None => None
  }
}

///|
/// Encode offset response for transmission
pub impl KafkaEncoder for OffsetResponse with encode(self, pe) {
  if self.version < 0 || self.version > 4 {
    raise PacketEncodingError(
      "invalid or unsupported OffsetResponse version field",
    )
  }
  if self.version >= 2 {
    pe.put_int(self.throttle_time_ms)
  }
  pe.put_array_length(self.blocks.length())
  for topic, partitions in self.blocks {
    pe.put_string(topic)
    pe.put_array_length(partitions.length())
    for partition, block in partitions {
      pe.put_int(partition)
      block.encode(pe, self.version)
    }
  }
}

///|
/// Implement ProtocolBody for OffsetResponse to integrate with generic request/response handling
pub impl ProtocolBody for OffsetResponse with key(_) {
  ApiKeyListOffsets
}

///|
pub impl ProtocolBody for OffsetResponse with version(self) {
  self.version
}

///|
pub impl ProtocolBody for OffsetResponse with header_version(_) {
  // ListOffsets response 从未引入 flexible header，因此固定返回 0
  0
}

///|
pub impl ProtocolBody for OffsetResponse with is_valid_version(self) {
  self.version >= 0 && self.version <= 4
}

///|
pub impl ProtocolBody for OffsetResponse with required_version(self) {
  match self.version {
    4 => v2_1_0_0
    3 => v2_0_0_0
    2 => v0_11_0_0
    1 => v0_10_1_0
    0 => v0_8_2_0
    _ => v2_0_0_0
  }
}
