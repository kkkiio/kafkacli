///|
fn[T : ProtocolBody] encode_only_body(body : T) -> Bytes raise {
  let buf = Array::make(1024, Byte::default())
  let pe = RealEncoder::new(buf)
  body.encode(pe)
  return buf[:pe.offset()].to_array() |> Bytes::from_array
}

///|
fn[T] decode_only_body(
  body_bytes : Bytes,
  version : Int16,
  decode_fn : (&PacketDecoder, Int16) -> T raise PacketDecodingError,
) -> T raise PacketDecodingError {
  let pd = RealDecoder::new(body_bytes[:])
  decode_fn(pd, version)
}
