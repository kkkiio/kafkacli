///|
// Encoder is the interface that wraps the basic Encode method.
// Anything implementing Encoder can be turned into bytes using Kafka's encoding rules.
pub(open) trait Encoder {
  encode(Self, &PacketEncoder) -> Unit raise
}

///|
pub(open) trait EncoderWithHeader: Encoder {
  header_version(Self) -> Int16
}

///|
/// Encode takes an Encoder and turns it into bytes while potentially recording metrics.
pub fn encode(e : &Encoder) -> Bytes raise {
  let prepEnc = PrepEncoder::new()
  e.encode(prepEnc)
  if prepEnc.length < 0 || prepEnc.length > MaxRequestSize.reinterpret_as_int() {
    raise PacketEncodingError("invalid request size (\{prepEnc.length})")
  }
  let raw = Array::make(prepEnc.length, Byte::default())
  let realEnc = RealEncoder::new(raw)
  e.encode(realEnc)
  Bytes::from_array(raw)
}

///|
/// decoder is the interface that wraps the basic Decode method.
/// Anything implementing Decoder can be extracted from bytes using Kafka's encoding rules.
pub trait Decoder {
  decode(Self, &PacketDecoder) -> Unit raise PacketDecodingError
}

///|
pub trait VersionedDecoder {
  decode(Self, &PacketDecoder, version : Int16) -> Unit raise PacketDecodingError
}

///|
/// decode takes bytes and a decoder and fills the fields of the decoder from the bytes,
/// interpreted using Kafka's encoding rules.
pub fn[T] decode(
  bytes : BytesView,
  decode : (&PacketDecoder) -> T raise PacketDecodingError,
) -> T raise PacketDecodingError {
  let helper = RealDecoder::new(bytes)
  let result = decode(helper)
  if helper.off != bytes.length() {
    raise PacketDecodingError(
      "invalid length (\{helper.off}, len=\{bytes.length()})",
    )
  }
  result
}

///|
pub fn[T : VersionedDecoder] versioned_decode(
  buf : BytesView,
  in_ : T,
  version : Int16,
) -> Unit raise PacketDecodingError {
  let helper = RealDecoder::new(buf)
  in_.decode(helper, version)
  if helper.off != buf.length() {
    raise PacketDecodingError(
      "invalid length (off=\{helper.off}, len=\{buf.length()})",
    )
  }
}
