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
