///|
/// Configuration types and defaults for the Sarama Kafka client library

///|
/// Admin configuration section
pub struct AdminConfig {
  retry_max : Int
  retry_backoff_ms : Int
  timeout_ms : Int
} derive(Show, ToJson)

///|
/// Default admin configuration
pub impl Default for AdminConfig with default() {
  { retry_max: 5, retry_backoff_ms: 100, timeout_ms: 3000 }
}

///|
/// Network configuration section
pub(all) struct NetConfig {
  max_open_requests : Int
  dial_timeout_ms : Int
  read_timeout_ms : Int
  write_timeout_ms : Int
  tls_enable : Bool
} derive(Show, ToJson)

///|
/// Default network configuration
pub impl Default for NetConfig with default() {
  {
    max_open_requests: 5,
    dial_timeout_ms: 30000,
    read_timeout_ms: 30000,
    write_timeout_ms: 30000,
    tls_enable: false,
  }
}

///|
/// Producer configuration section
pub(all) struct ProducerConfig {
  max_message_bytes : Int
  required_acks : @protocol.RequiredAcks
  timeout_ms : Int
  retries : Int
  retry_backoff_ms : Int
  idempotent : Bool
} derive(Show, ToJson)

///|
/// Default producer configuration
pub impl Default for ProducerConfig with default() {
  {
    max_message_bytes: 1000012, // 1MB
    required_acks: WaitForLocal,
    timeout_ms: 30000,
    retries: 0,
    retry_backoff_ms: 100,
    idempotent: false,
  }
}

///|
/// Consumer configuration section
pub(all) struct ConsumerConfig {
  group_id : String?
  offset_reset : OffsetReset
  max_wait_time_ms : Int
  min_fetch_bytes : Int
  max_fetch_bytes : Int
  max_partition_fetch_bytes : Int
  session_timeout_ms : Int
  heartbeat_interval_ms : Int
  // How long to wait after a failing to read from a partition before
  // trying again (default 2s).
  retry_backoff_ms : Milliseconds
} derive(Show)

///|
pub(all) enum OffsetReset {
  Earliest
  Latest
} derive(Show, ToJson)

///|
/// Default consumer configuration
pub impl Default for ConsumerConfig with default() {
  {
    group_id: None,
    offset_reset: Latest,
    max_wait_time_ms: 500,
    min_fetch_bytes: 1,
    max_fetch_bytes: 52428800, // 50MB
    max_partition_fetch_bytes: 1048576, // 1MB
    session_timeout_ms: 10000,
    heartbeat_interval_ms: 3000,
    retry_backoff_ms: 2000,
  }
}

///|
/// Main configuration structure
pub(all) struct Config {
  client_id : String
  admin : AdminConfig
  net : NetConfig
  producer : ProducerConfig
  consumer : ConsumerConfig
  /// ApiVersionsRequest determines whether Sarama should send an
  /// ApiVersionsRequest message to each broker as part of its initial
  /// connection. This defaults to `true` to match the official Java client
  /// and most 3rdparty ones.
  api_versions_request : Bool
  /// The version of Kafka that Sarama will assume it is running against.
  /// Defaults to the oldest supported stable version. Since Kafka provides
  /// backwards-compatibility, setting it to a version older than you have
  /// will not break anything, although it may prevent you from using the
  /// latest features. Setting it to a version greater than you are actually
  /// running may lead to random breakage.
  version : @protocol.KafkaVersion
} derive(Show)

///|
/// Default configuration
pub impl Default for Config with default() {
  {
    client_id: "sarama-mbt",
    admin: AdminConfig::default(),
    net: NetConfig::default(),
    producer: ProducerConfig::default(),
    consumer: ConsumerConfig::default(),
    api_versions_request: true,
    version: @protocol.default_version,
  }
}

///|
/// Create a new Config with default values
pub fn Config::new() -> Config {
  Config::default()
}

///|
using @protocol {type Milliseconds}
