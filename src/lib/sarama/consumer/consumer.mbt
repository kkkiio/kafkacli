///|
/// Consumer functionality for the Sarama Kafka client library
/// This module provides consumer and consumer group implementations

///|
/// Simplified partition consumer implementation for MVP
pub struct KafkaPartitionConsumer {
  topic : String
  partition : Int
  mut offset : Int64
  client : @client.KafkaClient
  seed_brokers : Array[String]
  client_id : String
  mut leader_addr : String
  mut leader_epoch : Int
  mut is_closed : Bool
} derive(Show)

///|
/// Choose starting offset for partition consumer
pub async fn partition_consumer_choose_starting_offset(
  consumer : KafkaPartitionConsumer,
  offset : Int64,
) -> Int64 {
  match offset {
    -1L => partition_consumer_fetch_offset(consumer, -1L)
    -2L => partition_consumer_fetch_offset(consumer, -2L)
    _ => {
      let earliest = partition_consumer_fetch_offset(consumer, -2L)
      let latest = partition_consumer_fetch_offset(consumer, -1L)
      if offset < earliest || offset > latest {
        fail(
          "Offset \{offset} out of range [\{earliest}, \{latest}] for \{consumer.topic}:\{consumer.partition}",
        )
      }
      offset
    }
  }
}

///|
/// Create a new partition consumer
pub async fn partition_consumer_new(
  topic : String,
  partition : Int,
  offset : Int64,
  client : @client.KafkaClient,
) -> KafkaPartitionConsumer {
  let brokers = @client.kafka_client_brokers(client)
  let config = @client.kafka_client_config(client)
  let consumer = {
    topic,
    partition,
    offset: 0L,
    client,
    seed_brokers: brokers.map(broker => broker.addr),
    client_id: config.client_id,
    leader_addr: "",
    leader_epoch: 0,
    is_closed: false,
  }
  let starting_offset = partition_consumer_choose_starting_offset(
    consumer, offset,
  )
  consumer.offset = starting_offset
  let (leader_addr, leader_epoch) = partition_consumer_resolve_leader(consumer)
  consumer.leader_addr = leader_addr
  consumer.leader_epoch = leader_epoch
  consumer
}

///|
fn partition_consumer_parse_broker_addr(addr : String) -> (String, Int) {
  match addr.split(":").to_array() {
    [host, port_str] => {
      let port = @strconv.parse_int(port_str) catch { _ => 9092 }
      (host.to_string(), port)
    }
    _ => (addr, 9092)
  }
}

///|
fn partition_consumer_is_leader_error(error_code : Int16) -> Bool {
  error_code == @protocol.ErrNotLeaderForPartition ||
  error_code == @protocol.ErrLeaderNotAvailable ||
  error_code == @protocol.ErrReplicaNotAvailable
}

///|
async fn partition_consumer_send_request(
  addr : String,
  encoded_request : Bytes,
) -> Bytes {
  let (host, port) = partition_consumer_parse_broker_addr(addr)
  let resolved = @socket.Addr::resolve(host, port~) catch {
    err =>
      fail(
        "Failed to resolve broker address: \{err}, host=\{host}, port=\{port}",
      )
  }
  let socket = @socket.TCP::connect(resolved) catch {
    err => fail("Failed to connect to broker: \{err}")
  }
  defer socket.close()
  socket.write(encoded_request) catch {
    err => fail("Failed to send request: \{err}")
  }
  let response_size_bytes = socket.read_exactly(4) catch {
    err => fail("Failed to read response size: \{err}")
  }
  guard response_size_bytes is [u32be(response_size)] else {
    fail("Invalid response size format")
  }
  let response_bytes = socket.read_exactly(response_size.reinterpret_as_int()) catch {
    err => fail("Failed to read response body: \{err}")
  }
  guard response_bytes is [u32be(_), .. payload] else {
    fail("Invalid response format")
  }
  payload.to_bytes()
}

///|
async fn partition_consumer_fetch_metadata(
  consumer : KafkaPartitionConsumer,
) -> @protocol.MetadataResponse {
  for addr in consumer.seed_brokers {
    let request_topics = [consumer.topic.to_string()]
    let metadata_request = @protocol.MetadataRequest::new(
      @protocol.default_version, request_topics,
    )
    let request = @protocol.Request::{
      body: metadata_request,
      correlation_id: 1,
      client_id: consumer.client_id,
    }
    let encoded = @protocol.encode(request)
    let payload = partition_consumer_send_request(addr, encoded)
    let response = @protocol.versioned_decode(
      payload,
      @protocol.MetadataResponse::decode,
      metadata_request.version,
    )
    return response
  }
  fail("Failed to fetch metadata from seed brokers")
}

///|
async fn partition_consumer_resolve_leader(
  consumer : KafkaPartitionConsumer,
) -> (String, Int) {
  let metadata = partition_consumer_fetch_metadata(consumer)
  guard metadata.topics
    .iter()
    .find_first(topic => topic.name == consumer.topic)
    .bind(topic => topic.partitions
      .iter()
      .find_first(partition => partition.id == consumer.partition))
    is Some(partition) else {
    fail("Topic \{consumer.topic} not found in metadata")
  }
  if partition.err.int_value() != @protocol.ErrNoError {
    fail(
      "Metadata error for partition: " + partition.err.int_value().to_string(),
    )
  }
  let leader_id = partition.leader
  let leader_epoch = partition.leader_epoch
  guard metadata.brokers.iter().find_first(broker => broker.id == leader_id)
    is Some(broker) else {
    fail("Leader broker \{leader_id} not found in metadata")
  }
  let leader_addr = @protocol.join_host_port(broker.host, broker.port)
  return (leader_addr, leader_epoch)
}

///|
async fn partition_consumer_fetch_offset(
  consumer : KafkaPartitionConsumer,
  timestamp : Int64,
) -> Int64 {
  let (leader_addr, _) = partition_consumer_resolve_leader(consumer)
  let offset_request = @protocol.OffsetRequest::with_version(4)
  offset_request.set_isolation_level(@protocol.ReadUncommitted)
  offset_request.add_block(
    consumer.topic.to_string(),
    consumer.partition,
    timestamp,
  )
  let request = @protocol.Request::{
    body: offset_request,
    correlation_id: 2,
    client_id: consumer.client_id,
  }
  let encoded = @protocol.encode(request) catch {
    err => fail("Failed to encode offset request: \{err}")
  }
  let payload = partition_consumer_send_request(leader_addr, encoded)
  let response = @protocol.versioned_decode(
    payload,
    @protocol.OffsetResponse::decode,
    offset_request.version,
  ) catch {
    err => fail("Failed to decode offset response: \{err}")
  }
  match response.get_block(consumer.topic, consumer.partition) {
    Some(block) => {
      if block.error != @protocol.ErrNoError {
        fail("Offset lookup error code: \{block.error}")
      }
      block.offset
    }
    None => fail("Offset response missing target partition")
  }
}

///|
/// Fetch messages from partition。内部会自动刷新元数据并在 leader 漂移时重试。
pub async fn KafkaPartitionConsumer::fetch_messages(
  self : KafkaPartitionConsumer,
) -> Array[@protocol.ConsumerMessage] {
  if self.is_closed {
    fail("Consumer is closed")
  }
  let conf = @client.kafka_client_config(self.client)
  let max_partition_fetch_bytes = conf.consumer.max_partition_fetch_bytes
  let mut attempt = 0
  let max_attempts = 3
  let mut last_error : String? = None
  while attempt < max_attempts {
    if self.leader_addr.length() == 0 {
      let (addr, epoch) = partition_consumer_resolve_leader(self)
      self.leader_addr = addr
      self.leader_epoch = epoch
    }
    let leader_epoch = self.leader_epoch
    let fetch_request = {
      ..@protocol.FetchRequest::with_version(11),
      max_wait_time: conf.consumer.max_wait_time_ms,
      min_bytes: conf.consumer.min_fetch_bytes,
      max_bytes: conf.consumer.max_fetch_bytes,
      isolation_level: @protocol.ReadUncommitted,
    }
    fetch_request.add_block(
      self.topic.to_string(),
      self.partition,
      self.offset,
      max_partition_fetch_bytes,
      leader_epoch,
    )
    let correlation_id = attempt + 1
    let request = @protocol.Request::{
      body: fetch_request,
      correlation_id,
      client_id: self.client_id,
    }
    let encoded_request = @protocol.encode(request) catch {
      err => {
        last_error = Some("Failed to encode fetch request: \{err}")
        attempt = attempt + 1
        continue
      }
    }
    let payload = partition_consumer_send_request(
      self.leader_addr,
      encoded_request,
    )
    let fetch_response = @protocol.versioned_decode(
      payload,
      @protocol.FetchResponse::decode,
      11,
    ) catch {
      err => {
        last_error = Some("Failed to decode fetch response: \{err}")
        attempt = attempt + 1
        continue
      }
    }
    match fetch_response.blocks.get(self.topic) {
      Some(partitions) =>
        match partitions.get(self.partition) {
          Some(partition_response) => {
            let error_code = partition_response.error
            if error_code != @protocol.ErrNoError {
              if partition_consumer_is_leader_error(error_code) {
                let (addr, epoch) = partition_consumer_resolve_leader(self)
                self.leader_addr = addr
                self.leader_epoch = epoch
                last_error = Some(
                  "Leader error during fetch, code " + error_code.to_string(),
                )
                attempt = attempt + 1
                continue
              } else if error_code == @protocol.ErrOffsetOutOfRange {
                last_error = Some(
                  "Offset \{self.offset} out of range for \{self.topic}:\{self.partition}",
                )
                break
              } else {
                last_error = Some(
                  "Kafka error in fetch response: " + error_code.to_string(),
                )
                break
              }
            }
            let messages = @protocol.parse_records_to_consumer_messages(
              self.topic,
              self.partition,
              partition_response.records,
            )
            let filtered_messages = []
            for msg in messages {
              if msg.offset >= self.offset {
                filtered_messages.push(msg)
              }
            }
            if filtered_messages.length() > 0 {
              let last_message = filtered_messages[filtered_messages.length() -
                1]
              self.offset = last_message.offset + 1
            } else if partition_response.high_watermark_offset > self.offset {
              self.offset = partition_response.high_watermark_offset
            }
            return filtered_messages
          }
          None => {
            last_error = Some(
              "No fetch response for partition " + self.partition.to_string(),
            )
            attempt = attempt + 1
            continue
          }
        }
      None => {
        last_error = Some("No fetch response for topic " + self.topic)
        attempt = attempt + 1
        continue
      }
    }
  }
  match last_error {
    Some(err) => fail(err)
    None => fail("Failed to fetch messages")
  }
}

///|
/// Check if partition consumer is closed
pub fn partition_consumer_is_closed(consumer : KafkaPartitionConsumer) -> Bool {
  consumer.is_closed
}

///|
pub fn partition_consumer_current_offset(
  consumer : KafkaPartitionConsumer,
) -> Int64 {
  consumer.offset
}

///|
/// Implement PartitionConsumer trait for KafkaPartitionConsumer
pub fn KafkaPartitionConsumer::close(self : KafkaPartitionConsumer) -> Unit {
  self.is_closed = true
}

///|
pub fn KafkaPartitionConsumer::is_closed(self : KafkaPartitionConsumer) -> Bool {
  partition_consumer_is_closed(self)
}

///|
pub fn KafkaPartitionConsumer::current_offset(
  self : KafkaPartitionConsumer,
) -> Int64 {
  partition_consumer_current_offset(self)
}

///|
/// HighWaterMarkOffset returns the high water mark offset of the partition,
/// i.e. the offset that will be used for the next message that will be produced.
/// You can use this to determine how far behind the processing is.
pub fn KafkaPartitionConsumer::high_water_mark_offset(
  self : KafkaPartitionConsumer,
) -> Int64 {
  ...
}

///|
/// Simplified consumer implementation for MVP
pub struct KafkaConsumer {
  client : @client.KafkaClient
  conf : @core.Config
} derive(Show)

///|
/// // NewConsumer creates a new consumer using the given broker addresses and configuration.
pub fn KafkaConsumer::new(
  addrs : Array[String],
  conf : @core.Config,
) -> KafkaConsumer {
  let client = @client.KafkaClient::new(conf, addrs)
  { client, conf }
}

///|
/// Get topics from consumer (delegates to client)
pub fn consumer_topics(
  consumer : KafkaConsumer,
) -> Array[String] raise {
  @client.kafka_client_topics(consumer.client)
}

///|
/// Get partitions for a topic (delegates to client)
pub fn consumer_partitions(
  consumer : KafkaConsumer,
  topic : String,
) -> Array[Int] raise {
  @client.kafka_client_partitions(consumer.client, topic)
}

///|
/// Create partition consumer (simplified MVP implementation)
pub async fn KafkaConsumer::consume_partition(
  self : KafkaConsumer,
  topic : String,
  partition : Int,
  offset : Int64,
) -> KafkaPartitionConsumer {
  partition_consumer_new(topic, partition, offset, self.client)
}

///|
/// Close consumer (simplified MVP implementation)
pub fn KafkaConsumer::close(self : KafkaConsumer) -> Unit {
  // Simple MVP implementation - just delegate to client close
  @client.kafka_client_close(self.client)
}
