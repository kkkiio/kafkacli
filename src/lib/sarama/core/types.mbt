///|
/// Core types and constants for the Sarama Kafka client library
/// This module provides fundamental types used throughout the Sarama library

///|
/// Compression codecs supported by Kafka
pub enum CompressionCodec {
  None
  Gzip
  Snappy
  LZ4
  ZSTD
} derive(Eq, Show, ToJson)

///|
/// Convert CompressionCodec to string representation
pub fn compression_codec_to_string(codec : CompressionCodec) -> String {
  match codec {
    None => "none"
    Gzip => "gzip"
    Snappy => "snappy"
    LZ4 => "lz4"
    ZSTD => "zstd"
  }
}

///|
/// Parse string to CompressionCodec
pub fn string_to_compression_codec(text : String) -> Result[CompressionCodec, String] {
  match text {
    "none" => Ok(None)
    "gzip" => Ok(Gzip)
    "snappy" => Ok(Snappy)
    "lz4" => Ok(LZ4)
    "zstd" => Ok(ZSTD)
    _ => Err("Cannot parse " + text + " as a compression codec")
  }
}

///|
/// Kafka API keys as defined in the Kafka protocol
pub enum ApiKey {
  Produce
  Fetch
  ListOffsets
  Metadata
  LeaderAndIsr
  StopReplica
  UpdateMetadata
  ControlledShutdown
  OffsetCommit
  OffsetFetch
  FindCoordinator
  JoinGroup
  Heartbeat
  LeaveGroup
  SyncGroup
  DescribeGroups
  ListGroups
  SaslHandshake
  ApiVersions
  CreateTopics
  DeleteTopics
  DeleteRecords
  InitProducerId
  OffsetForLeaderEpoch
  AddPartitionsToTxn
  AddOffsetsToTxn
  EndTxn
  WriteTxnMarkers
  TxnOffsetCommit
  DescribeAcls
  CreateAcls
  DeleteAcls
  DescribeConfigs
  AlterConfigs
  AlterReplicaLogDirs
  DescribeLogDirs
  SaslAuth
  CreatePartitions
  CreateDelegationToken
  RenewDelegationToken
  ExpireDelegationToken
  DescribeDelegationToken
  DeleteGroups
  ElectLeaders
  IncrementalAlterConfigs
  AlterPartitionReassignments
  ListPartitionReassignments
  OffsetDelete
  DescribeClientQuotas
  AlterClientQuotas
  DescribeUserScramCredentials
  AlterUserScramCredentials
} derive(Eq, Show, ToJson)

///|
/// Get the integer value for an API key
pub fn api_key_to_int(key : ApiKey) -> Int {
  match key {
    Produce => 0
    Fetch => 1
    ListOffsets => 2
    Metadata => 3
    LeaderAndIsr => 4
    StopReplica => 5
    UpdateMetadata => 6
    ControlledShutdown => 7
    OffsetCommit => 8
    OffsetFetch => 9
    FindCoordinator => 10
    JoinGroup => 11
    Heartbeat => 12
    LeaveGroup => 13
    SyncGroup => 14
    DescribeGroups => 15
    ListGroups => 16
    SaslHandshake => 17
    ApiVersions => 18
    CreateTopics => 19
    DeleteTopics => 20
    DeleteRecords => 21
    InitProducerId => 22
    OffsetForLeaderEpoch => 23
    AddPartitionsToTxn => 24
    AddOffsetsToTxn => 25
    EndTxn => 26
    WriteTxnMarkers => 27
    TxnOffsetCommit => 28
    DescribeAcls => 29
    CreateAcls => 30
    DeleteAcls => 31
    DescribeConfigs => 32
    AlterConfigs => 33
    AlterReplicaLogDirs => 34
    DescribeLogDirs => 35
    SaslAuth => 36
    CreatePartitions => 37
    CreateDelegationToken => 38
    RenewDelegationToken => 39
    ExpireDelegationToken => 40
    DescribeDelegationToken => 41
    DeleteGroups => 42
    ElectLeaders => 43
    IncrementalAlterConfigs => 44
    AlterPartitionReassignments => 45
    ListPartitionReassignments => 46
    OffsetDelete => 47
    DescribeClientQuotas => 48
    AlterClientQuotas => 49
    DescribeUserScramCredentials => 50
    AlterUserScramCredentials => 51
  }
}

///|
/// Message structure representing a Kafka message
pub struct Message {
  codec : CompressionCodec
  compression_level : Int
  log_append_time : Bool
  key : Bytes
  value : Bytes
  version : Int
  timestamp : Int64  // Unix timestamp in milliseconds
} derive(Show, ToJson)

///|
/// Create a new Message with default values
pub fn message_new() -> Message {
  {
    codec: None,
    compression_level: -1000,  // CompressionLevelDefault
    log_append_time: false,
    key: b"",
    value: b"",
    version: 0,
    timestamp: 0L
  }
}

///|
/// Record header for Kafka messages (Kafka 0.11+)
pub struct RecordHeader {
  key : Bytes
  value : Bytes
} derive(Show, ToJson)

///|
/// Consumer message structure
pub struct ConsumerMessage {
  headers : Array[RecordHeader]
  timestamp : Int64  // Unix timestamp in milliseconds
  block_timestamp : Int64  // Outer (compressed) block timestamp
  key : Bytes
  value : Bytes
  topic : String
  partition : Int
  offset : Int64
} derive(Show, ToJson)

///|
/// Consumer error structure
pub struct ConsumerError {
  topic : String
  partition : Int
  err : String
} derive(Show, ToJson)

///|
/// Convert ConsumerError to string representation
pub fn consumer_error_to_string(err : ConsumerError) -> String {
  "kafka: error while consuming " + err.topic + "/" + err.partition.to_string() + ": " + err.err
}