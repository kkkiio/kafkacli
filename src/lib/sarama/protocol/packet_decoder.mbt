///|
// PacketDecoder is the interface providing helpers for reading with Kafka's encoding rules.
// Types implementing Decoder only need to worry about calling methods like GetString,
// not about how a string is represented in Kafka.
pub trait PacketDecoder {
  // Primitives
  get_int8(Self) -> Byte raise PacketDecodingError
  get_int16(Self) -> Int16 raise PacketDecodingError
  get_int32(Self) -> Int raise PacketDecodingError
  get_int64(Self) -> Int64 raise PacketDecodingError
  get_varint(Self) -> Int64 raise PacketDecodingError
  get_uvarint(Self) -> UInt64 raise PacketDecodingError
  get_float64(Self) -> Double raise PacketDecodingError
  get_array_length(Self) -> Int raise PacketDecodingError
  get_compact_array_length(Self) -> Int raise PacketDecodingError
  get_bool(Self) -> Bool raise PacketDecodingError
  get_empty_tagged_field_array(Self) -> Int raise PacketDecodingError

  // Collections
  get_bytes(Self) -> BytesView? raise PacketDecodingError
  get_varint_bytes(Self) -> BytesView? raise PacketDecodingError
  get_compact_bytes(Self) -> BytesView raise PacketDecodingError
  get_raw_bytes(Self, length : Int) -> BytesView raise PacketDecodingError
  get_string(Self) -> String raise PacketDecodingError
  get_nullable_string(Self) -> String? raise PacketDecodingError
  get_compact_string(Self) -> String raise PacketDecodingError
  get_compact_nullable_string(Self) -> String? raise PacketDecodingError
  get_compact_int32_array(Self) -> Array[Int] raise PacketDecodingError
  get_int32_array(Self) -> Array[Int] raise PacketDecodingError
  get_int64_array(Self) -> Array[Int64] raise PacketDecodingError
  get_string_array(Self) -> Array[String] raise PacketDecodingError

  // Subsets
  remaining(Self) -> Int
  get_subset(Self, length : Int) -> &PacketDecoder raise PacketDecodingError
  peek(Self, offset : Int, length : Int) -> &PacketDecoder raise PacketDecodingError // similar to getSubset, but it doesn't advance the offset
  peek_int8(Self, offset : Int) -> Byte raise PacketDecodingError // similar to peek, but just one byte

  // Stacks, see PushDecoder
  push(Self, in_ : &PushDecoder) -> Unit raise
  pop(Self) -> Unit raise

  // To record metrics when provided
  // metricRegistry() metrics.Registry
}

// PushDecoder is the interface for decoding fields like CRCs and lengths where the validity
// of the field depends on what is after it in the packet. Start them with PacketDecoder.Push() where
// the actual value is located in the packet, then PacketDecoder.Pop() them when all the bytes they
// depend upon have been decoded.

///|
pub trait PushDecoder {
  // Saves the offset into the input buffer as the location to actually read the calculated value when able.
  save_offset(Self, in_ : Int) -> Unit

  // Returns the length of data to reserve for the input of this encoder (e.g. 4 bytes for a CRC32).
  reserve_length(Self) -> Int

  // Indicates that all required data is now available to calculate and check the field.
  // SaveOffset is guaranteed to have been called first. The implementation should read ReserveLength() bytes
  // of data from the saved offset, and verify it based on the data between the saved offset and curOffset.
  check(Self, curOffset : Int, buf : BytesView) -> Unit raise

  // dynamicPushDecoder extends the interface of pushDecoder for uses cases where the length of the
  // fields itself is unknown until its value was decoded (for instance varint encoded length
  // fields).
  // During push, dynamicPushDecoder.decode() method will be called instead of reserveLength()
  get_dynamic_decoder(Self) -> &Decoder? = _
}

///|
impl PushDecoder with get_dynamic_decoder(self) {
  None
}
