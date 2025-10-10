///|
struct PrepEncoder {
  stack : Array[&PushEncoder]
  mut length : Int
}

///|
pub fn PrepEncoder::new() -> PrepEncoder {
  { stack: Array::new(), length: 0 }
}

///|
pub impl PacketEncoder for PrepEncoder with put_int8(self, _) {
  self.length = self.length + 1
}

///|
pub impl PacketEncoder for PrepEncoder with put_int16(self, _) {
  self.length = self.length + 2
}

///|
pub impl PacketEncoder for PrepEncoder with put_int32(self, _) {
  self.length = self.length + 4
}

///|
pub impl PacketEncoder for PrepEncoder with put_int64(self, _) {
  self.length = self.length + 8
}

///|
pub impl PacketEncoder for PrepEncoder with put_varint(self, in_) {
  let buf = Array::make(@binary.MaxVarintLen64, Byte::default())
  self.length = self.length + @binary.put_varint(buf, in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_uvarint(self, in_) {
  let buf = Array::make(@binary.MaxVarintLen64, Byte::default())
  self.length = self.length + @binary.put_uvarint(buf, in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_float64(self, _) {
  self.length = self.length + 8
}

///|
pub impl PacketEncoder for PrepEncoder with put_array_length(self, in_) raise {
  if in_ > @int.max_value {
    raise PacketEncodingError("array too long (\{in_})")
  }
  self.length = self.length + 4
}

///|
pub impl PacketEncoder for PrepEncoder with put_compact_array_length(self, in_) {
  self.put_uvarint((in_ + 1).to_uint64())
}

///|
pub impl PacketEncoder for PrepEncoder with put_bool(self, _) {
  self.length = self.length + 1
}

// arrays

///|
pub impl PacketEncoder for PrepEncoder with put_bytes(self, in_) raise {
  self.length = self.length + 4
  guard in_ is Some(in_) else { return }
  self.put_raw_bytes(in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_varint_bytes(self, in_) raise {
  guard in_ is Some(in_) else {
    self.put_varint(-1)
    return
  }
  self.put_varint(in_.length().to_int64())
  self.put_raw_bytes(in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_compact_bytes(self, in_) raise {
  self.put_uvarint((in_.length() + 1).to_uint64())
  self.put_raw_bytes(in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_compact_string(self, in_) raise {
  self.put_compact_array_length(in_.length())
  self.put_raw_bytes(@encoding/utf8.encode(in_))
}

///|
pub impl PacketEncoder for PrepEncoder with put_nullable_compact_string(
  self,
  in_,
) raise {
  guard in_ is Some(in_) else {
    self.put_uvarint(0)
    return
  }
  return self.put_compact_string(in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_raw_bytes(self, in_) raise {
  if in_.length() > @int.max_value {
    raise PacketEncodingError("byteslice too long (\{in_.length()})")
  }
  self.length = self.length + in_.length()
}

///|
pub impl PacketEncoder for PrepEncoder with put_nullable_string(self, in_) raise {
  guard in_ is Some(in_) else {
    self.length = self.length + 2
    return
  }
  self.put_string(in_)
}

///|
pub impl PacketEncoder for PrepEncoder with put_string(self, in_) raise {
  self.length = self.length + 2
  if in_.length() > @int.max_value {
    raise PacketEncodingError("string too long (\{in_.length()})")
  }
  self.length = self.length + in_.length()
}

///|
pub impl PacketEncoder for PrepEncoder with put_string_array(self, in_) raise {
  self.put_array_length(in_.length())
  for _, str in in_ {
    self.put_string(str)
  }
}

///|
pub impl PacketEncoder for PrepEncoder with put_compact_int32_array(self, in_) raise {
  self.put_uvarint((in_.length() + 1).to_uint64())
  self.length = self.length + 4 * in_.length()
}

///|
pub impl PacketEncoder for PrepEncoder with put_nullable_compact_int32_array(
  self,
  in_,
) raise {
  guard in_ is Some(in_) else {
    self.put_uvarint(0)
    return
  }
  self.put_uvarint((in_.length() + 1).to_uint64())
  self.length = self.length + 4 * in_.length()
}

///|
pub impl PacketEncoder for PrepEncoder with put_int32_array(self, in_) raise {
  self.put_array_length(in_.length())
  self.length = self.length + 4 * in_.length()
}

///|
pub impl PacketEncoder for PrepEncoder with put_int64_array(self, in_) raise {
  self.put_array_length(in_.length())
  self.length = self.length + 8 * in_.length()
}

///|
pub impl PacketEncoder for PrepEncoder with put_empty_tagged_field_array(self) {
  self.put_uvarint(0)
}

///|
pub impl PacketEncoder for PrepEncoder with offset(self) -> Int {
  return self.length
}

// stackable

///|
pub impl PacketEncoder for PrepEncoder with push(self, in_) {
  in_.save_offset(self.length)
  self.length = self.length + in_.reserve_length()
  self.stack.push(in_)
}

///|
pub impl PacketEncoder for PrepEncoder with pop(self) raise {
  guard self.stack.pop() is Some(in_)
  self.length = self.length + in_.adjust_length(self.length)
}

// we do not record metrics during the prep encoder pass
// ///|
// pub impl PacketEncoder for PrepEncoder with metricRegistry(self) metrics.Registry {
// 	return nil
// }
