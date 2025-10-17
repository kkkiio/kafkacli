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
/// Only supports RecordBatch format (Kafka 0.11+)
pub fn parse_records_to_consumer_messages(
  topic : String,
  partition : Int,
  records : Bytes,
) -> Array[ConsumerMessage] raise {
  if records.length() == 0 {
    return []
  }
  let messages = []

  // Parse the records as a RecordBatch
  let record_batch = RecordBatch::decode(records)

  // Skip control batches
  if record_batch.control {
    return []
  }

  // Convert each record in the batch to a ConsumerMessage
  for record in record_batch.records {
    let consumer_message = convert_record_to_consumer_message(
      record_batch, record, topic, partition,
    )
    messages.push(consumer_message)
  }
  messages
}

///|
/// Convert a Record from RecordBatch to ConsumerMessage
pub fn convert_record_to_consumer_message(
  record_batch : RecordBatch,
  record : Record,
  topic : String,
  partition : Int,
) -> ConsumerMessage {
  // Calculate absolute timestamp and offset
  let absolute_timestamp = record_batch.first_timestamp + record.timestamp_delta
  let absolute_offset = record_batch.first_offset + record.offset_delta
  ConsumerMessage::{
    headers: record.headers,
    timestamp: absolute_timestamp,
    block_timestamp: record_batch.first_timestamp,
    key: record.key,
    value: record.value,
    topic,
    partition,
    offset: absolute_offset,
  }
}
