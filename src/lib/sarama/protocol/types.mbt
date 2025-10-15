///|
/// Protocol types and encoding/decoding for the Sarama Kafka client library
/// This module provides Kafka protocol request/response types

///|
/// Required acknowledgements for produce requests
pub(all) enum RequiredAcks {
  NoResponse
  WaitForLocal
  WaitForAll
} derive(Eq, Show, ToJson)

///|
/// Convert RequiredAcks to int16
pub fn required_acks_to_int(acks : RequiredAcks) -> Int {
  match acks {
    NoResponse => 0
    WaitForLocal => 1
    WaitForAll => -1
  }
}

///|
/// Convert int16 to RequiredAcks
pub fn int_to_required_acks(value : Int) -> RequiredAcks raise {
  match value {
    0 => NoResponse
    1 => WaitForLocal
    -1 => WaitForAll
    _ => fail("Invalid required acks value: " + value.to_string())
  }
}

///|
/// Response header structure
pub struct ResponseHeader {
  length : Int
  correlation_id : Int
} derive(Show, ToJson)

///|
/// Response structure
pub struct Response {
  header : ResponseHeader
  body : &ProtocolBody
} derive(ToJson)

///|
/// Produce request structure
pub struct ProduceRequest {
  transactional_id : String?
  required_acks : RequiredAcks
  timeout : Int
  version : Int
  records : Map[String, Map[Int, Bytes]] // Simplified from Records
} derive(Show, ToJson)

///|
/// Create new produce request
pub fn produce_request_new() -> ProduceRequest {
  {
    transactional_id: None,
    required_acks: WaitForLocal,
    timeout: 30000,
    version: 0,
    records: Map::new(),
  }
}

///|
/// Produce response structure
pub struct ProduceResponse {
  responses : Map[String, Map[Int, ProducePartitionResponse]]
  throttle_time_ms : Int?
} derive(Show, ToJson)

///|
/// Produce partition response structure
pub struct ProducePartitionResponse {
  error : String?
  offset : Int64
  timestamp : Int64?
  log_start_offset : Int64?
  log_append_time : Int64?
} derive(Show, ToJson)

///|
/// Broker metadata structure (compatible with Kafka protocol)
pub(all) struct BrokerMetadata {
  mut id : Int // Kafka broker ID，对应Go sarama的id字段
  mut host : String
  mut port : Int
  mut rack : String?
  mut version : Int // 添加version字段用于编码解码
} derive(Show, ToJson, Eq)

///|
/// Join host and port into address string
pub fn join_host_port(host : String, port : Int) -> String {
  host + ":" + port.to_string()
}

///|
/// Encode broker metadata to packet encoder
pub impl Encoder for BrokerMetadata with encode(self, pe) {
  pe.put_int32(self.id)
  pe.put_string(self.host)
  pe.put_int32(self.port)

  // Encode rack for versions 1+
  if self.version >= 1 {
    pe.put_nullable_string(self.rack)
  }

  // Add tagged fields for versions 9+
  if self.version >= 9 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode broker metadata from packet decoder
pub impl VersionedDecoder for BrokerMetadata with decode(self, pd, version) {
  self.version = version.to_int()
  self.id = pd.get_int32()
  self.host = pd.get_string()
  self.port = pd.get_int32()

  // Decode rack for versions 1+
  if version >= 1 {
    self.rack = pd.get_nullable_string()
  }

  // Skip tagged fields for versions 9+
  if version >= 9 {
    ignore(pd.get_empty_tagged_field_array())
  }
}
