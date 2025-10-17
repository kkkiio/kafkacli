///|
let errInvalidArrayLength : PacketDecodingError = PacketDecodingError(
  "invalid array length",
)

///|
let errInvalidByteSliceLength : PacketDecodingError = PacketDecodingError(
  "invalid byteslice length",
)

///|
let errInvalidStringLength : PacketDecodingError = PacketDecodingError(
  "invalid string length",
)

///|
let errVarintOverflow : PacketDecodingError = PacketDecodingError(
  "varint overflow",
)

///|
let errUVarintOverflow : PacketDecodingError = PacketDecodingError(
  "uvarint overflow",
)

///|
let errInvalidBool : PacketDecodingError = PacketDecodingError("invalid bool")

///|
struct RealDecoder {
  raw : BytesView
  mut off : Int
  stack : Array[&PushDecoder]
  // registry :metrics.Registry
}

///|
pub fn RealDecoder::new(raw : BytesView) -> RealDecoder {
  { raw, off: 0, stack: Array::new() }
}

// primitives

///|
pub impl PacketDecoder for RealDecoder with get_byte(self) {
  if self.remaining() < 1 {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  let tmp = self.raw[self.off]
  self.off += 1
  tmp
}

///|
pub impl PacketDecoder for RealDecoder with get_int16(self) {
  if self.remaining() < 2 {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  // let tmp = (@binary.BigEndian.Uint16(self.raw[self.off:]))
  let tmp = match self.raw[self.off:self.off + 2] {
    [a, b] => (a.to_int16() << 8) | b.to_int16()
    _ => raise err_insufficient_data
  }
  self.off += 2
  tmp
}

///|
pub impl PacketDecoder for RealDecoder with get_int(self) {
  if self.remaining() < 4 {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  let tmp = match self.raw[self.off:self.off + 4] {
    [a, b, c, d] =>
      (a.to_int() << 24) | (b.to_int() << 16) | (c.to_int() << 8) | d.to_int()
    _ => raise err_insufficient_data
  }
  self.off += 4
  tmp
}

///|
pub impl PacketDecoder for RealDecoder with get_int64(self) {
  if self.remaining() < 8 {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  let tmp = match self.raw[self.off:self.off + 8] {
    [a, b, c, d, e, f, g, h] =>
      (a.to_int64() << 56) |
      (b.to_int64() << 48) |
      (c.to_int64() << 40) |
      (d.to_int64() << 32) |
      (e.to_int64() << 24) |
      (f.to_int64() << 16) |
      (g.to_int64() << 8) |
      h.to_int64()
    _ => raise err_insufficient_data
  }
  self.off += 8
  tmp
}

///|
pub impl PacketDecoder for RealDecoder with get_varint(self) {
  let (tmp, n) = @binary.varint(self.raw[self.off:])
  if n == 0 {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  if n < 0 {
    self.off -= n
    raise errVarintOverflow
  }
  self.off += n
  tmp
}

///|
pub impl PacketDecoder for RealDecoder with get_uvarint(self) {
  let (tmp, n) = @binary.uvarint(self.raw[self.off:])
  if n == 0 {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  if n < 0 {
    self.off -= n
    raise errUVarintOverflow
  }
  self.off += n
  tmp
}

///|
pub impl PacketDecoder for RealDecoder with get_float64(self) {
  let int64 = self.get_int64()
  float64_frombits(int64.reinterpret_as_uint64())
}

///|
pub impl PacketDecoder for RealDecoder with get_array_length(self) {
  // cast to int32 first to get correct signedness for length before then
  // casting to int for ease of interop
  let int32 = self.get_int()
  if int32 > self.remaining() {
    self.off = self.raw.length()
    raise err_insufficient_data
  } else if int32 > MaxResponseSize.reinterpret_as_int() {
    raise errInvalidArrayLength
  }
  int32
}

///|
pub impl PacketDecoder for RealDecoder with get_compact_array_length(self) {
  let n = self.get_uvarint()
  if n == 0 {
    return 0
  }
  if n == 0 {
    return 0
  }
  return n.to_int() - 1
}

///|
pub impl PacketDecoder for RealDecoder with get_bool(self) {
  let b = self.get_byte()
  if b == 0 {
    false
  } else if b == 1 {
    true
  } else {
    raise errInvalidBool
  }
}

///|
pub impl PacketDecoder for RealDecoder with get_empty_tagged_field_array(self) {
  let tagCount = self.get_uvarint()
  if tagCount == 0 {
    return 0
  }

  // skip over any tagged fields without deserializing them
  // as we don't currently support doing anything with them
  for i in 0..<tagCount.to_int() {
    // fetch and ignore tag identifier
    let _ = self.get_uvarint()
    let length = self.get_uvarint()
    let _ = self.get_raw_bytes(length.to_int())

  }
  return 0
}

// collections

///|
pub impl PacketDecoder for RealDecoder with get_bytes(self) {
  let tmp = self.get_int()
  if tmp == -1 {
    return None
  }
  self.get_raw_bytes(tmp) |> Some
}

///|
pub impl PacketDecoder for RealDecoder with get_varint_bytes(self) {
  let tmp = self.get_varint()
  if tmp == -1 {
    return None
  }
  self.get_raw_bytes(tmp.to_int()) |> Some
}

///|
pub impl PacketDecoder for RealDecoder with get_compact_bytes(self) {
  let n = self.get_uvarint()
  let length = n.to_int() - 1
  self.get_raw_bytes(length)
}

///|
pub fn RealDecoder::get_string_length(
  self : RealDecoder,
) -> Int raise PacketDecodingError {
  let length = self.get_int16()
  let n = length.to_int()
  if n < -1 {
    raise errInvalidStringLength
  }
  if n > self.remaining() {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  n
}

///|
pub impl PacketDecoder for RealDecoder with get_string(self) {
  let n = self.get_string_length()
  if n == -1 {
    return ""
  }
  let tmpStr = {
    let bytes = self.raw[self.off:self.off + n].to_bytes()
    // Simple UTF-8 validation - for now just convert bytes to string
    // TODO: implement proper UTF-8 decoding
    // For now, just return an empty string - proper UTF-8 decoding can be added later
    // TODO: implement proper UTF-8 decoding
    ""
  }
  self.off += n
  tmpStr
}

///|
pub impl PacketDecoder for RealDecoder with get_nullable_string(self) {
  let n = self.get_string_length()
  if n == -1 {
    return None
  }
  let tmpStr = {
    let bytes = self.raw[self.off:self.off + n].to_bytes()
    // Simple UTF-8 validation - for now just convert bytes to string
    // TODO: implement proper UTF-8 decoding
    // For now, just return an empty string - proper UTF-8 decoding can be added later
    // TODO: implement proper UTF-8 decoding
    ""
  }
  self.off += n
  Some(tmpStr)
}

///|
pub impl PacketDecoder for RealDecoder with get_compact_string(self) {
  let n = self.get_uvarint()
  let length = n.to_int() - 1
  if length < 0 {
    raise errInvalidByteSliceLength
  }
  let tmpStr = {
    let bytes = self.raw[self.off:self.off + length].to_bytes()
    // Simple UTF-8 validation - for now just convert bytes to string
    // TODO: implement proper UTF-8 decoding
    // For now, just return an empty string - proper UTF-8 decoding can be added later
    // TODO: implement proper UTF-8 decoding
    ""
  }
  self.off += length
  tmpStr
}

///|
pub impl PacketDecoder for RealDecoder with get_compact_nullable_string(self) {
  let n = self.get_uvarint()
  if n == 0 {
    return None
  }
  let length = n.to_int() - 1
  if length < 0 {
    raise errInvalidByteSliceLength
  }
  let tmpStr = {
    let bytes = self.raw[self.off:self.off + length].to_bytes()
    // Simple UTF-8 validation - for now just convert bytes to string
    // TODO: implement proper UTF-8 decoding
    // For now, just return an empty string - proper UTF-8 decoding can be added later
    // TODO: implement proper UTF-8 decoding
    ""
  }
  self.off += length
  Some(tmpStr)
}

///|
pub impl PacketDecoder for RealDecoder with get_compact_int_array(self) {
  let n = self.get_uvarint()
  if n == 0 {
    return Array::new()
  }
  let arrayLength = n.to_int() - 1
  let ret = Array::make(arrayLength, 0)
  for i in 0..<arrayLength {
    let v = self.get_int()
    ret[i] = v
  }
  ret
}

///|
pub impl PacketDecoder for RealDecoder with get_int_array(self) {
  let n = self.get_array_length()
  if n <= 0 {
    return Array::new()
  }
  if n <= 0 {
    return Array::new()
  }
  if self.remaining() < 4 * n {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  let ret = Array::make(n, 0)
  for i in 0..<n {
    ret[i] = self.get_int()
  }
  ret
}

///|
pub impl PacketDecoder for RealDecoder with get_int64_array(self) {
  let n = self.get_array_length()
  if n <= 0 {
    return Array::new()
  }
  if self.remaining() < 8 * n {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  let ret = Array::make(n, 0L)
  for i in 0..<n {
    ret[i] = self.get_int64()
  }
  ret
}

///|
pub impl PacketDecoder for RealDecoder with get_string_array(self) {
  let n = self.get_array_length()
  if n <= 0 {
    return Array::new()
  }
  let ret = Array::make(n, "")
  for i in 0..<n {
    let str = self.get_string()
    ret[i] = str
  }
  ret
}

// subsets

///|
pub impl PacketDecoder for RealDecoder with remaining(self) {
  return self.raw.length() - self.off
}

///|
pub impl PacketDecoder for RealDecoder with get_subset(self, length : Int) {
  let buf = self.get_raw_bytes(length)
  RealDecoder::new(buf)
}

///|
pub impl PacketDecoder for RealDecoder with get_raw_bytes(self, length : Int) {
  if length < 0 {
    raise errInvalidByteSliceLength
  } else if length > self.remaining() {
    self.off = self.raw.length()
    raise err_insufficient_data
  }
  let start = self.off
  self.off += length
  self.raw[start:self.off]
}

///|
pub impl PacketDecoder for RealDecoder with peek(
  self,
  offset : Int,
  length : Int,
) {
  if self.remaining() < offset + length {
    raise err_insufficient_data
  }
  let off = self.off + offset
  RealDecoder::new(self.raw[off:off + length])
}

///|
pub impl PacketDecoder for RealDecoder with peek_byte(self, offset : Int) {
  let byteLen = 1
  if self.remaining() < offset + byteLen {
    raise err_insufficient_data
  }
  self.raw[self.off + offset]
}

// stacks

///|
pub impl PacketDecoder for RealDecoder with push(self, in_ : &PushDecoder) {
  in_.save_offset(self.off)
  let reserve = if in_.get_dynamic_decoder() is Some(dpd) {
    dpd.decode(self)
    0
  } else {
    let reserve = in_.reserve_length()
    if self.remaining() < reserve {
      self.off = self.raw.length()
      raise err_insufficient_data
    }
    reserve
  }
  self.stack.push(in_)
  self.off += reserve
}

///|
pub impl PacketDecoder for RealDecoder with pop(self) {
  // this is go's ugly pop pattern (the inverse of append)
  guard self.stack.pop() is Some(in_)
  in_.check(self.off, self.raw)
}

// func (rd *realDecoder) metricRegistry() metrics.Registry {
// 	return rd.registry
// }

///|
fn float64_frombits(bits : UInt64) -> Double {
  bits.reinterpret_as_double()
}
