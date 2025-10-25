///|
test "ListGroupsResponse v0 - empty groups" {
  let response = @protocol.ListGroupsResponse::with_version(0)
  let encoded = @protocol.encode(response)
  inspect(
    encoded,
    content=(
      #|b"\x00\x00\x00\x00\x00\x00"
    ),
  ) // error code (0) + array length (0)
}

///|
test "ListGroupsResponse v0 - with error" {
  let response = @protocol.ListGroupsResponse::with_version(0)
  response.error = @protocol.ErrClusterAuthorizationFailed
  let encoded = @protocol.encode(response)
  inspect(
    encoded,
    content=(
      #|b"\x00\x1f\x00\x00\x00\x00"
    ),
  ) // error code (31) + array length (0)
}

///|
test "ListGroupsResponse v0 - with consumer group" {
  let response = @protocol.ListGroupsResponse::with_version(0)
  response.add_group("foo", "consumer")
  let encoded = @protocol.encode(response)
  inspect(
    encoded,
    content=(
      #|b"\x00\x00\x00\x00\x00\x01\x00\x03foo\x00\x08consumer"
    ),
  ) // error (0) + array length (1) + group data
}

///|
test "ListGroupsResponse v4 - with group state" {
  let response = @protocol.ListGroupsResponse::with_version(4)
  let group_data = @protocol.ListGroupsGroupData::new()
  group_data.group_state = "Empty"
  response.add_group_with_data("foo", "consumer", group_data)
  let encoded = @protocol.encode(response)
  inspect(
    encoded,
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\x02\x04foo\x09consumer\x06Empty\x00\x00"
    ),
  ) // throttle (0) + error (0) + compact array + group + state + tagged fields
}

///|
test "ListGroupsResponse v5 - with group state and type" {
  let response = @protocol.ListGroupsResponse::with_version(5)
  let group_data = @protocol.ListGroupsGroupData::new()
  group_data.group_state = "Empty"
  group_data.group_type = "Classic"
  response.add_group_with_data("foo", "consumer", group_data)
  let encoded = @protocol.encode(response)
  inspect(
    encoded,
    content=(
      #|b"\x00\x00\x00\x00\x00\x00\x02\x04foo\x09consumer\x06Empty\x08Classic\x00\x00"
    ),
  ) // throttle (0) + error (0) + compact array + group + state + type + tagged fields
}

///|
test "ListGroupsResponse roundtrip v0 empty" {
  let original = @protocol.ListGroupsResponse::with_version(0)
  let encoded = @protocol.encode(original)
  let decoded = @protocol.versioned_decode(
    encoded,
    ListGroupsResponse::decode,
    0,
  )
  @json.inspect(decoded, content={
    "version": 0,
    "throttle_time_ms": 0,
    "error": 0,
    "groups": {},
    "groups_data": {},
  })
}

///|
test "ListGroupsResponse roundtrip v0 with groups" {
  let original = @protocol.ListGroupsResponse::with_version(0)
  original.add_group("foo", "consumer")
  original.add_group("bar", "connect")
  let encoded = @protocol.encode(original)
  let decoded = @protocol.versioned_decode(
    encoded,
    ListGroupsResponse::decode,
    0,
  )
  @json.inspect(decoded, content={
    "version": 0,
    "throttle_time_ms": 0,
    "error": 0,
    "groups": { "foo": "consumer", "bar": "connect" },
    "groups_data": {},
  })
}

///|
test "ListGroupsResponse roundtrip v1 with throttle" {
  let original = @protocol.ListGroupsResponse::with_version(1)
  original.throttle_time_ms = 100
  original.add_group("test", "consumer")
  let encoded = @protocol.encode(original)
  let decoded = @protocol.versioned_decode(
    encoded,
    ListGroupsResponse::decode,
    1,
  )
  @json.inspect(decoded, content={
    "version": 1,
    "throttle_time_ms": 100,
    "error": 0,
    "groups": { "test": "consumer" },
    "groups_data": {},
  })
}

///|
test "ListGroupsResponse roundtrip v4 with extended data" {
  let original = @protocol.ListGroupsResponse::with_version(4)
  let group_data1 = @protocol.ListGroupsGroupData::new()
  group_data1.group_state = "Stable"
  let group_data2 = @protocol.ListGroupsGroupData::new()
  group_data2.group_state = "Empty"
  original.add_group_with_data("group1", "consumer", group_data1)
  original.add_group_with_data("group2", "connect", group_data2)
  let encoded = @protocol.encode(original)
  let decoded = @protocol.versioned_decode(
    encoded,
    ListGroupsResponse::decode,
    4,
  )
  @json.inspect(decoded, content={
    "version": 4,
    "throttle_time_ms": 0,
    "error": 0,
    "groups": { "group1": "consumer", "group2": "connect" },
    "groups_data": {
      "group1": { "group_state": "Stable", "group_type": "" },
      "group2": { "group_state": "Empty", "group_type": "" },
    },
  })
}

///|
test "ListGroupsResponse roundtrip v5 with full data" {
  let original = @protocol.ListGroupsResponse::with_version(5)
  let group_data = @protocol.ListGroupsGroupData::new()
  group_data.group_state = "Stable"
  group_data.group_type = "Classic"
  original.add_group_with_data("my-group", "consumer", group_data)
  original.throttle_time_ms = 50
  let encoded = @protocol.encode(original)
  let decoded = @protocol.versioned_decode(
    encoded,
    ListGroupsResponse::decode,
    5,
  )
  @json.inspect(decoded, content={
    "version": 5,
    "throttle_time_ms": 50,
    "error": 0,
    "groups": { "my-group": "consumer" },
    "groups_data": {
      "my-group": { "group_state": "Stable", "group_type": "Classic" },
    },
  })
}

///|
test "ListGroupsResponse with error roundtrip" {
  let original = @protocol.ListGroupsResponse::with_version(2)
  original.error = @protocol.ErrNotCoordinatorForConsumer
  original.throttle_time_ms = 200
  let encoded = @protocol.encode(original)
  let decoded = @protocol.versioned_decode(
    encoded,
    ListGroupsResponse::decode,
    2,
  )
  @json.inspect(decoded, content={
    "version": 2,
    "throttle_time_ms": 200,
    "error": 16,
    "groups": {},
    "groups_data": {},
  })
}
