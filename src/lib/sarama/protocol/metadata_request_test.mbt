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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\x00\\x00\\x00\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 0,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_three_topics = MetadataRequest::{
    version: 0,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_three_topics = encode_only_body(request_three_topics)
  @json.inspect(
    packet_three_topics,
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  let decoded_three : MetadataRequest = decode_only_body(
    packet_three_topics,
    request_three_topics.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_three_topics.to_json(), decoded_three.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 1,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_three_topics = MetadataRequest::{
    version: 1,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_three_topics = encode_only_body(request_three_topics)
  @json.inspect(
    packet_three_topics,
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  let decoded_three : MetadataRequest = decode_only_body(
    packet_three_topics,
    request_three_topics.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_three_topics.to_json(), decoded_three.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 2,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_three_topics = MetadataRequest::{
    version: 2,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_three_topics = encode_only_body(request_three_topics)
  @json.inspect(
    packet_three_topics,
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  let decoded_three : MetadataRequest = decode_only_body(
    packet_three_topics,
    request_three_topics.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_three_topics.to_json(), decoded_three.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 3,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_three_topics = MetadataRequest::{
    version: 3,
    topics: ["foo", "bar", "baz"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_three_topics = encode_only_body(request_three_topics)
  @json.inspect(
    packet_three_topics,
    content="\\x00\\x00\\x00\\x03\\x00\\x03foo\\x00\\x03bar\\x00\\x03baz",
  )
  let decoded_three : MetadataRequest = decode_only_body(
    packet_three_topics,
    request_three_topics.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_three_topics.to_json(), decoded_three.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 4,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_no_auto_create = MetadataRequest::{
    version: 4,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_no_auto_create = encode_only_body(request_no_auto_create)
  @json.inspect(
    packet_no_auto_create,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  let decoded_no_auto : MetadataRequest = decode_only_body(
    packet_no_auto_create,
    request_no_auto_create.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_no_auto_create.to_json(), decoded_no_auto.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 5,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_no_auto_create = MetadataRequest::{
    version: 5,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_no_auto_create = encode_only_body(request_no_auto_create)
  @json.inspect(
    packet_no_auto_create,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  let decoded_no_auto : MetadataRequest = decode_only_body(
    packet_no_auto_create,
    request_no_auto_create.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_no_auto_create.to_json(), decoded_no_auto.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 6,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_no_auto_create = MetadataRequest::{
    version: 6,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_no_auto_create = encode_only_body(request_no_auto_create)
  @json.inspect(
    packet_no_auto_create,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  let decoded_no_auto : MetadataRequest = decode_only_body(
    packet_no_auto_create,
    request_no_auto_create.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_no_auto_create.to_json(), decoded_no_auto.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 7,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_no_auto_create = MetadataRequest::{
    version: 7,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_no_auto_create = encode_only_body(request_no_auto_create)
  @json.inspect(
    packet_no_auto_create,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00",
  )
  let decoded_no_auto : MetadataRequest = decode_only_body(
    packet_no_auto_create,
    request_no_auto_create.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_no_auto_create.to_json(), decoded_no_auto.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\xff\\xff\\xff\\xff\\x00\\x00\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01\\x00\\x00",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_no_auto_create = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_no_auto_create = encode_only_body(request_no_auto_create)
  @json.inspect(
    packet_no_auto_create,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x00\\x00\\x00",
  )
  let decoded_no_auto : MetadataRequest = decode_only_body(
    packet_no_auto_create,
    request_no_auto_create.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_no_auto_create.to_json(), decoded_no_auto.to_json())
  let request_auth = MetadataRequest::{
    version: 8,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: true,
    include_topic_authorized_operations: true,
  }
  let packet_auth = encode_only_body(request_auth)
  @json.inspect(
    packet_auth,
    content="\\x00\\x00\\x00\\x01\\x00\\x06topic1\\x01\\x01\\x01",
  )
  let decoded_auth : MetadataRequest = decode_only_body(
    packet_auth,
    request_auth.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_auth.to_json(), decoded_auth.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\x00\\x00\\x00\\x00\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_one_topic = MetadataRequest::{
    version: 9,
    topics: ["topic1"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_one_topic = encode_only_body(request_one_topic)
  @json.inspect(
    packet_one_topic,
    content="\\x02\\x07topic1\\x00\\x00\\x00\\x00\\x00",
  )
  let decoded_one : MetadataRequest = decode_only_body(
    packet_one_topic,
    request_one_topic.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_one_topic.to_json(), decoded_one.to_json())
  let request_auth = MetadataRequest::{
    version: 9,
    topics: ["topic1"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: true,
  }
  let packet_auth = encode_only_body(request_auth)
  @json.inspect(
    packet_auth,
    content="\\x02\\x07topic1\\x00\\x01\\x00\\x01\\x00",
  )
  let decoded_auth : MetadataRequest = decode_only_body(
    packet_auth,
    request_auth.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_auth.to_json(), decoded_auth.to_json())
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
  let bytes = encode_only_body(request)
  @json.inspect(bytes, content="\\x00\\x00\\x00\\x00\\x00")
  let decoded : MetadataRequest = decode_only_body(
    bytes,
    request.version(),
    MetadataRequest::decode,
  )
  assert_eq(request.to_json(), decoded.to_json())
  let request_two_topics = MetadataRequest::{
    version: 10,
    topics: ["topic1", "topic2"],
    allow_auto_topic_creation: false,
    include_cluster_authorized_operations: false,
    include_topic_authorized_operations: false,
  }
  let packet_two_topics = encode_only_body(request_two_topics)
  @json.inspect(
    packet_two_topics,
    content="\\x03\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic1\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic2\\x00\\x00\\x00\\x00\\x00",
  )
  let decoded_two : MetadataRequest = decode_only_body(
    packet_two_topics,
    request_two_topics.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_two_topics.to_json(), decoded_two.to_json())
  let request_auth = MetadataRequest::{
    version: 10,
    topics: ["topic1", "topic2"],
    allow_auto_topic_creation: true,
    include_cluster_authorized_operations: true,
    include_topic_authorized_operations: true,
  }
  let packet_auth = encode_only_body(request_auth)
  @json.inspect(
    packet_auth,
    content="\\x03\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic1\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x07topic2\\x00\\x01\\x01\\x01\\x00",
  )
  let decoded_auth : MetadataRequest = decode_only_body(
    packet_auth,
    request_auth.version(),
    MetadataRequest::decode,
  )
  assert_eq(request_auth.to_json(), decoded_auth.to_json())
}
