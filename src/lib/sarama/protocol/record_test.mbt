/// Test functions for Record and RecordBatch (ported from Go Sarama)

///|
/// Test data for empty record batch
let emptyRecordBatch : Bytes = [
  0, 0, 0, 0, 0, 0, 0, 0, // First Offset
  0, 0, 0, 49, // Length
  0, 0, 0, 0, // Partition Leader Epoch
  2,                // Version
  89, 95, 183, 221, // CRC
  0, 0, // Attributes
  0, 0, 0, 0, // Last Offset Delta
  0, 0, 0, 0, 0, 0, 0, 0, // First Timestamp
  0, 0, 0, 0, 0, 0, 0, 0, // Max Timestamp
  0, 0, 0, 0, 0, 0, 0, 0, // Producer ID
  0, 0, // Producer Epoch
  0, 0, 0, 0, // First Sequence
  0, 0, 0, 0, // Number of Records
]

///|
/// Test data for control batch
let controlRecordBatch : Bytes = [
  0, 0, 0, 0, 0, 0, 0, 0, // First Offset
  0, 0, 0, 49, // Length
  0, 0, 0, 0, // Partition Leader Epoch
  2,               // Version
  81, 46, 67, 217, // CRC
  0, 32, // Attributes (control bit set)
  0, 0, 0, 0, // Last Offset Delta
  0, 0, 0, 0, 0, 0, 0, 0, // First Timestamp
  0, 0, 0, 0, 0, 0, 0, 0, // Max Timestamp
  0, 0, 0, 0, 0, 0, 0, 0, // Producer ID
  0, 0, // Producer Epoch
  0, 0, 0, 0, // First Sequence
  0, 0, 0, 0, // Number of Records
]

///|
/// Test data for uncompressed record batch
let uncompressedRecordBatch : Bytes = [
  0, 0, 0, 0, 0, 0, 0, 0, // First Offset
  0, 0, 0, 70, // Length
  0, 0, 0, 0, // Partition Leader Epoch
  2,                // Version
  84, 121, 97, 253, // CRC
  0, 0, // Attributes
  0, 0, 0, 0, // Last Offset Delta
  0, 0, 1, 88, 141, 205, 89, 56, // First Timestamp (1479847795)
  0, 0, 0, 0, 0, 0, 0, 0, // Max Timestamp
  0, 0, 0, 0, 0, 0, 0, 0, // Producer ID
  0, 0, // Producer Epoch
  0, 0, 0, 0, // First Sequence
  0, 0, 0, 1, // Number of Records
  40, // Record Length
  0,  // Attributes
  10, // Timestamp Delta (5ms)
  0,  // Offset Delta
  8,  // Key Length
  1, 2, 3, 4, // Key
  6, // Value Length
  5, 6, 7, // Value
  2,        // Number of Headers
  6,        // Header Key Length
  8, 9, 10, // Header Key
  4,      // Header Value Length
  11, 12, // Header Value
]

///|
/// Helpers mirroring the Go Sarama record tests
struct BatchCase {
  encoded : Bytes
  expect_control : Bool
  expect_records : Int
  expect_first_timestamp : Int64
}

///|
let uncompressedRecordPayload : Bytes = [
  40, // Varint length prefix (zigzag encoded 20)
  0, // Attributes
  10, // Timestamp delta (varint => 5)
  0, // Offset delta
  8, // Key length (varint => 4)
  1, 2, 3, 4, // Key bytes
  6, // Value length (varint => 3)
  5, 6, 7, // Value bytes
  2, // Number of headers (varint => 1)
  6, // Header key length (varint => 3)
  8, 9, 10, // Header key
  4, // Header value length (varint => 2)
  11, 12, // Header value
]

///|
test "decode_record_batch_variants" {
  let cases = [
    BatchCase::{
      encoded: emptyRecordBatch,
      expect_control: false,
      expect_records: 0,
      expect_first_timestamp: 0,
    },
    BatchCase::{
      encoded: controlRecordBatch,
      expect_control: true,
      expect_records: 0,
      expect_first_timestamp: 0,
    },
    BatchCase::{
      encoded: uncompressedRecordBatch,
      expect_control: false,
      expect_records: 1,
      expect_first_timestamp: 1_479_847_795_000,
    },
  ]

  for case in cases {
    let batch_result = try? RecordBatch::decode(case.encoded)
    match batch_result {
      Ok(batch) => {
        assert_eq(batch.version, 2)
        assert_eq(batch.control, case.expect_control)
        assert_eq(batch.records.length(), case.expect_records)
        assert_eq(batch.first_timestamp, case.expect_first_timestamp)
      }
      Err(_) => assert_true(false)
    }
  }
}

///|
test "decode_record_header_full" {
  let helper = RealDecoder::new(uncompressedRecordPayload[14:])
  let header_result = try? RecordHeader::decode(helper)
  match header_result {
    Ok(header) => {
      assert_eq(header.key, b"\x08\x09\x0a")
      assert_eq(header.value, b"\x0b\x0c")
    }
    Err(_) => assert_true(false)
  }
}

///|
test "decode_single_record" {
  let helper = RealDecoder::new(uncompressedRecordPayload[:])
  let record_result = try? Record::decode(helper)
  match record_result {
    Ok(record) => {
      assert_eq(record.attributes, 0)
      assert_eq(record.timestamp_delta, 5)
      assert_eq(record.offset_delta, 0)
      assert_eq(record.key, b"\x01\x02\x03\x04")
      assert_eq(record.value, b"\x05\x06\x07")
      assert_eq(record.headers.length(), 1)
      let header = record.headers[0]
      assert_eq(header.key, b"\x08\x09\x0a")
      assert_eq(header.value, b"\x0b\x0c")
    }
    Err(_) => assert_true(false)
  }
}
