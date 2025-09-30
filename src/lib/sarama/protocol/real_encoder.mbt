///|
struct RealEncoder {
  raw : Array[Byte]
  mut off : Int
  stack : Array[&PushEncoder]
  // registry metrics.Registry
}

///|
pub fn RealEncoder::new(raw : Array[Byte]) -> RealEncoder {
  { raw, off: 0, stack: Array::new() }
}

///|
pub impl PacketEncoder for RealEncoder with put_int8(self, in_) {
  self.raw[self.off] = in_
  self.off += 1
}

///|
pub impl PacketEncoder for RealEncoder with put_int16(self, in_) {
  // binary.BigEndian.PutUint16(re.raw[re.off:], uint16(in))
  self.raw[self.off] = (in_ >> 8).to_byte()
  self.raw[self.off + 1] = (in_ & 0xFF).to_byte()
  self.off += 2
}

///|
pub impl PacketEncoder for RealEncoder with put_int32(self, in_) {
  // binary.BigEndian.PutUint32(re.raw[re.off:], uint32(in))
  self.raw[self.off] = (in_ >> 24).to_byte()
  self.raw[self.off + 1] = (in_ >> 16).to_byte()
  self.raw[self.off + 2] = (in_ >> 8).to_byte()
  self.raw[self.off + 3] = (in_ & 0xFF).to_byte()
  self.off += 4
}

///|
pub impl PacketEncoder for RealEncoder with put_int64(self, in_) {
  // binary.BigEndian.PutUint64(re.raw[re.off:], uint64(in))
  let in_ = in_.reinterpret_as_uint64()
  self.raw[self.off] = (in_ >> 56).to_byte()
  self.raw[self.off + 1] = (in_ >> 48).to_byte()
  self.raw[self.off + 2] = (in_ >> 40).to_byte()
  self.raw[self.off + 3] = (in_ >> 32).to_byte()
  self.raw[self.off + 4] = (in_ >> 24).to_byte()
  self.raw[self.off + 5] = (in_ >> 16).to_byte()
  self.raw[self.off + 6] = (in_ >> 8).to_byte()
  self.raw[self.off + 7] = (in_ & 0xFF).to_byte()
  self.off += 8
}

///|
pub impl PacketEncoder for RealEncoder with put_varint(self, in_) {
  self.off += @binary.put_varint(self.raw, in_, offset=self.off)
}

///|
pub impl PacketEncoder for RealEncoder with put_uvarint(self, in_) {
  self.off += @binary.put_uvarint(self.raw, in_, offset=self.off)
}

///|
pub impl PacketEncoder for RealEncoder with put_float64(self, in_) {
  // binary.BigEndian.PutUint64(re.raw[re.off:], float64bits(in))
  let uint64 = float64bits(in_)
  self.put_int64(uint64.reinterpret_as_int64())
  self.off += 8
}

///|
pub impl PacketEncoder for RealEncoder with put_array_length(self, in_) {
  self.put_int32(in_)
}

///|
pub impl PacketEncoder for RealEncoder with put_compact_array_length(self, in_) {
  // 0 represents a null array, so +1 has to be added
  self.put_uvarint((in_ + 1).to_uint64())
}

///|
pub impl PacketEncoder for RealEncoder with put_bool(self, in_) {
  if in_ {
    self.put_int8(1)
  } else {
    self.put_int8(0)
  }
}

// collection

///|
pub impl PacketEncoder for RealEncoder with put_raw_bytes(self, in_) {
  // copy(self.raw[self.off:], in_)
  let in_ = in_.to_array()
  self.raw.unsafe_blit(self.off, in_, 0, in_.length())
  self.off += in_.length()
}

///|
pub impl PacketEncoder for RealEncoder with put_bytes(self, in_) {
  match in_ {
    None => self.put_int32(-1)
    Some(in_) => {
      self.put_int32(in_.length())
      self.put_raw_bytes(in_)
    }
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_varint_bytes(self, in_) {
  match in_ {
    None => self.put_varint(-1)
    Some(in_) => {
      self.put_varint(in_.length().to_int64())
      self.put_raw_bytes(in_)
    }
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_compact_bytes(self, in_) {
  self.put_uvarint((in_.length() + 1).to_uint64())
  self.put_raw_bytes(in_)
}

///|
pub impl PacketEncoder for RealEncoder with put_compact_string(self, in_) {
  let in_ = @encoding/utf8.encode(in_)
  self.put_compact_array_length(in_.length())
  self.put_raw_bytes(in_)
}

///|
pub impl PacketEncoder for RealEncoder with put_nullable_compact_string(
  self,
  in_,
) {
  match in_ {
    None => self.put_int8(0)
    Some(in_) => self.put_compact_string(in_)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_string(self, in_) {
  let in_ = @encoding/utf8.encode(in_)
  self.put_int16(in_.length().to_int16())
  self.put_raw_bytes(in_)
}

///|
pub impl PacketEncoder for RealEncoder with put_nullable_string(self, in_) {
  match in_ {
    None => self.put_int16(-1)
    Some(in_) => self.put_string(in_)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_string_array(self, in_) {
  self.put_array_length(in_.length())
  for _, val in in_ {
    self.put_string(val)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_compact_int32_array(self, in_) {
  // 0 represents a null array, so +1 has to be added
  self.put_uvarint((in_.length() + 1).to_uint64())
  for _, val in in_ {
    self.put_int32(val)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_nullable_compact_int32_array(
  self,
  in_,
) {
  guard in_ is Some(in_) else {
    self.put_uvarint(0)
    return
  }
  // 0 represents a null array, so +1 has to be added
  self.put_uvarint(in_.length().to_uint64() + 1)
  for _, val in in_ {
    self.put_int32(val)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_int32_array(self, in_) {
  self.put_array_length(in_.length())
  for _, val in in_ {
    self.put_int32(val)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_int64_array(self, in_) {
  self.put_array_length(in_.length())
  for _, val in in_ {
    self.put_int64(val)
  }
}

///|
pub impl PacketEncoder for RealEncoder with put_empty_tagged_field_array(self) {
  self.put_uvarint(0)
}

///|
pub impl PacketEncoder for RealEncoder with offset(self) -> Int {
  self.off
}

// stacks

///|
pub impl PacketEncoder for RealEncoder with push(self, in_) {
  in_.save_offset(self.off)
  self.off += in_.reserve_length()
  self.stack.push(in_)
}

///|
pub impl PacketEncoder for RealEncoder with pop(self) raise {
  guard self.stack.pop() is Some(in_)
  return in_.run(self.off, self.raw)
}

// we do record metrics during the real encoder pass
// pub impl PacketEncoder for RealEncoder metricRegistry(self) metrics.Registry {
// 	return re.registry
// }

///|
fn float64bits(in_ : Double) -> UInt64 {
  in_.reinterpret_as_uint64()
}
