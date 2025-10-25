///|
/// ListOffsets (offset) request block
pub struct OffsetRequestBlock {
  version : Int16
  current_leader_epoch : Int
  mut timestamp : Int64
  max_num_offsets : Int
} derive(Show, ToJson)

///|
/// Create a new offset request block with defaults
pub fn OffsetRequestBlock::new(version : Int16) -> OffsetRequestBlock {
  {
    version,
    current_leader_epoch: -1,
    timestamp: -1L,
    max_num_offsets: 1,
  }
}

///|
/// Encode offset request block into packet encoder
pub fn OffsetRequestBlock::encode(
  self : OffsetRequestBlock,
  pe : &PacketEncoder,
) -> Unit {
  if self.version >= 4 {
    pe.put_int(self.current_leader_epoch)
  }
  pe.put_int64(self.timestamp)
  if self.version == 0 {
    pe.put_int(self.max_num_offsets)
  }
}

///|
/// Main ListOffsets request (OffsetRequest)
pub(all) struct OffsetRequest {
  version : Int16
  mut replica_id : Int
  mut isolation_level : IsolationLevel
  mut blocks : Map[String, Map[Int, OffsetRequestBlock]]
} derive(Show, ToJson)

///|
/// Create request with explicit version
pub fn OffsetRequest::with_version(version : Int16) -> OffsetRequest {
  {
    version,
    replica_id: -1,
    isolation_level: ReadUncommitted,
    blocks: Map::new(),
  }
}

///|
/// Set replica id (optional)
pub fn OffsetRequest::set_replica_id(
  self : OffsetRequest,
  replica_id : Int,
) -> Unit {
  self.replica_id = replica_id
}

///|
/// Set isolation level
pub fn OffsetRequest::set_isolation_level(
  self : OffsetRequest,
  level : IsolationLevel,
) -> Unit {
  self.isolation_level = level
}

///|
/// Add topic/partition block
pub fn OffsetRequest::add_block(
  self : OffsetRequest,
  topic : String,
  partition_id : Int,
  timestamp : Int64,
) -> Unit {
  if !self.blocks.contains(topic) {
    self.blocks[topic] = Map::new()
  }
  let block = OffsetRequestBlock::new(self.version)
  block.timestamp = timestamp
  self.blocks[topic][partition_id] = block
}

///|
/// Encode whole request
pub impl Encoder for OffsetRequest with encode(self, pe) {
  pe.put_int(self.replica_id)

  if self.version >= 2 {
    pe.put_bool(self.isolation_level == ReadCommitted)
  }

  pe.put_array_length(self.blocks.length())
  for topic, partitions in self.blocks {
    pe.put_string(topic)
    pe.put_array_length(partitions.length())
    for partition_id, block in partitions {
      pe.put_int(partition_id)
      block.encode(pe)
    }
  }
}

///|
/// Implement ProtocolBody for request
pub impl ProtocolBody for OffsetRequest with key(_) {
  ApiKeyListOffsets
}

///|
pub impl ProtocolBody for OffsetRequest with version(self) {
  self.version
}

///|
pub impl ProtocolBody for OffsetRequest with header_version(self) {
  1
}

///|
pub impl ProtocolBody for OffsetRequest with is_valid_version(self) {
  self.version >= 0 && self.version <= 4
}

///|
pub impl ProtocolBody for OffsetRequest with required_version(self) {
  match self.version {
    4 => v2_1_0_0
    3 => v2_0_0_0
    2 => v0_11_0_0
    1 => v0_10_1_0
    0 => v0_8_2_0
    _ => v2_0_0_0
  }
}
