///|
/// Record parser for converting Kafka protocol records to ConsumerMessage
/// This module handles the parsing of batch records from FetchResponse

///|
/// Record header for Kafka messages (Kafka 0.11+)
pub(all) struct RecordHeader {
  key : Bytes
  value : Bytes
} derive(Show, ToJson, Eq)

///|
/// Record is kafka record type (matches Go Sarama Record structure)
pub(all) struct Record {
  headers : Array[RecordHeader]
  attributes : Byte
  timestamp_delta : Int64 // milliseconds
  offset_delta : Int64
  key : Bytes
  value : Bytes
} derive(Show, ToJson, Eq)

///|
/// Decode record header
pub fn RecordHeader::decode(pd : &PacketDecoder) -> RecordHeader raise {
  let key = pd.get_varint_bytes().map_or(b"", BytesView::to_bytes)
  let value = pd.get_varint_bytes().map_or(b"", BytesView::to_bytes)
  { key, value }
}

///|
/// Decode record
pub fn Record::decode(pd : &PacketDecoder) -> Record raise {
  pd.push(VarintLengthField::{ start_offset: 0, length: 0 })

  let attributes = pd.get_byte()
  let timestamp_delta = pd.get_varint()
  let offset_delta = pd.get_varint()
  let key = pd.get_varint_bytes().map_or(b"", BytesView::to_bytes)
  let value = pd.get_varint_bytes().map_or(b"", BytesView::to_bytes)
  let headers_count64 = pd.get_varint()
  let headers_count = if headers_count64 <= 0 {
    0
  } else {
    headers_count64.to_int()
  }
  let headers : Array[RecordHeader] = Array::new(capacity=headers_count)
  for _ in 0..<headers_count {
    headers.push(RecordHeader::decode(pd))
  }
  pd.pop()

  {
    headers,
    attributes,
    timestamp_delta,
    offset_delta,
    key,
    value,
  }
}
