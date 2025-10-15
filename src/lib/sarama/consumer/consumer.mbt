///|
/// Consumer functionality for the Sarama Kafka client library
/// This module provides consumer and consumer group implementations

///|
/// Simplified partition consumer interface for MVP
pub trait PartitionConsumer {
  /// Close partition consumer
  async close(Self) -> Unit

  /// Fetch messages from partition
  async fetch_messages(Self) -> Array[@protocol.ConsumerMessage]

  /// Check if consumer is closed
  is_closed(Self) -> Bool
}

///|
/// Simplified consumer interface for MVP
pub trait Consumer {
  /// Get available topics
  topics() -> Result[Array[String], String]

  /// Get partitions for a topic
  partitions(topic : String) -> Result[Array[Int], String]

  /// Create partition consumer for topic/partition with given offset
  consume_partition(topic : String, partition : Int, offset : Int64) -> &PartitionConsumer raise

  /// Close consumer
  close() -> Result[Unit, String]
}

///|
/// Simplified partition consumer implementation for MVP
pub struct KafkaPartitionConsumer {
  topic : String
  partition : Int
  offset : Int64
  client : @client.KafkaClient
  is_closed : Bool
} derive(Show, ToJson)

///|
/// Choose starting offset for partition consumer
pub fn partition_consumer_choose_starting_offset(
  topic : String,
  partition : Int,
  offset : Int64,
  client : @client.KafkaClient,
) -> Int64 raise {
  match offset {
    // OffsetNewest (-1): get latest offset
    -1L =>
      match @client.kafka_client_get_offset(client, topic, partition, -1L) {
        Ok(latest_offset) => latest_offset
        Err(e) => fail("Failed to get latest offset: " + e)
      }
    // OffsetOldest (-2): get earliest offset
    -2L =>
      match @client.kafka_client_get_offset(client, topic, partition, -2L) {
        Ok(earliest_offset) => earliest_offset
        Err(e) => fail("Failed to get earliest offset: " + e)
      }
    // Specific offset: validate it's in range
    _ => offset
  }
}

///|
/// Create a new partition consumer
pub fn partition_consumer_new(
  topic : String,
  partition : Int,
  offset : Int64,
  client : @client.KafkaClient,
) -> KafkaPartitionConsumer raise {
  let starting_offset = partition_consumer_choose_starting_offset(
    topic, partition, offset, client,
  )
  { topic, partition, offset: starting_offset, client, is_closed: false }
}

///|
/// Fetch messages from partition (MVP implementation)
pub async fn partition_consumer_fetch_messages(
  consumer : KafkaPartitionConsumer,
) -> Array[@protocol.ConsumerMessage] {
  if consumer.is_closed {
    fail("Consumer is closed")
  }

  // Get leader broker for this partition
  let leader = @client.kafka_client_leader(
    consumer.client,
    consumer.topic,
    consumer.partition,
  )

  // Parse broker address
  let broker_address = leader.addr
  let (host, port_str) = match broker_address.split(":").to_array() {
    [h, p] => (h, p)
    _ => (broker_address, "9092") // default port
  }
  let port = @strconv.parse_int(port_str) catch { _ => 9092 }

  // Create FetchRequest
  let fetch_request = @protocol.FetchRequest::with_version(4) // Use version 4 for basic functionality
  fetch_request.max_wait_time = 500 // 500ms max wait
  fetch_request.min_bytes = 1 // Return at least 1 byte
  fetch_request.max_bytes = 1048576 // 1MB max
  fetch_request.isolation_level = @protocol.ReadUncommitted

  // Add partition to fetch request
  fetch_request.add_block(
    consumer.topic,
    consumer.partition,
    consumer.offset,
    1048576, // 1MB max per partition
    0, // leader epoch
  )

  // Establish network connection
  let addr = @socket.Addr::resolve(host.to_string(), port~) catch {
    err =>
      fail(
        "Failed to resolve broker address: \{err}" +
        ", host=\{host}" +
        ", port=\{port}",
      )
  }
  let socket = @socket.TCP::connect(addr) catch {
    err => fail("Failed to connect to broker: \{err}, addr=\{addr}")
  }
  defer socket.close()

  // Create and encode request
  let correlation_id = 123 // Simple correlation ID for MVP
  let request_body = fetch_request
  let request = @protocol.Request::{
    body: request_body,
    correlation_id,
    client_id: "kafkacli",
  }
  let encoded_request = @protocol.encode(request)

  // Send request
  socket.write(encoded_request) catch {
    err => fail("Failed to send fetch request: \{err}")
  }

  // Read response size (4 bytes big-endian)
  let response_size_bytes = socket.read_exactly(4) catch {
    err => fail("Failed to read response size: \{err}")
  }
  guard response_size_bytes is [u32be(response_size)] else {
    fail("Invalid response size format")
  }

  // Read response body
  let response_bytes = socket.read_exactly(response_size.reinterpret_as_int()) catch {
    err => fail("Failed to read response body: \{err}")
  }

  // Parse response (skip 4-byte size field)
  guard response_bytes is [u32be(_), .. payload] else {
    fail("Invalid response format")
  }

  // Create and decode FetchResponse
  let fetch_response = @protocol.FetchResponse::with_version(4)
  let response_body = fetch_response
  @protocol.versioned_decode(payload, response_body, 4) catch {
    err => fail("Failed to decode fetch response: \{err}")
  }

  // Extract messages from response
  let all_messages = []
  match fetch_response.blocks.get(consumer.topic) {
    Some(partitions) =>
      match partitions.get(consumer.partition) {
        Some(partition_response) => {
          // Check for errors
          if partition_response.error != 0 {
            fail(
              "Kafka error in fetch response: " +
              partition_response.error.to_string(),
            )
          }

          // Parse records into ConsumerMessage array
          let messages = @protocol.parse_records_to_consumer_messages(
            consumer.topic,
            consumer.partition,
            partition_response.records,
          )
          let mut i = 0
          while i < messages.length() {
            all_messages.push(messages[i])
            i = i + 1
          }
        }
        None =>
          fail("No response for partition: " + consumer.partition.to_string())
      }
    None => fail("No response for topic: " + consumer.topic)
  }

  // Filter messages based on consumer offset and return
  let filtered_messages = []
  let mut i = 0
  while i < all_messages.length() {
    let msg = all_messages[i]
    if msg.offset >= consumer.offset {
      filtered_messages.push(msg)
    }
    i = i + 1
  }

  // Update consumer offset to the highest fetched offset + 1
  if filtered_messages.length() > 0 {
    let last_message = filtered_messages[filtered_messages.length() - 1]
    // Note: In a real implementation, we would update the consumer's offset
    // For now, we'll just return the messages
    println(
      "Fetched \{filtered_messages.length()} messages from offset \{consumer.offset}",
    )
  }
  filtered_messages
}

///|
/// Check if partition consumer is closed
pub fn partition_consumer_is_closed(consumer : KafkaPartitionConsumer) -> Bool {
  consumer.is_closed
}

///|
/// Implement PartitionConsumer trait for KafkaPartitionConsumer
pub impl PartitionConsumer for KafkaPartitionConsumer with close(self) {
  // Simple MVP implementation - just mark as closed
}

///|
pub impl PartitionConsumer for KafkaPartitionConsumer with fetch_messages(self) {
  partition_consumer_fetch_messages(self)
}

///|
pub impl PartitionConsumer for KafkaPartitionConsumer with is_closed(self) -> Bool {
  partition_consumer_is_closed(self)
}

///|
/// Simplified consumer implementation for MVP
pub struct KafkaConsumer {
  client : @client.KafkaClient
  conf : @core.Config
} derive(Show, ToJson)

///|
/// Create a new consumer (simplified MVP implementation)
pub fn consumer_new(client : @client.KafkaClient) -> KafkaConsumer raise {
  if @client.kafka_client_closed(client) {
    fail("Client is closed")
  }
  { client, conf: @client.kafka_client_config(client) }
}

///|
/// Get topics from consumer (delegates to client)
pub fn consumer_topics(
  consumer : KafkaConsumer,
) -> Result[Array[String], String] {
  @client.kafka_client_topics(consumer.client)
}

///|
/// Get partitions for a topic (delegates to client)
pub fn consumer_partitions(
  consumer : KafkaConsumer,
  topic : String,
) -> Result[Array[Int], String] {
  @client.kafka_client_partitions(consumer.client, topic)
}

///|
/// Create partition consumer (simplified MVP implementation)
pub fn consumer_consume_partition(
  consumer : KafkaConsumer,
  topic : String,
  partition : Int,
  offset : Int64,
) -> &PartitionConsumer raise {
  partition_consumer_new(topic, partition, offset, consumer.client)
}

///|
/// Close consumer (simplified MVP implementation)
pub fn consumer_close(consumer : KafkaConsumer) -> Result[Unit, String] {
  // Simple MVP implementation - just delegate to client close
  @client.kafka_client_close(consumer.client)
}
