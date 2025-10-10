///|
/// Metadata response tests - translated from Go sarama
/// Tests for Kafka metadata response encoding and decoding
test "Test basic empty metadata response V0" {
  let empty_response_v0 : Bytes = b"\x00\x00\x00\x00\x00\x00\x00\x00"
  let response = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  let decoded = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  test_response(response, empty_response_v0, decoded)

  // Verify the decoded response
  inspect(decoded.brokers.length(), content="0")
  inspect(decoded.topics.length(), content="0")
  inspect(decoded.throttle_time_ms, content="0")
}

///|
test "Test metadata response with brokers V0" {
  let brokers_response_v0 : Bytes = [
    0x00, 0x00, 0x00, 0x02, // broker array length (2)

    // Broker 1
     0x00, 0x00, 0xab, 0xff, // node_id (44031)
     0x00, 0x09, // host length (9)
     0x6c, 0x6f, 0x63, 0x61, 0x6c, 0x68, 0x6f, 0x73, 0x74, // "localhost"
     0x00, 0x00, 0x00, 0x33, // port (51)

    // Broker 2
     0x00, 0x01, 0x02, 0x03, // node_id (66051)
     0x00, 0x0a, // host length (10)
     0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, // "google.com"
     0x00, 0x00, 0x01, 0x11, // port (273)
     0x00, 0x00, 0x00, 0x00, // topic array length (0)
  ]
  let response = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: [
      BrokerMetadata::{
        id: 44031,
        host: "localhost",
        port: 51,
        rack: None,
        version: 0,
      },
      BrokerMetadata::{
        id: 66051,
        host: "google.com",
        port: 273,
        rack: None,
        version: 0,
      },
    ],
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  let decoded = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  test_response(response, brokers_response_v0, decoded)

  // Verify the decoded response
  inspect(decoded.brokers.length(), content="2")
  inspect(decoded.topics.length(), content="0")
  inspect(decoded.brokers[0].id, content="44031")
  inspect(decoded.brokers[0].host, content="localhost")
  inspect(decoded.brokers[0].port, content="51")
  inspect(decoded.brokers[1].id, content="66051")
  inspect(decoded.brokers[1].host, content="google.com")
  inspect(decoded.brokers[1].port, content="273")
}

///|
test "Test metadata response with topics V0" {
  let topics_response_v0 : Bytes = [
    0x00, 0x00, 0x00, 0x00, // broker array length (0)
     0x00, 0x00, 0x00, 0x02, // topic array length (2)

    // Topic 1: "foo"
     0x00, 0x00, // error code (0)
     0x00, 0x03, // topic name length (3)
     0x66, 0x6f, 0x6f, // "foo"
     0x00, 0x00, 0x00, 0x01, // partition array length (1)
     0x00, 0x04, // partition error (4 - ErrInvalidMessageSize)
     0x00, 0x00, 0x00, 0x01, // partition id (1)
     0x00, 0x00, 0x00, 0x07, // partition leader (7)
     0x00, 0x00, 0x00, 0x03, // replicas array length (3)
     0x00, 0x00, 0x00, 0x01, // replica 1
     0x00, 0x00, 0x00, 0x02, // replica 2
     0x00, 0x00, 0x00, 0x03, // replica 3
     0x00, 0x00, 0x00, 0x00, // isr array length (0)

    // Topic 2: "bar" (no partitions)
     0x00, 0x00, // error code (0)
     0x00, 0x03, // topic name length (3)
     0x62, 0x61, 0x72, // "bar"
     0x00, 0x00, 0x00, 0x00, // partition array length (0)
  ]
  let response = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: [
      TopicMetadata::{
        version: 0,
        err: KError(0),
        name: "foo",
        uuid: null_uuid,
        is_internal: false,
        partitions: [
          PartitionMetadata::{
            version: 0,
            err: KError(4),
            id: 1,
            leader: 7,
            leader_epoch: 0,
            replicas: [1, 2, 3],
            isr: Array::new(),
            offline_replicas: Array::new(),
          },
        ],
        topic_authorized_operations: 0,
      },
      TopicMetadata::{
        version: 0,
        err: KError(0),
        name: "bar",
        uuid: null_uuid,
        is_internal: false,
        partitions: Array::new(),
        topic_authorized_operations: 0,
      },
    ],
    cluster_authorized_operations: 0,
  }
  let encoded = encode(response)
  let decoded = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  let expected = topics_response_v0
  assert_eq(encoded, expected)
  versioned_decode(encoded, decoded, response.version())
  assert_eq(decoded, response)

  // Verify the decoded response
  inspect(decoded.brokers.length(), content="0")
  inspect(decoded.topics.length(), content="2")

  // Verify topic 1
  inspect(decoded.topics[0].name, content="foo")
  inspect(decoded.topics[0].err.int_value(), content="0")
  inspect(decoded.topics[0].partitions.length(), content="1")
  inspect(decoded.topics[0].partitions[0].id, content="1")
  inspect(decoded.topics[0].partitions[0].leader, content="7")
  inspect(decoded.topics[0].partitions[0].replicas.length(), content="3")
  inspect(decoded.topics[0].partitions[0].replicas, content="[1, 2, 3]")

  // Verify topic 2
  inspect(decoded.topics[1].name, content="bar")
  inspect(decoded.topics[1].partitions.length(), content="0")
}

///|
test "Test metadata response with rack information V1" {
  let rack_response_v1 : Bytes = [
    0x00, 0x00, 0x00, 0x02, // broker array length (2)

    // Broker 1 with rack
     0x00, 0x00, 0xab, 0xff, // node_id (44031)
     0x00, 0x09, // host length (9)
     0x6c, 0x6f, 0x63, 0x61, 0x6c, 0x68, 0x6f, 0x73, 0x74, // "localhost"
     0x00, 0x00, 0x00, 0x33, // port (51)
     0x00, 0x05, // rack length (5)
     0x72, 0x61, 0x63, 0x6b, 0x30, // "rack0"

    // Broker 2 with rack
     0x00, 0x01, 0x02, 0x03, // node_id (66051)
     0x00, 0x0a, // host length (10)
     0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, // "google.com"
     0x00, 0x00, 0x01, 0x11, // port (273)
     0x00, 0x05, // rack length (5)
     0x72, 0x61, 0x63, 0x6b, 0x31, // "rack1"
     0x00, 0x00, 0x00, 0x01, // controller_id (1)
     0x00, 0x00, 0x00, 0x00, // topic array length (0)
  ]
  let response = MetadataResponse::{
    version: 1,
    throttle_time_ms: 0,
    brokers: [
      BrokerMetadata::{
        id: 44031,
        host: "localhost",
        port: 51,
        rack: Some("rack0"),
        version: 1,
      },
      BrokerMetadata::{
        id: 66051,
        host: "google.com",
        port: 273,
        rack: Some("rack1"),
        version: 1,
      },
    ],
    cluster_id: None,
    controller_id: 1,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  let decoded = MetadataResponse::{
    version: 1,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  test_response(response, rack_response_v1, decoded)

  // Verify the decoded response
  inspect(decoded.brokers.length(), content="2")
  inspect(decoded.controller_id, content="1")
  inspect(
    decoded.brokers[0].rack,
    content=(
      #|Some("rack0")
    ),
  )
  inspect(
    decoded.brokers[1].rack,
    content=(
      #|Some("rack1")
    ),
  )
}

///|
test "Test complete metadata response round trip" {
  let response = MetadataResponse::{
    version: 8,
    throttle_time_ms: 100,
    brokers: [
      BrokerMetadata::{
        id: 1,
        host: "broker1.example.com",
        port: 9092,
        rack: Some("rack1"),
        version: 8,
      },
      BrokerMetadata::{
        id: 2,
        host: "broker2.example.com",
        port: 9093,
        rack: None,
        version: 8,
      },
    ],
    cluster_id: Some("test-cluster"),
    controller_id: 1,
    topics: Array::new(),
    cluster_authorized_operations: 123,
  }

  // Encode response
  let encoded = encode(response)

  // Decode response
  let decoded_response = MetadataResponse::{
    version: 0,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    controller_id: 0,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  versioned_decode(encoded, decoded_response, 8)

  // Verify round trip
  inspect(decoded_response.version, content="8")
  inspect(decoded_response.throttle_time_ms, content="100")
  inspect(decoded_response.brokers.length(), content="2")
  inspect(
    decoded_response.cluster_id,
    content=(
      #|Some("test-cluster")
    ),
  )
  inspect(decoded_response.controller_id, content="1")
  inspect(decoded_response.cluster_authorized_operations, content="123")

  // Verify broker details
  inspect(decoded_response.brokers[0].id, content="1")
  inspect(decoded_response.brokers[0].host, content="broker1.example.com")
  inspect(decoded_response.brokers[0].port, content="9092")
  inspect(
    decoded_response.brokers[0].rack,
    content=(
      #|Some("rack1")
    ),
  )
}
