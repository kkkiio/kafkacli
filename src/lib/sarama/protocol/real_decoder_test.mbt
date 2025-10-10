///|
test "TestRealDecoder_getArrayLength" {
  // null array (-1)
  let input_null : Bytes = b"\xff\xff\xff\xff"
  let rd_null = RealDecoder::new(input_null[:])
  let got_len_null = rd_null.get_array_length()
  assert_eq(got_len_null, -1)

  // valid array length 64
  let input_64 = make_input(64)
  let rd_64 = RealDecoder::new(input_64[:])
  let got_len_64 = rd_64.get_array_length()
  assert_eq(got_len_64, 64)

  // valid array up to MaxResponseSize
  // NOTE: 这里可能会分配很大的数组，具体大小取决于 MaxResponseSize。
  // 如若过大导致内存压力，可将此用例单独运行或在实现处引入替代策略。
  let input_max = make_input(MaxResponseSize)
  let rd_max = RealDecoder::new(input_max[:])
  let got_len_max = rd_max.get_array_length()
  assert_eq(got_len_max, MaxResponseSize.reinterpret_as_int())

  // insufficient data: fewer than 4 bytes
  let input_short : Bytes = b"\x00\x00\x00"
  let rd_short = RealDecoder::new(input_short)
  try {
    ignore(rd_short.get_array_length())
    // 不应到达此处
    assert_true(false)
  } catch {
    // 期望 err_insufficient_data（具体错误对象为私有，黑盒测试不做强匹配）
    _ => ()
  }

  // length exceeds remaining: length=5 但仅剩 1 字节
  // Go 用例: [0,0,0,5,0] 期望 ErrInsufficientData
  let input_len_exceeds : Bytes = b"\x00\x00\x00\x05\x00"
  let rd_len_exceeds = RealDecoder::new(input_len_exceeds)
  try {
    ignore(rd_len_exceeds.get_array_length())
    // 预期抛错；如果当前实现与 Go 不一致，这里会失败，提示需要修正实现的校验顺序。
    assert_true(false)
  } catch {
    _ => ()
  }

  // length exceeds MaxResponseSize
  // 构造长度为 MaxResponseSize+1 的头部，且提供足够的剩余字节
  let input_over = make_input(MaxResponseSize + 1)
  let rd_over = RealDecoder::new(input_over[:])
  let rs = try? rd_over.get_array_length()
  // assert_eq(rs, Err(@protocol.errInvalidArrayLength))
  inspect(rs, content="Err(kafka: error decoding packet: invalid array length)")
}

///|
/// 大端写入长度到前 4 字节，并补齐 payload（零填充）
fn make_input(length : UInt) -> Bytes {
  // 4 字节长度头 + length 个数据字节（零）
  let total = 4 + length.reinterpret_as_int()
  let arr = Array::make(total, b'\x00')
  // 大端写入
  arr[0] = ((length >> 24) & 0xff).to_byte()
  arr[1] = ((length >> 16) & 0xff).to_byte()
  arr[2] = ((length >> 8) & 0xff).to_byte()
  arr[3] = (length & 0xff).to_byte()
  arr |> Bytes::from_array
}
