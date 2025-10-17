///|
/// LengthField implements the PushEncoder and PushDecoder interfaces for calculating 4-byte lengths.
struct LengthField {
  mut start_offset : Int
  mut length : Int
} derive(Default)

///|
pub impl Decoder for LengthField with decode(self, pd) {
  self.length = pd.get_int()
  if self.length > pd.remaining() {
    raise PacketDecodingError("insufficient data")
  }
}

///|
fn LengthField::save_offset(self : LengthField, in_ : Int) -> Unit {
  self.start_offset = in_
}

///|
fn LengthField::reserve_length(self : LengthField) -> Int {
  4
}

///|
pub impl PushDecoder for LengthField with save_offset(self, in_) {
  self.save_offset(in_)
}

///|
pub impl PushDecoder for LengthField with reserve_length(self) {
  self.reserve_length()
}

///|
pub impl PushEncoder for LengthField with run(self, curOffset, buf) {
  let length = (curOffset - self.start_offset - 4).reinterpret_as_uint()
  buf[self.start_offset] = (length >> 24).to_byte()
  buf[self.start_offset + 1] = (length >> 16).to_byte()
  buf[self.start_offset + 2] = (length >> 8).to_byte()
  buf[self.start_offset + 3] = length.to_byte()
}

///|
pub impl PushEncoder for LengthField with save_offset(self, in_) {
  self.save_offset(in_)
}

///|
pub impl PushEncoder for LengthField with reserve_length(self) {
  self.reserve_length()
}

///|
pub impl PushDecoder for LengthField with check(self, curOffset, buf) {
  if curOffset - self.start_offset - 4 != self.length {
    raise PacketDecodingError("length field invalid")
  }
}

///|
struct VarintLengthField {
  mut start_offset : Int
  mut length : Int64
}

///|
pub impl Decoder for VarintLengthField with decode(self, pd) {
  self.length = pd.get_varint()
}

///|
pub fn VarintLengthField::save_offset(
  self : VarintLengthField,
  in_ : Int,
) -> Unit {
  self.start_offset = in_
}

///|
pub impl PushDecoder for VarintLengthField with save_offset(self, in_) {
  self.save_offset(in_)
}

///|
pub fn VarintLengthField::adjust_length(
  self : VarintLengthField,
  currOffset : Int,
) -> Int {
  let oldFieldSize = self.reserve_length()
  self.length = (currOffset - self.start_offset - oldFieldSize).to_int64()
  return self.reserve_length() - oldFieldSize
}

///|
fn VarintLengthField::reserve_length(self : VarintLengthField) -> Int {
  // var tmp [binary.MaxVarintLen64]byte
  // return binary.PutVarint(tmp[:], l.length)
  @binary.append_uvarint([], self.length.reinterpret_as_uint64())
}

///|
pub impl PushEncoder for VarintLengthField with save_offset(self, in_) {
  self.save_offset(in_)
}

///|
pub impl PushEncoder for VarintLengthField with reserve_length(self) {
  self.reserve_length()
}

///|
pub impl PushDecoder for VarintLengthField with reserve_length(self) {
  self.reserve_length()
}

///|
pub impl PushDecoder for VarintLengthField with get_dynamic_decoder(self) {
  Some(self)
}

///|
pub impl PushEncoder for VarintLengthField with run(self, curOffset, buf) {
  @binary.put_varint(buf, self.length, offset=self.start_offset) |> ignore
}

///|
pub impl PushDecoder for VarintLengthField with check(self, curOffset, buf) {
  if (curOffset - self.start_offset - self.reserve_length()).to_int64() !=
    self.length {
    raise PacketDecodingError("length field invalid")
  }
}
