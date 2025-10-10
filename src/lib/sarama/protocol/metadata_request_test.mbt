///|
// Test data for different versions of metadata requests

///|
// Version 0 test data - non-nullable array of topic names
let metadata_request_no_topics_v0 : Bytes = b"\x00\x00\x00\x00"

///|
let metadata_request_one_topic_v0 : Bytes = b"\x00\x00\x00\x01\x00\x06topic1"

///|
let metadata_request_three_topics_v0 : Bytes = b"\x00\x00\x00\x03\x00\x03foo\x00\x03bar\x00\x03baz"

///|
// Version 1 test data - same as v0 but array is nullable
let metadata_request_no_topics_v1 : Bytes = b"\xff\xff\xff\xff"

///|
let metadata_request_one_topic_v1 : Bytes = metadata_request_one_topic_v0

///|
let metadata_request_three_topics_v1 : Bytes = metadata_request_three_topics_v0

///|
// Version 2 test data - same as v1
let metadata_request_no_topics_v2 : Bytes = metadata_request_no_topics_v1

///|
let metadata_request_one_topic_v2 : Bytes = metadata_request_one_topic_v1

///|
let metadata_request_three_topics_v2 : Bytes = metadata_request_three_topics_v1

///|
// Version 3 test data - same as v1 and v2
let metadata_request_no_topics_v3 : Bytes = metadata_request_no_topics_v2

///|
let metadata_request_one_topic_v3 : Bytes = metadata_request_one_topic_v2

///|
let metadata_request_three_topics_v3 : Bytes = metadata_request_three_topics_v2

///|
// Version 4 test data - adds allow_auto_topic_creation field
let metadata_request_no_topics_v4 : Bytes = metadata_request_no_topics_v1 +
  b"\x00"

///|
let metadata_request_auto_create_v4 : Bytes = metadata_request_one_topic_v3 +
  b"\x01"

///|
let metadata_request_no_auto_create_v4 : Bytes = metadata_request_one_topic_v3 +
  b"\x00"

///|
// Version 5 test data - same as v4
let metadata_request_no_topics_v5 : Bytes = metadata_request_no_topics_v4

///|
let metadata_request_auto_create_v5 : Bytes = metadata_request_auto_create_v4

///|
let metadata_request_no_auto_create_v5 : Bytes = metadata_request_no_auto_create_v4

///|
// Version 6 test data - same as v5
let metadata_request_no_topics_v6 : Bytes = metadata_request_no_topics_v5

///|
let metadata_request_auto_create_v6 : Bytes = metadata_request_auto_create_v5

///|
let metadata_request_no_auto_create_v6 : Bytes = metadata_request_no_auto_create_v5

///|
// Version 7 test data - same as v6
let metadata_request_no_topics_v7 : Bytes = metadata_request_no_topics_v6

///|
let metadata_request_auto_create_v7 : Bytes = metadata_request_auto_create_v6

///|
let metadata_request_no_auto_create_v7 : Bytes = metadata_request_no_auto_create_v6

///|
// Version 8 test data - adds authorization fields
let metadata_request_no_topics_v8 : Bytes = metadata_request_no_topics_v7 +
  b"\x00\x00"

///|
let metadata_request_auto_create_v8 : Bytes = metadata_request_auto_create_v7 +
  b"\x00\x00"

///|
let metadata_request_no_auto_create_v8 : Bytes = metadata_request_no_auto_create_v7 +
  b"\x00\x00"

///|
let metadata_request_auto_create_cluster_auth_topic_auth_v8 : Bytes = metadata_request_auto_create_v7 +
  b"\x01\x01"

///|
// Version 9 test data - uses compact arrays and tagged fields
let metadata_request_no_topics_v9 : Bytes = b"\x00\x00\x00\x00\x00"

///|
let metadata_request_one_topic_v9 : Bytes = b"\x02\x07topic1\x00\x00\x00\x00\x00"

///|
let metadata_request_one_topic_auto_create_topic_v9 : Bytes = b"\x02\x07topic1\x00\x01\x00\x01\x00"

///|
// Version 10 test data - adds UUID support and nullable topic names
let metadata_request_no_topics_v10 : Bytes = metadata_request_no_topics_v9

///|
let metadata_request_two_topics_v10 : Bytes = b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07topic1" +
  b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07topic2\x00\x00\x00\x00\x00"

///|
let metadata_request_auto_create_cluster_auth_topic_auth_v10 : Bytes = b"\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07topic1" +
  b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x07topic2\x00\x01\x01\x01\x00"

///|
// Test functions for each version

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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1"))
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
  @json.inspect(packet_three_topics[body_offset_three_topics:].to_bytes(), content=("\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1"))
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
  @json.inspect(packet_three_topics[body_offset_three_topics:].to_bytes(), content=("\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1"))
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
  @json.inspect(packet_three_topics[body_offset_three_topics:].to_bytes(), content=("\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1"))
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
  @json.inspect(packet_three_topics[body_offset_three_topics:].to_bytes(), content=("\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01"))
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
  @json.inspect(packet_no_auto_create[body_offset_no_auto_create:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01"))
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
  @json.inspect(packet_no_auto_create[body_offset_no_auto_create:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01"))
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
  @json.inspect(packet_no_auto_create[body_offset_no_auto_create:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01"))
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
  @json.inspect(packet_no_auto_create[body_offset_no_auto_create:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01\\x00\\x00"))
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
  @json.inspect(packet_no_auto_create[body_offset_no_auto_create:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00\\x00\\x00"))
  test_request_decode(request_no_auto_create, packet_no_auto_create)
  let request_auth = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: true,
    include_topic_authorized_operations: true,
  }
  let (packet_auth, body_offset_auth) = encode_test_request(request_auth)
  @json.inspect(packet_auth[body_offset_auth:].to_bytes(), content=("\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01\\x01\\x01"))
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
  @json.inspect(packet_one_topic[body_offset_one_topic:].to_bytes(), content=("\\x02\\x07topic1\\x00\\x00\\x00\\x00\\x00"))
  test_request_decode(request_one_topic, packet_one_topic)
  let request_auth = MetadataRequest::{
    version: 9,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: true,
  }
  let (packet_auth, body_offset_auth) = encode_test_request(request_auth)
  @json.inspect(packet_auth[body_offset_auth:].to_bytes(), content=("\\x02\\x07topic1\\x00\\x01\\x00\\x01\\x00"))
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
  @json.inspect(packet_two_topics[body_offset_two_topics:].to_bytes(), content=("\\x03\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic1\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic2\\x00\\x00\\x00\\x00\\x00"))
  test_request_decode(request_two_topics, packet_two_topics)
  let request_auth = MetadataRequest::{
    version: 10,
    topics: ["topic1", "topic2"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: true,
    include_topic_authorized_operations: true,
  }
  let (packet_auth, body_offset_auth) = encode_test_request(request_auth)
  @json.inspect(packet_auth[body_offset_auth:].to_bytes(), content=("\\x03\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic1\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic2\\x00\\x01\\x01\\x01\\x00"))
  test_request_decode(request_auth, packet_auth)
}
