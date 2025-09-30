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
} derive(Show)

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
/// Fetch request structure
pub struct FetchRequest {
  replica_id : Int
  max_wait_time : Int
  min_bytes : Int
  max_bytes : Int
  isolation_level : Int
  session_id : Int
  session_epoch : Int
  topics : Array[FetchTopic]
  version : Int
} derive(Show, ToJson)

///|
/// Fetch topic structure
pub struct FetchTopic {
  topic : String
  partitions : Array[FetchPartition]
} derive(Show, ToJson)

///|
/// Fetch partition structure
pub struct FetchPartition {
  partition : Int
  fetch_offset : Int64
  log_start_offset : Int64
  partition_max_bytes : Int
} derive(Show, ToJson)

///|
/// Fetch response structure
pub struct FetchResponse {
  responses : Array[FetchTopicResponse]
  throttle_time_ms : Int?
  error : String?
  session_id : Int?
} derive(Show, ToJson)

///|
/// Fetch topic response structure
pub struct FetchTopicResponse {
  topic : String
  partitions : Array[FetchPartitionResponse]
} derive(Show, ToJson)

///|
/// Fetch partition response structure
pub struct FetchPartitionResponse {
  partition : Int
  error : String?
  high_watermark : Int64
  last_stable_offset : Int64?
  log_start_offset : Int64?
  aborted_transactions : Array[AbortedTransaction]
  preferred_read_replica : Int?
  records : Bytes
} derive(Show, ToJson)

///|
/// Aborted transaction structure
pub struct AbortedTransaction {
  producer_id : Int64
  first_offset : Int64
} derive(Show, ToJson)

///|
/// Metadata request structure
pub struct MetadataRequest {
  topics : Array[String]?
  allow_auto_topic_creation : Bool
  include_cluster_authorized_operations : Bool
  include_topic_authorized_operations : Bool
} derive(Show, ToJson)

///|
/// Metadata response structure
pub struct MetadataResponse {
  brokers : Array[BrokerMetadata]
  cluster_id : String?
  controller_id : Int
  topics : Array[TopicMetadata]
  cluster_authorized_operations : Int?
} derive(Show, ToJson)

///|
/// Broker metadata structure
pub struct BrokerMetadata {
  node_id : Int
  host : String
  port : Int
  rack : String?
} derive(Show, ToJson)

///|
/// Topic metadata structure
pub struct TopicMetadata {
  error : String?
  is_internal : Bool
  topic : String
  partition_metadata : Array[PartitionMetadata]
  topic_authorized_operations : Int?
} derive(Show, ToJson)

///|
/// Partition metadata structure
pub struct PartitionMetadata {
  error : String?
  partition : Int
  leader : Int
  replicas : Array[Int]
  isr : Array[Int]
  offline_replicas : Array[Int]
} derive(Show, ToJson)
