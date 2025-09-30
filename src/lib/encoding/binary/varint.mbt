// MaxVarintLenN is the maximum length of a varint-encoded N-bit integer.

///|
pub const MaxVarintLen16 = 3

///|
pub const MaxVarintLen32 = 5

///|
pub const MaxVarintLen64 = 10

///|
pub suberror DecodeError {
  ErrOverflow
  ErrEOF
  ErrUnexpectedEOF
}

///|
/// 无符号 varint 编码，写入到 `buf`，返回写入字节数
/// 等价 Go: encoding/binary.PutUvarint
pub fn put_uvarint(buf : Array[Byte], value : UInt64, offset? : Int = 0) -> Int {
  let mut x = value
  let mut n = 0
  while x >= 0x80UL {
    let b = ((x & 0x7FUL) | 0x80UL).to_int().to_byte()
    buf.op_set(offset + n, b)
    x = x >> 7
    n += 1
  }
  buf.op_set(offset + n, x.to_int().to_byte())
  n + 1
}

///|
/// 附加无符号 varint 到 `buf`，返回写入字节数
/// 等价 Go: encoding/binary.AppendUvarint
pub fn append_uvarint(buf : Array[Byte], value : UInt64) -> Int {
  let mut x = value
  let mut n = 0
  while x >= 0x80UL {
    let b = ((x & 0x7FUL) | 0x80UL).to_int().to_byte()
    buf.push(b)
    x = x >> 7
    n += 1
  }
  buf.push(x.to_int().to_byte())
  n + 1
}

///|
/// 从字节序列中解码无符号 varint，返回 (值, 已读字节数)
/// 错误语义与 Go 对齐：
/// - n == 0: 数据不足
/// - n < 0: 溢出，-n 为已读字节数
pub fn uvarint(data : ArrayView[Byte]) -> (UInt64, Int) {
  let mut x : UInt64 = 0UL
  let mut s : Int = 0
  let len = data.length()
  for i in 0..<len {
    if i == MaxVarintLen64 {
      return (0UL, -(i + 1))
    }
    let bi = data[i].to_int()
    if bi < 0x80 {
      if i == MaxVarintLen64 - 1 && bi > 1 {
        return (0UL, -(i + 1))
      }
      let v = UInt64::extend_uint(bi.reinterpret_as_uint())
      return (x | (v << s), i + 1)
    }
    let lower7 = (bi & 0x7f).reinterpret_as_uint()
    x = x | (UInt64::extend_uint(lower7) << s)
    s += 7
  }
  (0UL, 0)
}

///|
/// 有符号数 ZigZag 编码并写入，返回写入字节数
/// 等价 Go: encoding/binary.PutVarint
pub fn put_varint(buf : Array[Byte], value : Int64, offset? : Int = 0) -> Int {
  let ux = (value.reinterpret_as_uint64() << 1) ^
    (value >> 63).reinterpret_as_uint64()
  put_uvarint(buf, ux, offset~)
}

///|
/// 附加有符号 varint 到 `buf`，返回写入字节数
pub fn append_varint(buf : Array[Byte], value : Int64) -> Int {
  let ux = (value.reinterpret_as_uint64() << 1) ^
    (value >> 63).reinterpret_as_uint64()
  append_uvarint(buf, ux)
}

///|
/// 从字节序列中解码有符号 varint，返回 (值, 已读字节数)
/// 错误语义与 Go 对齐：n == 0 数据不足；n < 0 溢出
pub fn varint(data : ArrayView[Byte]) -> (Int64, Int) {
  let (ux, n) = uvarint(data)
  let mut x = (ux >> 1).reinterpret_as_int64()
  if (ux & 1UL) != 0UL {
    x = x.lnot()
  }
  (x, n)
}

///|
/// 从字节序列读取无符号 varint，返回 (值, 错误?)
/// 错误：ErrEOF / ErrUnexpectedEOF / ErrOverflow
pub fn read_uvarint(data : ArrayView[Byte]) -> UInt64 raise DecodeError {
  let mut x : UInt64 = 0UL
  let mut s : Int = 0
  let len = data.length()
  if len == 0 {
    raise ErrEOF
  }
  for i in 0..<(if len < MaxVarintLen64 { len } else { MaxVarintLen64 }) {
    let bi = data[i].to_int()
    if bi < 0x80 {
      if i == MaxVarintLen64 - 1 && bi > 1 {
        raise ErrOverflow
      }
      let v = UInt64::extend_uint(bi.reinterpret_as_uint())
      return x | (v << s)
    }
    let lower7 = (bi & 0x7f).reinterpret_as_uint()
    x = x | (UInt64::extend_uint(lower7) << s)
    s += 7
  }
  // 循环结束仍未遇到终止字节
  if len >= MaxVarintLen64 {
    raise ErrOverflow
  }
  // 未读到终止位，根据是否读到过字节决定 EOF 类型
  if len > 0 {
    raise ErrUnexpectedEOF
  } else {
    raise ErrEOF
  }
}

///|
/// 从字节序列读取有符号 varint，返回 (值, 错误?)
pub fn read_varint(data : ArrayView[Byte]) -> Int64 raise DecodeError {
  let ux = read_uvarint(data)
  let mut x = (ux >> 1).reinterpret_as_int64()
  if (ux & 1UL) != 0UL {
    x = x.lnot()
  }
  x
}
