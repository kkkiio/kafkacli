// PacketEncoder is the interface providing helpers for writing with Kafka's encoding rules.
// Types implementing Encoder only need to worry about calling methods like PutString,
// not about how a string is represented in Kafka.

///|
pub trait PacketEncoder {
  // Primitives
  put_byte(Self, Byte) -> Unit
  put_int16(Self, Int16) -> Unit
  put_int(Self, Int) -> Unit
  put_int64(Self, Int64) -> Unit
  put_varint(Self, Int64) -> Unit
  put_uvarint(Self, UInt64) -> Unit
  put_float64(Self, Double) -> Unit
  put_compact_array_length(Self, Int) -> Unit
  put_array_length(Self, Int) -> Unit raise
  put_bool(Self, Bool) -> Unit

  // Collections
  put_bytes(Self, Bytes?) -> Unit raise
  put_varint_bytes(Self, Bytes?) -> Unit raise
  put_compact_bytes(Self, Bytes) -> Unit raise
  put_raw_bytes(Self, Bytes) -> Unit raise
  put_compact_string(Self, String) -> Unit raise
  put_nullable_compact_string(Self, String?) -> Unit raise
  put_string(Self, String) -> Unit raise
  put_nullable_string(Self, String?) -> Unit raise
  put_string_array(Self, Array[String]) -> Unit raise
  put_compact_int_array(Self, Array[Int]) -> Unit raise
  put_nullable_compact_int_array(Self, Array[Int]?) -> Unit raise
  put_int_array(Self, Array[Int]) -> Unit raise
  put_int64_array(Self, Array[Int64]) -> Unit raise
  put_empty_tagged_field_array(Self) -> Unit

  // Provide the current offset to record the batch size metric
  offset(Self) -> Int

  // Stacks, see PushEncoder
  push(Self, &PushEncoder) -> Unit
  pop(Self) -> Unit raise

  // To record metrics when provided
  // metricRegistry() metrics.Registry
}

// PushEncoder is the interface for encoding fields like CRCs and lengths where the value
// of the field depends on what is encoded after it in the packet. Start them with PacketEncoder.Push() where
// the actual value is located in the packet, then PacketEncoder.Pop() them when all the bytes they
// depend upon have been written.

///|
trait PushEncoder {
  // Saves the offset into the input buffer as the location to actually write the calculated value when able.
  save_offset(Self, Int) -> Unit

  // Returns the length of data to reserve for the output of this encoder (eg 4 bytes for a CRC32).
  reserve_length(Self) -> Int

  // Indicates that all required data is now available to calculate and write the field.
  // SaveOffset is guaranteed to have been called first. The implementation should write ReserveLength() bytes
  // of data to the saved offset, based on the data between the saved offset and curOffset.
  run(Self, Int, Array[Byte]) -> Unit raise
  // Called during pop() to adjust the length of the field.
  // It should return the difference in bytes between the last computed length and current length.
  adjust_length(Self, Int) -> Int = _
}

///|
impl PushEncoder with adjust_length(_, _) {
  0
}
