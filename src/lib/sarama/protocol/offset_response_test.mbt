///|
let emptyOffsetResponse : Bytes = [0x00, 0x00, 0x00, 0x00]

///|
let normalOffsetResponse : Bytes = [
  0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0x61,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x01, 0x7a,
  0x00, 0x00, 0x00, 0x01,
  0x00, 0x00, 0x00, 0x02,
  0x00, 0x00,
  0x00, 0x00, 0x00, 0x02,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06,
]

///|
let normalOffsetResponseV1 : Bytes = [
  0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0x61,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x01, 0x7a,
  0x00, 0x00, 0x00, 0x01,
  0x00, 0x00, 0x00, 0x02,
  0x00, 0x00,
  0x00, 0x00, 0x01, 0x58, 0x1a, 0xe6, 0x48, 0x86,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06,
]

///|
let offsetResponseV4 : Bytes = [
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x01,
  0x00, 0x04, 0x64, 0x6e, 0x77, 0x65,
  0x00, 0x00, 0x00, 0x01,
  0x00, 0x00, 0x00, 0x09,
  0x00, 0x00,
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xff, 0xff, 0xff, 0xff,
]

///|
test "OffsetResponse empty v0" {
  let response = versioned_decode(emptyOffsetResponse, OffsetResponse::decode, 0)
  assert_eq(response.blocks.length(), 0)
}

///|
test "OffsetResponse empty v1" {
  let response = versioned_decode(emptyOffsetResponse, OffsetResponse::decode, 1)
  assert_eq(response.blocks.length(), 0)
}

///|
test "OffsetResponse normal v0" {
  let response = versioned_decode(normalOffsetResponse, OffsetResponse::decode, 0)
  assert_eq(response.blocks.length(), 2)
  assert_eq(response.blocks.contains("a"), true)
  assert_eq(response.blocks["a"].length(), 0)
  assert_eq(response.blocks.contains("z"), true)
  assert_eq(response.blocks["z"].length(), 1)
  guard response.blocks["z"].get(2) is Some(block)
  assert_eq(block.error, KErrorCode(ErrNoError))
  assert_eq(block.offsets.length(), 2)
  assert_eq(block.offsets[0], 5L)
  assert_eq(block.offsets[1], 6L)
}

///|
test "OffsetResponse normal v1" {
  let response = versioned_decode(normalOffsetResponseV1, OffsetResponse::decode, 1)
  assert_eq(response.blocks.length(), 2)
  assert_eq(response.blocks.contains("a"), true)
  assert_eq(response.blocks["a"].length(), 0)
  assert_eq(response.blocks.contains("z"), true)
  assert_eq(response.blocks["z"].length(), 1)
  guard response.blocks["z"].get(2) is Some(block)
  assert_eq(block.error, KErrorCode(ErrNoError))
  assert_eq(block.timestamp, 1477920049286L)
  assert_eq(block.offset, 6L)
  assert_eq(block.offsets.length(), 1)
  assert_eq(block.offsets[0], 6L)
}

///|
test "OffsetResponse v4 leader epoch" {
  let response = versioned_decode(offsetResponseV4, OffsetResponse::decode, 4)
  assert_eq(response.blocks.length(), 1)
  guard response.get_block("dnwe", 9) is Some(block)
  assert_eq(block.error, KErrorCode(ErrNoError))
  assert_eq(block.timestamp, -1L)
  assert_eq(block.offset, 0L)
  assert_eq(block.leader_epoch, -1)
}
