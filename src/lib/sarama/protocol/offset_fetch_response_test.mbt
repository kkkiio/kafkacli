///|
test "OffsetFetchResponse v7 roundtrip with partition data" {
  let partitions = [
    @protocol.OffsetFetchResponsePartition::{
      partition_index: 0,
      committed_offset: 42L,
      committed_leader_epoch: 3,
      metadata: Some(""),
      error_code: @protocol.ErrNoError,
    },
  ]
  let response = @protocol.OffsetFetchResponse::with_version(7)
  response.throttle_time_ms = 5
  response.error_code = @protocol.ErrNoError
  response.add_topic(@protocol.OffsetFetchResponseTopic::{ name: "users", partitions })
  let encoded = @protocol.encode(response)
  let decoded = @protocol.versioned_decode(
    encoded,
    OffsetFetchResponse::decode,
    7,
  )
  @json.inspect(decoded, content=({"version":7,"throttle_time_ms":5,"topics":[{"name":"users","partitions":[{"partition_index":0,"committed_offset":"42","committed_leader_epoch":3,"metadata":"","error_code":0}]}],"error_code":0}))
}

///|
test "OffsetFetchResponse v2 roundtrip without throttle" {
  let partitions = [
    @protocol.OffsetFetchResponsePartition::{
      partition_index: 1,
      committed_offset: 100L,
      committed_leader_epoch: -1,
      metadata: None,
      error_code: @protocol.ErrOffsetOutOfRange,
    },
  ]
  let response = @protocol.OffsetFetchResponse::with_version(2)
  response.add_topic(@protocol.OffsetFetchResponseTopic::{
    name: "orders",
    partitions,
  })
  let encoded = @protocol.encode(response)
  let decoded = @protocol.versioned_decode(
    encoded,
    OffsetFetchResponse::decode,
    2,
  )
  @json.inspect(decoded, content=({"version":2,"throttle_time_ms":0,"topics":[{"name":"orders","partitions":[{"partition_index":1,"committed_offset":"100","committed_leader_epoch":-1,"error_code":1}]}],"error_code":0}))
}
