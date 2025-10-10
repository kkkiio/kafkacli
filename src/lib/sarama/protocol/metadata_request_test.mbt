/// Test functions for each version

///|
test "TestMetadataRequestV0" {
  let request = MetadataRequest::{
    version: 0,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content="\\x00\\x00\\x00\\x00")
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 0,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_three_topics = MetadataRequest::{
    version: 0,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_three_topics, body_offset_three_topics) = encode_test_request(
    request_three_topics,
  )
  @json.inspect(
    packet_three_topics[body_offset_three_topics:].to_bytes(),
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  test_request_decode(request_three_topics, packet_three_topics)
}

///|
test "TestMetadataRequestV1" {
  let request = MetadataRequest::{
    version: 1,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content="\\xff\\xff\\xff\\xff")
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 1,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_three_topics = MetadataRequest::{
    version: 1,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_three_topics, body_offset_three_topics) = encode_test_request(
    request_three_topics,
  )
  @json.inspect(
    packet_three_topics[body_offset_three_topics:].to_bytes(),
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  test_request_decode(request_three_topics, packet_three_topics)
}

///|
test "TestMetadataRequestV2" {
  let request = MetadataRequest::{
    version: 2,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content="\\xff\\xff\\xff\\xff")
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 2,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_three_topics = MetadataRequest::{
    version: 2,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_three_topics, body_offset_three_topics) = encode_test_request(
    request_three_topics,
  )
  @json.inspect(
    packet_three_topics[body_offset_three_topics:].to_bytes(),
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  test_request_decode(request_three_topics, packet_three_topics)
}

///|
test "TestMetadataRequestV3" {
  let request = MetadataRequest::{
    version: 3,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(packet[body_offset:].to_bytes(), content="\\xff\\xff\\xff\\xff")
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 3,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_three_topics = MetadataRequest::{
    version: 3,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_three_topics, body_offset_three_topics) = encode_test_request(
    request_three_topics,
  )
  @json.inspect(
    packet_three_topics[body_offset_three_topics:].to_bytes(),
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  test_request_decode(request_three_topics, packet_three_topics)
}

///|
test "TestMetadataRequestV4" {
  let request = MetadataRequest::{
    version: 4,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\xff\\xff\\xff\\xff\\x00",
  )
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 4,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_no_auto_create = MetadataRequest::{
    version: 4,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_no_auto_create, body_offset_no_auto_create) = encode_test_request(
    request_no_auto_create,
  )
  @json.inspect(
    packet_no_auto_create[body_offset_no_auto_create:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  test_request_decode(request_no_auto_create, packet_no_auto_create)
}

///|
test "TestMetadataRequestV5" {
  let request = MetadataRequest::{
    version: 5,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\xff\\xff\\xff\\xff\\x00",
  )
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 5,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_no_auto_create = MetadataRequest::{
    version: 5,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_no_auto_create, body_offset_no_auto_create) = encode_test_request(
    request_no_auto_create,
  )
  @json.inspect(
    packet_no_auto_create[body_offset_no_auto_create:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  test_request_decode(request_no_auto_create, packet_no_auto_create)
}

///|
test "TestMetadataRequestV6" {
  let request = MetadataRequest::{
    version: 6,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\xff\\xff\\xff\\xff\\x00",
  )
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 6,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_no_auto_create = MetadataRequest::{
    version: 6,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_no_auto_create, body_offset_no_auto_create) = encode_test_request(
    request_no_auto_create,
  )
  @json.inspect(
    packet_no_auto_create[body_offset_no_auto_create:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  test_request_decode(request_no_auto_create, packet_no_auto_create)
}

///|
test "TestMetadataRequestV7" {
  let request = MetadataRequest::{
    version: 7,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\xff\\xff\\xff\\xff\\x00",
  )
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 7,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_no_auto_create = MetadataRequest::{
    version: 7,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_no_auto_create, body_offset_no_auto_create) = encode_test_request(
    request_no_auto_create,
  )
  @json.inspect(
    packet_no_auto_create[body_offset_no_auto_create:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  test_request_decode(request_no_auto_create, packet_no_auto_create)
}

///|
test "TestMetadataRequestV8" {
  let request = MetadataRequest::{
    version: 8,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00",
  )
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01\\x00\\x00",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_no_auto_create = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_no_auto_create, body_offset_no_auto_create) = encode_test_request(
    request_no_auto_create,
  )
  @json.inspect(
    packet_no_auto_create[body_offset_no_auto_create:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00\\x00\\x00",
  )
  test_request_decode(request_no_auto_create, packet_no_auto_create)
  let request_auth = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: true,
    include_topic_authorized_operations: true,
  }
  let (packet_auth, body_offset_auth) = encode_test_request(request_auth)
  @json.inspect(
    packet_auth[body_offset_auth:].to_bytes(),
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01\\x01\\x01",
  )
  test_request_decode(request_auth, packet_auth)
}

///|
test "TestMetadataRequestV9" {
  let request = MetadataRequest::{
    version: 9,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\x00\\x00\\x00\\x00\\x00",
  )
  test_request_decode(request, packet)
  let request_one_topic = MetadataRequest::{
    version: 9,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_one_topic, body_offset_one_topic) = encode_test_request(
    request_one_topic,
  )
  @json.inspect(
    packet_one_topic[body_offset_one_topic:].to_bytes(),
    content="\\x02\\x07topic1\\x00\\x00\\x00\\x00\\x00",
  )
  test_request_decode(request_one_topic, packet_one_topic)
  let request_auth = MetadataRequest::{
    version: 9,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: true,
  }
  let (packet_auth, body_offset_auth) = encode_test_request(request_auth)
  @json.inspect(
    packet_auth[body_offset_auth:].to_bytes(),
    content="\\x02\\x07topic1\\x00\\x01\\x00\\x01\\x00",
  )
  test_request_decode(request_auth, packet_auth)
}

///|
test "TestMetadataRequestV10" {
  let request = MetadataRequest::{
    version: 10,
    topics: [],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet, body_offset) = encode_test_request(request)
  @json.inspect(
    packet[body_offset:].to_bytes(),
    content="\\x00\\x00\\x00\\x00\\x00",
  )
  test_request_decode(request, packet)
  let request_two_topics = MetadataRequest::{
    version: 10,
    topics: ["topic1", "topic2"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let (packet_two_topics, body_offset_two_topics) = encode_test_request(
    request_two_topics,
  )
  @json.inspect(
    packet_two_topics[body_offset_two_topics:].to_bytes(),
    content="\\x03\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic1\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic2\\x00\\x00\\x00\\x00\\x00",
  )
  test_request_decode(request_two_topics, packet_two_topics)
  let request_auth = MetadataRequest::{
    version: 10,
    topics: ["topic1", "topic2"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: true,
    include_topic_authorized_operations: true,
  }
  let (packet_auth, body_offset_auth) = encode_test_request(request_auth)
  @json.inspect(
    packet_auth[body_offset_auth:].to_bytes(),
    content="\\x03\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic1\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic2\\x00\\x01\\x01\\x01\\x00",
  )
  test_request_decode(request_auth, packet_auth)
}
