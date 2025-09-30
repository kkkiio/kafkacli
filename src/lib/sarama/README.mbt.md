# Sarama - MoonBit Kafka Client Library

Sarama is a pure MoonBit client library for dealing with Apache Kafka (versions 0.8 and later). It includes a high-level API for easily producing and consuming messages, and a low-level API for controlling bytes on the wire when the high-level API is insufficient.

## Features

- **Producers**: Both AsyncProducer and SyncProducer with transactional support
- **Consumers**: Individual partition consumers and consumer groups with offset management
- **Administration**: Full cluster administration capabilities for topics, ACLs, configurations
- **Protocol Support**: Complete Kafka protocol implementation with encoding/decoding
- **Configuration**: Flexible configuration system with sensible defaults

## Quick Start

### Creating a Producer

```moonbit
test "producer example" {
  // Create configuration with defaults
  let config = @core.Config::new()

  // Create client with broker addresses
  let client = @client.KafkaClient::new(config, ["localhost:9092"])

  // Create a sync producer
  let producer = @producer.KafkaSyncProducer::new(client)

  // Create a message
  let message = @producer.ProducerMessage::{
    topic: "test-topic",
    key: b"message-key",
    value: b"Hello, Kafka from MoonBit!",
    partition: None,
    offset: None,
    headers: [],
    timestamp: None,
    metadata: None
  }

  // Send the message
  let (partition, offset) = @producer.KafkaSyncProducer::send_message(producer, message)

  println("Message sent successfully to partition " + partition.to_string() + " at offset " + offset.to_string())
}
```

### Creating a Consumer

```moonbit

test "consumer example" {
  // Create configuration
  let config = @core.Config::new()

  // Create client
  let client = @client.KafkaClient::new(config, ["localhost:9092"])

  // Create consumer
  let consumer = @consumer.consumer_new(client)

  // Consume from partition 0 starting at the beginning
  let partition_consumer = @consumer.consumer_consume_partition(consumer, "test-topic", 0, @client.OffsetOldest)

  // Consume messages
  let message = @consumer.partition_consumer_messages(partition_consumer)
  println("Received message:")
  println("  Topic: " + message.topic)
  println("  Partition: " + message.partition.to_string())
  println("  Offset: " + message.offset.to_string())
  println("  Key: " + message.key.to_string())
  println("  Value: " + message.value.to_string())
}
```

### Cluster Administration

```moonbit
test "admin example" {
  // Create configuration
  let config = @core.Config::new()

  // Create client
  let client = @client.KafkaClient::new(config, ["localhost:9092"])

  // Create cluster admin
  let admin = @admin.KafkaClusterAdmin::new(client)

  // Create a new topic
  let topic_detail = @admin.TopicDetail::{
    num_partitions: 3,
    replication_factor: 1,
    replica_assignment: None,
    config_entries: Some({"retention.ms": "604800000"})
  }

  @admin.cluster_admin_create_topic(admin, "new-topic", topic_detail, false)

  // List all topics
  let topics = @admin.cluster_admin_list_topics(admin)
  println("Available topics: " + topics.keys().to_string())
}
```

## Configuration

Sarama provides a flexible configuration system:

```moonbit

test "configuration example" {
  let config = @core.Config::new()

  // Configure network settings
  let net_config = @core.NetConfig::default()
  let updated_net_config = { ..net_config,
    max_open_requests: 10,
    dial_timeout_ms: 10000,
    read_timeout_ms: 30000,
    write_timeout_ms: 30000
  }

  // Configure producer settings
  let producer_config = @core.ProducerConfig::default()
  let updated_producer_config = {
    ..producer_config,
    required_acks: @protocol.RequiredAcks::WaitForAll,
    retries: 3,
    idempotent: true
  }

  // Update main config
  let updated_config = { ..config,
    client_id: "my-app",
    net: updated_net_config,
    producer: updated_producer_config
  }

  // Use the configuration
  let client = @client.KafkaClient::new(updated_config, ["localhost:9092"])
}
```

## API Reference

### Core Types

- `Config`: Main configuration structure
- `Message`: Kafka message structure
- `ConsumerMessage`: Consumer message with metadata
- `CompressionCodec`: Supported compression algorithms
- `SaramaError`: Library-specific error types

### Client

- `Client`: High-level client interface
- `Broker`: Individual broker connection
- `KafkaClient`: Client implementation
- Functions for metadata management, broker discovery, etc.

### Producer

- `AsyncProducer`: Non-blocking producer interface
- `SyncProducer`: Blocking producer interface
- `ProducerMessage`: Message structure for production
- Transactional support with `begin_txn()`, `commit_txn()`, `abort_txn()`

### Consumer

- `Consumer`: High-level consumer interface
- `PartitionConsumer`: Individual partition consumer
- `ConsumerMessage`: Consumed message structure
- Offset management and pause/resume functionality

### Administration

- `ClusterAdmin`: Cluster administration interface
- Functions for topic management, ACL operations, configuration management
- Support for all major administrative operations

### Protocol

- Complete Kafka protocol implementation
- Request/Response types for all API calls
- Encoding/decoding utilities
