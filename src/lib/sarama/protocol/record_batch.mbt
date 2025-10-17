///|
/// RecordBatch implementation for Kafka 0.11+ record format
/// Simplified version without compression support

const RECORD_BATCH_OVERHEAD : Int = 49

///|
/// RecordBatch represents Kafka's batch record format
pub struct RecordBatch {
  first_offset : Int64
  partition_leader_epoch : Int
  version : Byte
  control : Bool
  last_offset_delta : Int
  first_timestamp : Int64
  max_timestamp : Int64
  producer_id : Int64
  producer_epoch : Int16
  first_sequence : Int
  records : Array[Record]
} derive(Show, ToJson)

///|
/// Create a new empty RecordBatch
pub fn RecordBatch::new() -> RecordBatch {
  {
    first_offset: 0,
    partition_leader_epoch: 0,
    version: 2, // Default to version 2
    control: false,
    last_offset_delta: 0,
    first_timestamp: 0,
    max_timestamp: 0,
    producer_id: 0,
    producer_epoch: 0,
    first_sequence: 0,
    records: [],
  }
}

///|
/// Get the last offset of the batch
pub fn RecordBatch::last_offset(self : RecordBatch) -> Int64 {
  self.first_offset + self.last_offset_delta.to_int64()
}

///|
/// Decode RecordBatch from bytes (simplified version, no compression support)
pub fn RecordBatch::decode(data : Bytes) -> RecordBatch raise {
  if data.length() < 49 {
    fail("RecordBatch too short: " + data.length().to_string())
  }
  let helper = RealDecoder::new(data[:])

  let first_offset = helper.get_int64()
  let batch_length = helper.get_int()
  if batch_length < 0 {
    fail("RecordBatch length must be non-negative")
  }
  if batch_length < RECORD_BATCH_OVERHEAD {
    fail("RecordBatch length smaller than header")
  }
  let record_bytes_len = batch_length - RECORD_BATCH_OVERHEAD

  let partition_leader_epoch = helper.get_int()
  let version = helper.get_byte()
  if version != 2 {
    fail("Unsupported RecordBatch version: " + version.to_string())
  }

  // Skip CRC (4 bytes)
  let _ = helper.get_int()

  let attributes = helper.get_int16()
  let attributes_int = attributes.to_int()
  let compression_mask = 0x07
  if (attributes_int & compression_mask) != 0 {
    fail("Compressed RecordBatch is not supported yet")
  }
  let control = (attributes_int & 0x20) != 0

  let last_offset_delta = helper.get_int()
  let first_timestamp = helper.get_int64()
  let max_timestamp = helper.get_int64()
  let producer_id = helper.get_int64()
  let producer_epoch = helper.get_int16()
  let first_sequence = helper.get_int()

  let num_records = helper.get_int()
  let record_count = if num_records < 0 { 0 } else { num_records }

  let record_bytes = helper.get_raw_bytes(record_bytes_len)
  let record_decoder = RealDecoder::new(record_bytes)
  let records = if record_count == 0 {
    []
  } else {
    let records_array = Array::new(capacity=record_count)
    for _ in 0..<record_count {
      let record = Record::decode(record_decoder)
      records_array.push(record)
    }
    records_array
  }
  if record_decoder.remaining() != 0 {
    fail("Record payload has trailing bytes")
  }

  {
    first_offset,
    partition_leader_epoch,
    version,
    control,
    last_offset_delta,
    first_timestamp,
    max_timestamp,
    producer_id,
    producer_epoch,
    first_sequence,
    records,
  }
}
