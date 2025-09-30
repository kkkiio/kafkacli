///|
test "TestConstants" {
  test_constant(16, MaxVarintLen16)
  test_constant(32, MaxVarintLen32)
  test_constant(64, MaxVarintLen64)
}

///|
fn test_constant(w : UInt, max : Int) -> Unit raise {
  let buf = Array::make(MaxVarintLen64, b'\x00')
  // 1<<w - 1
  let x = 1UL << (w.reinterpret_as_int() - 1)
  let n = put_uvarint(buf, x)
  assert_eq(n, max)
}

///|
/// 测试有符号 varint 的编解码、一致性与追加
fn test_varint_one(x : Int64) -> Unit raise {
  let buf = Array::make(MaxVarintLen64, b'\x00')
  let n = put_varint(buf, x)
  buf.resize(n, b'\x00')
  let (y, m) = varint(buf)
  assert_eq(y, x)
  assert_eq(m, n)
  let prefix = b"prefix"
  let buf2 = prefix.to_array()
  append_varint(buf2, x) |> ignore
  let expected = [prefix.to_array(), buf].flatten()
  assert_eq(buf2, expected)
  let yy = read_varint(buf)
  assert_eq(yy, x)
}

///|
/// 测试无符号 varint 的编解码、一致性与追加
fn test_uvarint_one(x : UInt64) -> Unit raise {
  let buf = Array::make(MaxVarintLen64, b'\x00')
  let n = put_uvarint(buf, x)
  buf.resize(n, b'\x00')
  let (y, m) = uvarint(buf)
  assert_eq(y, x)
  assert_eq(m, n)
  let prefix = b"prefix"
  let buf2 = prefix.to_array()
  append_uvarint(buf2, x) |> ignore
  let expected = [prefix.to_array(), buf].flatten()
  assert_eq(buf2, expected)
  let yy = read_uvarint(buf)
  assert_eq(yy, x)
}

///|
test "TestVarint" {
  let tests : Array[Int64] = [
    -(1L << 63),
    -(1L << 63) + 1L,
    -1L,
    0L,
    1L,
    2L,
    10L,
    20L,
    63L,
    64L,
    65L,
    127L,
    128L,
    129L,
    255L,
    256L,
    257L,
    (1L << 63) - 1L,
  ]
  for x in tests {
    test_varint_one(x)
    test_varint_one(-x)
  }
  let mut x = 0x7L
  while x != 0L {
    test_varint_one(x)
    test_varint_one(-x)
    x = x << 1
  }
}

///|
test "TestUvarint" {
  let tests : Array[Int64] = [
    -(1L << 63),
    -(1L << 63) + 1L,
    -1L,
    0L,
    1L,
    2L,
    10L,
    20L,
    63L,
    64L,
    65L,
    127L,
    128L,
    129L,
    255L,
    256L,
    257L,
    (1L << 63) - 1L,
  ]
  for xv in tests {
    test_uvarint_one(xv.reinterpret_as_uint64())
  }
  let mut ux = 0x7UL
  while ux != 0UL {
    test_uvarint_one(ux)
    ux = ux << 1
  }
}

///|
test "TestBufferTooSmall" {
  let base = [b'\x80', b'\x80', b'\x80', b'\x80']
  for i = 0; i <= base.length(); i = i + 1 {
    let part = Array::make(i, b'\x80')
    let bytes = part[:]
    let (val, n) = uvarint(bytes)
    assert_eq(val, 0UL)
    assert_eq(n, 0)
    try {
      read_uvarint(bytes) |> ignore
      fail("should not reach here")
    } catch {
      DecodeError::ErrEOF => assert_true(i == 0)
      DecodeError::ErrUnexpectedEOF => assert_true(i > 0)
      DecodeError::ErrOverflow => assert_true(false)
      e => raise e
    }
  }
}

///|
/// 溢出用例（超过 MaxVarintLen64 字节）
test "TestOverflowBasic" {
  let arr = Array::make(11, b'\xff')
  let bytes = arr[:]
  let (_, n) = uvarint(bytes)
  assert_eq(n, -11)
  try {
    read_uvarint(bytes) |> ignore
    assert_true(false)
  } catch {
    DecodeError::ErrOverflow => ()
    _ => assert_true(false)
  }
}
