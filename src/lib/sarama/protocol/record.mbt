///|
/// Record parser for converting Kafka protocol records to ConsumerMessage
/// This module handles the parsing of batch records from FetchResponse

///|
/// Record header for Kafka messages (Kafka 0.11+)
pub struct RecordHeader {
  key : Bytes
  value : Bytes
} derive(Show, ToJson)
