///|
/// Aborted transaction structure
pub struct AbortedTransaction {
  producer_id : Int64
  first_offset : Int64
} derive(Show, ToJson, Eq)

///|
/// Encode aborted transaction to packet encoder
pub fn AbortedTransaction::encode(self : AbortedTransaction, pe : &PacketEncoder) -> Unit {
  pe.put_int64(self.producer_id)
  pe.put_int64(self.first_offset)
}

///|
/// Decode aborted transaction from packet decoder
pub fn AbortedTransaction::decode(pd : &PacketDecoder) -> AbortedTransaction raise PacketDecodingError {
  let producer_id = pd.get_int64()
  let first_offset = pd.get_int64()
  { producer_id, first_offset }
}

///|
/// Fetch response block for a specific partition
pub(all) struct FetchResponseBlock {
  version : Int16
  error : Int16
  high_watermark_offset : Int64
  last_stable_offset : Int64
  log_start_offset : Int64
  aborted_transactions : Array[AbortedTransaction]
  preferred_read_replica : Int
  records : Bytes
} derive(Show, ToJson)

///|
/// Create a new fetch response block
pub fn FetchResponseBlock::new() -> FetchResponseBlock {
  {
    version: 0,
    error: 0,
    high_watermark_offset: 0,
    last_stable_offset: 0,
    log_start_offset: 0,
    aborted_transactions: [],
    preferred_read_replica: -1,
    records: [],
  }
}

///|
/// Encode fetch response block to packet encoder
pub fn FetchResponseBlock::encode(self : FetchResponseBlock, pe : &PacketEncoder) -> Unit raise {
  pe.put_int16(self.error)
  pe.put_int64(self.high_watermark_offset)
  if self.version >= 4 {
    pe.put_int64(self.last_stable_offset)
    if self.version >= 5 {
      pe.put_int64(self.log_start_offset)
    }
    pe.put_array_length(self.aborted_transactions.length())
    for transaction in self.aborted_transactions {
      transaction.encode(pe)
    }
  }
  if self.version >= 11 {
    pe.put_int32(self.preferred_read_replica)
  }

  // Records length and records data
  pe.put_int32(self.records.length())
  pe.put_raw_bytes(self.records)
}

///|
/// Decode fetch response block from packet decoder
pub fn FetchResponseBlock::decode(
  self : Self,
  pd : &PacketDecoder,
  version : Int16,
) -> Self raise PacketDecodingError {
  let error = pd.get_int16()
  let high_watermark_offset = pd.get_int64()
  let (last_stable_offset, log_start_offset, aborted_transactions) = if version >= 4 {
    let last_stable = pd.get_int64()
    let log_start = if version >= 5 { pd.get_int64() } else { 0 }
    let aborted_count = pd.get_array_length()
    let aborted = if aborted_count > 0 {
      let aborted_array = Array::new(capacity=aborted_count)
      for _ in 0..<aborted_count {
        aborted_array.push(AbortedTransaction::decode(pd))
      }
      aborted_array
    } else {
      []
    }
    (last_stable, log_start, aborted)
  } else {
    (0, 0, [])
  }

  let preferred_read_replica = if version >= 11 { pd.get_int32() } else { -1 }

  // Read records
  let records_size = pd.get_int32()
  let records = if records_size > 0 {
    pd.get_raw_bytes(records_size).to_bytes()
  } else {
    []
  }

  {
    version: version,
    error: error,
    high_watermark_offset: high_watermark_offset,
    last_stable_offset: last_stable_offset,
    log_start_offset: log_start_offset,
    aborted_transactions: aborted_transactions,
    preferred_read_replica: preferred_read_replica,
    records: records,
  }
}

///|
/// Main fetch response structure
pub(all) struct FetchResponse {
  mut version : Int16
  mut throttle_time_ms : Int
  mut error_code : Int16
  mut session_id : Int
  mut blocks : Map[String, Map[Int, FetchResponseBlock]]
} derive(Show, ToJson)

///|
/// Create a new fetch response with default values
pub fn FetchResponse::new() -> FetchResponse {
  {
    version: 0,
    throttle_time_ms: 0,
    error_code: 0,
    session_id: 0,
    blocks: Map::new(),
  }
}

///|
/// Create a new fetch response with specified version
pub fn FetchResponse::with_version(version : Int16) -> FetchResponse {
  let response = FetchResponse::new()
  response.version = version
  response
}

///|
/// Get a block for specific topic and partition
pub fn FetchResponse::get_block(
  self : FetchResponse,
  topic : String,
  partition : Int,
) -> FetchResponseBlock? {
  match self.blocks.get(topic) {
    Some(partitions) => partitions.get(partition)
    None => None
  }
}

///|
/// Add an error for a specific topic and partition
pub fn FetchResponse::add_error(
  self : FetchResponse,
  topic : String,
  partition : Int,
  error : Int16,
) -> Unit {
  if !self.blocks.contains(topic) {
    self.blocks[topic] = Map::new()
  }
  if !self.blocks[topic].contains(partition) {
    let block = FetchResponseBlock::new()
    let updated_block = {
      version: self.version,
      error: error,
      high_watermark_offset: block.high_watermark_offset,
      last_stable_offset: block.last_stable_offset,
      log_start_offset: block.log_start_offset,
      aborted_transactions: block.aborted_transactions,
      preferred_read_replica: block.preferred_read_replica,
      records: block.records,
    }
    self.blocks[topic][partition] = updated_block
  } else {
    let block = self.blocks[topic][partition]
    let updated_block = {
      version: block.version,
      error: error,
      high_watermark_offset: block.high_watermark_offset,
      last_stable_offset: block.last_stable_offset,
      log_start_offset: block.log_start_offset,
      aborted_transactions: block.aborted_transactions,
      preferred_read_replica: block.preferred_read_replica,
      records: block.records,
    }
    self.blocks[topic][partition] = updated_block
  }
}

///|
/// Get or create a block for specific topic and partition
pub fn FetchResponse::get_or_create_block(
  self : FetchResponse,
  topic : String,
  partition : Int,
) -> FetchResponseBlock {
  if !self.blocks.contains(topic) {
    self.blocks[topic] = Map::new()
  }
  if !self.blocks[topic].contains(partition) {
    let block = {
      version: self.version,
      error: 0,
      high_watermark_offset: 0,
      last_stable_offset: 0,
      log_start_offset: 0,
      aborted_transactions: [],
      preferred_read_replica: -1,
      records: [],
    }
    self.blocks[topic][partition] = block
  }
  self.blocks[topic][partition]
}

///|
/// Encode fetch response to packet encoder
pub impl Encoder for FetchResponse with encode(self, pe) {
  if self.version < 0 || self.version > 11 {
    raise PacketEncodingError(
      "invalid or unsupported FetchResponse version field",
    )
  }
  if self.version >= 1 {
    pe.put_int32(self.throttle_time_ms)
  }
  if self.version >= 7 {
    pe.put_int16(self.error_code)
    pe.put_int32(self.session_id)
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
}

///|
/// Decode fetch response from packet decoder
pub impl VersionedDecoder for FetchResponse with decode(self, pd, version) raise PacketDecodingError {
  self.version = version
  if version >= 1 {
    self.throttle_time_ms = pd.get_int32()
  }
  if version >= 7 {
    self.error_code = pd.get_int16()
    self.session_id = pd.get_int32()
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
        let block = FetchResponseBlock::new()
        let decoded_block = block.decode(pd, version)
        partitions[partition_id] = decoded_block
      }
      self.blocks[topic] = partitions
    }
  }
}

///|
/// Get API key for fetch response
pub impl ProtocolBody for FetchResponse with key(self) {
  ApiKeyFetch
}

///|
/// Get version of fetch response
pub impl ProtocolBody for FetchResponse with version(self) {
  self.version
}

///|
/// Set version of fetch response
pub impl ProtocolBody for FetchResponse with set_version(self, version) {
  self.version = version
}

///|
/// Get header version based on response version
pub impl ProtocolBody for FetchResponse with header_version(self) {
  0 // Fetch response always uses header version 0
}

///|
/// Check if version is valid
pub impl ProtocolBody for FetchResponse with is_valid_version(self) {
  self.version >= 0 && self.version <= 11
}

///|
/// Get required Kafka version for response version
pub impl ProtocolBody for FetchResponse with required_version(self) {
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
