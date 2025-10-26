///|
const TestMsg : String = "Foo"

///|
const TestKey : String = "Bar"

///|
/// If a particular offset is provided then messages are consumed starting from
/// that offset.
#skip
async test "TestConsumerOffsetManual" {
  // Given
  let broker0 = @client.MockBroker::new(0)
  let manualOffset = 1234L
  let offsetNewest = 2345L
  let offsetNewestAfterFetchRequest = 3456L
  let mockFetchResponse = @client.MockFetchResponse::new(1)

  // skipped because parseRecords(): offset < child.offset
  mockFetchResponse.set_message("my_topic", 0, manualOffset - 1, TestMsg)
  for i in 0..<10 {
    mockFetchResponse.set_message(
      "my_topic",
      0,
      i.to_int64() + manualOffset,
      TestMsg,
    )
  }
  mockFetchResponse.set_high_water_mark(
    "my_topic", 0, offsetNewestAfterFetchRequest,
  )
  broker0.set_handler_by_map({
    "MetadataRequest": @client.MockMetadataResponse::new()
    ..set_broker(broker0.addr(), broker0.broker_id())
    ..set_leader("my_topic", 0, broker0.broker_id())
    .for_request(_),
    "OffsetRequest": @client.MockOffsetResponse::new()
    ..set_offset("my_topic", 0, @client.OffsetOldest, 0)
    ..set_offset("my_topic", 0, @client.OffsetNewest, offsetNewest)
    .for_request(_),
    "FetchRequest": mockFetchResponse.for_request(_),
  })

  // When
  let master = KafkaConsumer::new([broker0.addr()], new_test_config())
  let consumer = master.consume_partition("my_topic", 0, manualOffset)

  // Then
  let hwmo = consumer.high_water_mark_offset()
  if hwmo != offsetNewest {
    fail("Expected high water mark offset \{offsetNewest}, found \{hwmo}")
  }
  for i in 0..<10 {
    let messages = consumer.fetch_messages()
    for msg in messages {
      // assert_message_offset(message, i + manualOffset)
      assert_eq(msg.offset, i.to_int64() + manualOffset)
    }
  }
  let hwmo = consumer.current_offset()
  if hwmo != offsetNewestAfterFetchRequest {
    fail(
      "Expected high water mark offset \{offsetNewestAfterFetchRequest}, found \{hwmo}",
    )
  }
  consumer.close()
  master.close()
  broker0.close()
}

///|
/// new_test_config returns a config meant to be used by tests.
/// Due to inconsistencies with the request versions the clients send using the default Kafka version
/// and the response versions our mocks use, we default to the minimum Kafka version in most tests
pub fn new_test_config() -> @core.Config {
  let config = @core.Config::new()
  {
    ..config,
    api_versions_request: false,
    consumer: @core.ConsumerConfig::{ ..config.consumer, retry_backoff_ms: 0 },
    producer: @core.ProducerConfig::{ ..config.producer, retry_backoff_ms: 0 },
    version: @protocol.min_version,
  }
}
