///|
test "OffsetFetchRequest v7 encode/decode with all topics" {
  let request = @protocol.OffsetFetchRequest::default("analytics")
  request.set_require_stable(true)
  let encoded = @protocol.encode(request)
  let decoded = @protocol.versioned_decode(
    encoded,
    OffsetFetchRequest::decode,
    7,
  )
  @json.inspect(decoded, content=({"version":7,"group_id":"analytics","require_stable":true}))
}

///|
test "OffsetFetchRequest v5 encode/decode with specific partitions" {
  let topic = @protocol.OffsetFetchRequestTopic::{
    name: "users",
    partition_indexes: [0, 1],
  }
  let request = @protocol.OffsetFetchRequest::new(5, "analytics")
  request.set_topics(Some([topic]))
  let encoded = @protocol.encode(request)
  let decoded = @protocol.versioned_decode(
    encoded,
    OffsetFetchRequest::decode,
    5,
  )
  @json.inspect(decoded, content={
    "version": 5,
    "group_id": "analytics",
    "topics": [
      { "name": "users", "partition_indexes": [0, 1] },
    ],
    "require_stable": false,
  })
}
