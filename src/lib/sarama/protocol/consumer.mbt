///|
/// Consumer message structure
pub(all) struct ConsumerMessage {
  headers : Array[RecordHeader]
  timestamp : Int64 // Unix timestamp in milliseconds
  block_timestamp : Int64 // Outer (compressed) block timestamp
  key : Bytes
  value : Bytes
  topic : String
  partition : Int
  offset : Int64
} derive(Show, ToJson)

///|
/// Parse records from FetchResponse partition data into ConsumerMessage array
pub fn parse_records_to_consumer_messages(
  topic : String,
  partition : Int,
  records : Bytes,
) -> Array[ConsumerMessage] raise {
  if records.length() == 0 {
    return []
  }

  // For now, we'll implement a simple parser that handles basic records
  // In a full implementation, this would parse the complete RecordBatch format
  // including magic bytes, attributes, timestamps, keys, values, etc.

  let messages = []
  let mut offset = 0

  // Simple parsing - assumes records are in a simple format for MVP
  // This is a simplified implementation that works for basic testing
  while offset < records.length() {
    let remaining = records.length() - offset

    // Need at least 4 bytes for record length
    if remaining < 4 {
      break
    }

    // Read record length (4 bytes, big endian)
    let record_length = (records[offset].to_int() << 24) |
      (records[offset + 1].to_int() << 16) |
      (records[offset + 2].to_int() << 8) |
      records[offset + 3].to_int()
    offset = offset + 4

    // Check if we have enough bytes for the record
    if record_length <= 0 || record_length > remaining - 4 {
      break
    }

    // Extract record data
    let record_data = records[offset:offset + record_length]
    offset = offset + record_length

    // Parse the record (simplified parsing for MVP)
    messages.push(parse_single_record(topic, partition, record_data))
  }
  messages
}

///|
/// Parse a single record into ConsumerMessage
pub fn parse_single_record(
  topic : String,
  partition : Int,
  record_data : BytesView,
) -> ConsumerMessage raise {
  if record_data.length() < 24 {
    fail("Record too short")
  }

  // Simple record format for MVP:
  // 8 bytes: timestamp
  // 8 bytes: offset
  // 4 bytes: key length
  // N bytes: key
  // 4 bytes: value length
  // N bytes: value

  let mut offset = 0

  // Read timestamp (8 bytes)
  let timestamp = (record_data[offset].to_int64() << 56) |
    (record_data[offset + 1].to_int64() << 48) |
    (record_data[offset + 2].to_int64() << 40) |
    (record_data[offset + 3].to_int64() << 32) |
    (record_data[offset + 4].to_int64() << 24) |
    (record_data[offset + 5].to_int64() << 16) |
    (record_data[offset + 6].to_int64() << 8) |
    record_data[offset + 7].to_int64()
  offset = offset + 8

  // Read offset (8 bytes)
  let record_offset = (record_data[offset].to_int64() << 56) |
    (record_data[offset + 1].to_int64() << 48) |
    (record_data[offset + 2].to_int64() << 40) |
    (record_data[offset + 3].to_int64() << 32) |
    (record_data[offset + 4].to_int64() << 24) |
    (record_data[offset + 5].to_int64() << 16) |
    (record_data[offset + 6].to_int64() << 8) |
    record_data[offset + 7].to_int64()
  offset = offset + 8

  // Read key length (4 bytes)
  let key_length = (record_data[offset].to_int() << 24) |
    (record_data[offset + 1].to_int() << 16) |
    (record_data[offset + 2].to_int() << 8) |
    record_data[offset + 3].to_int()
  offset = offset + 4

  // Read key
  let key = if key_length > 0 && key_length <= record_data.length() - offset {
    let key_data = record_data[offset:offset + key_length]
    offset = offset + key_length
    key_data.to_bytes()
  } else {
    b""
  }

  // Read value length (4 bytes)
  if offset + 4 > record_data.length() {
    fail("Record too short for value length")
  }
  let value_length = (record_data[offset].to_int() << 24) |
    (record_data[offset + 1].to_int() << 16) |
    (record_data[offset + 2].to_int() << 8) |
    record_data[offset + 3].to_int()
  offset = offset + 4

  // Read value
  let value = if value_length > 0 &&
    value_length <= record_data.length() - offset {
    let value_data = record_data[offset:offset + value_length]
    value_data.to_bytes()
  } else {
    b""
  }

  // Create ConsumerMessage
  ConsumerMessage::{
    headers: [],
    timestamp,
    block_timestamp: timestamp, // Use same timestamp for MVP
    key,
    value,
    topic,
    partition,
    offset: record_offset,
  }
}
