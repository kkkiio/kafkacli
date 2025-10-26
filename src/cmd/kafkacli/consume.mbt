///|
priv suberror ConsumeError {
  ClientCreationFailed(errstr~ : String)
  SubscriptionFailed(errstr~ : String)
  MessageError(errstr~ : String)
} derive(Show)

///|
/// consume messages from kafka
pub fn consume(
  broker : String,
  topics : Array[String],
  group : String,
  offset : @core.OffsetReset,
  debug? : Bool = false,
) -> Unit raise {
  ...
  // // Create configuration reference
  // let config = @core.Config::{
  //   ..@core.Config::new(),
  //   consumer: @core.ConsumerConfig::{
  //     ..@core.ConsumerConfig::default(),
  //     group_id: Some(group),
  //     offset_reset: offset,
  //   },
  // }
  // // Create consumer instance
  // let client = @client.KafkaClient::new(config, [broker])
  // // Create topic partition list and add topic
  // // TODO: support multiple topics
  // guard topics is [topic] else { fail("only support one topic for now") }
  // // Create consumer
  // let consumer = @consumer.consumer_new(client)
  // // TODO: support consumer group
  // let partition_consumer = @consumer.consumer_consume_partition(
  //   consumer,
  //   topic,
  //   0,
  //   @client.OffsetOldest,
  // )
  // // Message consumption loop
  // while true {
  //   let msg = @consumer.partition_consumer_messages(partition_consumer)
  //   let partition = msg.partition
  //   let offset = msg.offset
  //   let bytes = msg.value
  //   let str = @encoding/utf8.decode_lossy(bytes)
  //   let json_data = @json.parse(str) catch {
  //     e => fail("Failed to parse JSON: \{e}, str=\{str}")
  //   }
  //   let full : Json = {
  //     "topic": topic.to_string(),
  //     "partition": partition,
  //     "offset": offset,
  //     "data": json_data,
  //   }
  //   println(full.stringify(indent=2))
  //   // print_nl_flush(bytes)
  // }
}

///|
/// Consume messages from a specific partition.
///
/// 会自动解析最新的 leader broker.
pub async fn consume_partition(
  logger : @pino.Logger,
  bootstrap_servers : Array[String],
  topic : String,
  partition : Int,
  offset : Int64,
) -> Unit {
  logger.debug("Starting partition consumer", {
    "topic": topic.to_json(),
    "partition": partition.to_json(),
    "offset": offset.to_json(),
    "bootstrap_servers": bootstrap_servers.to_json(),
  })

  // Create client configuration
  let config = @core.Config::new()

  // Create consumer
  let consumer = @consumer.KafkaConsumer::new(bootstrap_servers, config)

  // Create partition consumer
  let partition_consumer = consumer.consume_partition(topic, partition, offset)
  // Fetch messages
  let messages = partition_consumer.fetch_messages()
  for msg in messages {
    println(msg.to_json().stringify(indent=2))
  }
  let next_offset = partition_consumer.current_offset()
  // TODO: loop until signal is received
  ignore(next_offset)
  // Close partition consumer
  partition_consumer.close()

  // Close consumer
  consumer.close()
}
