///|
/// Isolation level for fetch requests
pub(all) enum IsolationLevel {
  ReadUncommitted
  ReadCommitted
} derive(Eq, Show, ToJson)

///|
/// Convert isolation level to int8
pub fn isolation_level_to_int(level : IsolationLevel) -> Int {
  match level {
    ReadUncommitted => 0
    ReadCommitted => 1
  }
}

///|
/// Convert int8 to isolation level
pub fn int_to_isolation_level(value : Int) -> IsolationLevel {
  match value {
    0 => ReadUncommitted
    1 => ReadCommitted
    _ => ReadUncommitted // default
  }
}

///|
/// Fetch request block for a specific partition
pub struct FetchRequestBlock {
  version : Int16
  current_leader_epoch : Int
  fetch_offset : Int64
  log_start_offset : Int64
  max_bytes : Int
} derive(Show, ToJson)

///|
/// Create a new fetch request block
pub fn FetchRequestBlock::new() -> FetchRequestBlock {
  {
    version: 0,
    current_leader_epoch: 0,
    fetch_offset: 0,
    log_start_offset: 0,
    max_bytes: 0,
  }
}

///|
/// Encode fetch request block to packet encoder
pub fn FetchRequestBlock::encode(
  self : FetchRequestBlock,
  pe : &PacketEncoder,
) -> Unit {
  if self.version >= 9 {
    pe.put_int32(self.current_leader_epoch)
  }
  pe.put_int64(self.fetch_offset)
  if self.version >= 5 {
    pe.put_int64(self.log_start_offset)
  }
  pe.put_int32(self.max_bytes)
}

///|
/// Decode fetch request block from packet decoder
pub fn FetchRequestBlock::decode(
  self : Self,
  pd : &PacketDecoder,
  version : Int16,
) -> Self raise PacketDecodingError {
  {
    version,
    current_leader_epoch: if version >= 9 {
      pd.get_int32()
    } else {
      0
    },
    fetch_offset: pd.get_int64(),
    log_start_offset: if version >= 5 {
      pd.get_int64()
    } else {
      0
    },
    max_bytes: pd.get_int32(),
  }
}

///|
/// Main fetch request structure
pub(all) struct FetchRequest {
  mut version : Int16
  mut max_wait_time : Int
  mut min_bytes : Int
  mut max_bytes : Int
  mut isolation_level : IsolationLevel
  mut session_id : Int
  mut session_epoch : Int
  mut blocks : Map[String, Map[Int, FetchRequestBlock]]
  mut forgotten : Map[String, Array[Int]]
  mut rack_id : String
} derive(Show, ToJson)

///|
/// Create a new fetch request with default values
pub fn FetchRequest::new() -> FetchRequest {
  {
    version: 0,
    max_wait_time: 0,
    min_bytes: 0,
    max_bytes: 0,
    isolation_level: ReadUncommitted,
    session_id: 0,
    session_epoch: 0,
    blocks: Map::new(),
    forgotten: Map::new(),
    rack_id: "",
  }
}

///|
/// Create a new fetch request with specified version
pub fn FetchRequest::with_version(version : Int16) -> FetchRequest {
  let request = FetchRequest::new()
  request.version = version
  request
}

///|
/// Add a block to the fetch request
pub fn FetchRequest::add_block(
  self : FetchRequest,
  topic : String,
  partition_id : Int,
  fetch_offset : Int64,
  max_bytes : Int,
  leader_epoch : Int,
) -> Unit {
  if self.version >= 7 && self.forgotten.is_empty() {
    self.forgotten = Map::new()
  }
  if !self.blocks.contains(topic) {
    self.blocks[topic] = Map::new()
  }
  let block = FetchRequestBlock::{
    version: self.version,
    current_leader_epoch: if self.version >= 9 {
      leader_epoch
    } else {
      0
    },
    fetch_offset,
    log_start_offset: 0,
    max_bytes,
  }
  self.blocks[topic][partition_id] = block
}

///|
/// Encode fetch request to packet encoder
pub impl Encoder for FetchRequest with encode(self, pe) {
  if self.version < 0 || self.version > 11 {
    raise PacketEncodingError(
      "invalid or unsupported FetchRequest version field",
    )
  }

  // ReplicaID is always -1 for clients
  pe.put_int32(-1)
  pe.put_int32(self.max_wait_time)
  pe.put_int32(self.min_bytes)
  if self.version >= 3 {
    pe.put_int32(self.max_bytes)
  }
  if self.version >= 4 {
    pe.put_int8(isolation_level_to_int(self.isolation_level).to_byte())
  }
  if self.version >= 7 {
    pe.put_int32(self.session_id)
    pe.put_int32(self.session_epoch)
  }

  // Encode blocks
  pe.put_array_length(self.blocks.length())
  for topic, partitions in self.blocks {
    pe.put_string(topic)
    pe.put_array_length(partitions.length())
    for partition_id, block in partitions {
      pe.put_int32(partition_id)
      block.encode(pe)
    }
  }
  if self.version >= 7 {
    // Encode forgotten partitions
    pe.put_array_length(self.forgotten.length())
    for topic, partitions in self.forgotten {
      pe.put_string(topic)
      pe.put_array_length(partitions.length())
      for partition_id in partitions {
        pe.put_int32(partition_id)
      }
    }
  }
  if self.version >= 11 {
    pe.put_string(self.rack_id)
  }
}

///|
/// Decode fetch request from packet decoder
pub impl VersionedDecoder for FetchRequest with decode(self, pd, version) raise {
  self.version = version

  // Skip replica_id (always -1 for clients)
  ignore(pd.get_int32())
  self.max_wait_time = pd.get_int32()
  self.min_bytes = pd.get_int32()
  if version >= 3 {
    self.max_bytes = pd.get_int32()
  }
  if version >= 4 {
    let isolation = pd.get_int8().to_int()
    self.isolation_level = int_to_isolation_level(isolation)
  }
  if version >= 7 {
    self.session_id = pd.get_int32()
    self.session_epoch = pd.get_int32()
  }

  // Decode blocks
  let topic_count = pd.get_array_length()
  if topic_count > 0 {
    self.blocks = Map::new()
    for _ in 0..<topic_count {
      let topic = pd.get_string()
      let partition_count = pd.get_array_length()
      let partitions = Map::new()
      for _ in 0..<partition_count {
        let partition_id = pd.get_int32()
        let block = FetchRequestBlock::new()
        let decoded_block = block.decode(pd, version)
        partitions[partition_id] = decoded_block
      }
      self.blocks[topic] = partitions
    }
  }
  if version >= 7 {
    // Decode forgotten partitions
    let forgotten_count = pd.get_array_length()
    if forgotten_count > 0 {
      self.forgotten = Map::new()
      for _ in 0..<forgotten_count {
        let topic = pd.get_string()
        let partition_count = pd.get_array_length()
        let partitions = Array::new(capacity=partition_count)
        for _ in 0..<partition_count {
          partitions.push(pd.get_int32())
        }
        self.forgotten[topic] = partitions
      }
    }
  }
  if version >= 11 {
    self.rack_id = pd.get_string()
  }
}

///|
/// Get API key for fetch request
pub impl ProtocolBody for FetchRequest with key(self) {
  ApiKeyFetch
}

///|
/// Get version of fetch request
pub impl ProtocolBody for FetchRequest with version(self) {
  self.version
}

///|
/// Set version of fetch request
pub impl ProtocolBody for FetchRequest with set_version(self, version) {
  self.version = version
}

///|
/// Get header version based on request version
pub impl ProtocolBody for FetchRequest with header_version(self) {
  1 // Fetch request always uses header version 1
}

///|
/// Check if version is valid
pub impl ProtocolBody for FetchRequest with is_valid_version(self) {
  self.version >= 0 && self.version <= 11
}

///|
/// Get required Kafka version for request version
pub impl ProtocolBody for FetchRequest with required_version(self) {
  match self.version {
    11 => v2_3_0_0
    9 | 10 => v2_1_0_0
    8 => v2_0_0_0
    7 => v1_1_0_0
    6 => v1_0_0_0
    4 | 5 => v0_11_0_0
    3 => v0_10_1_0
    2 => v0_10_0_0
    1 => v0_9_0_0
    0 => v0_8_2_0
    _ => v2_3_0_0
  }
}
