///|
fn write_i16(buf : @buffer.Buffer, i : Int) -> Unit {
  // buf.write_i16_be(i)
  buf.write_byte(((i >> 8) & 0xFF).to_byte())
  buf.write_byte(i.to_byte())
}

///|
fn write_i32(buf : @buffer.Buffer, i : Int) -> Unit {
  buf.write_int_be(i)
}

///|
fn write_string(buf : @buffer.Buffer, s : String) -> Unit {
  let bytes = @encoding/utf8.encode(s)
  write_i16(buf, bytes.length())
  buf.write_bytes(bytes)
}

///|
fn write_request_header(
  buf : @buffer.Buffer,
  api_key : Int,
  api_version : Int,
  correlation_id : Int,
  client_id : String,
) -> Unit {
  write_i16(buf, api_key)
  write_i16(buf, api_version)
  write_i32(buf, correlation_id)
  // Write client_id as legacy i16-prefixed string to match tests
  write_string(buf, client_id)
}

///|
pub fn encode_api_versions_request(
  correlation_id : Int,
  client_id : String,
  client_software_name : String,
  client_software_version : String,
) -> Bytes {
  let b = @buffer.new()
  // size
  write_i32(b, 0)
  // api_key, api_version, correlation_id
  write_i16(b, 18)
  write_i16(b, 3)
  write_i32(b, correlation_id)
  // client_id 
  let cid = @encoding/utf8.encode(client_id)
  // -- Request header v2 expects client_id as COMPACT_NULLABLE_STRING (length = N+1, encoded as UNSIGNED_VARINT)
  write_uvarint(b, (cid.length() + 1).reinterpret_as_uint())
  b.write_bytes(cid)
  // -- header tagged fields (none)
  write_uvarint(b, 0)
  // client software name 
  let name_bytes = @encoding/utf8.encode(client_software_name)
  // write_i16(b, name_bytes.length() + 1)
  write_uvarint(b, (name_bytes.length() + 1).reinterpret_as_uint())
  b.write_bytes(name_bytes)
  // client software version compact: length+1 then bytes
  let ver = @encoding/utf8.encode(client_software_version)
  write_uvarint(b, (ver.length() + 1).reinterpret_as_uint())
  b.write_bytes(ver)
  // trailing tagged fields zero
  write_uvarint(b, 0)
  let bytes = b.to_bytes().to_fixedarray()
  for i, b in (bytes.length() - 4).to_be_bytes() {
    bytes[i] = b
  }
  Bytes::from_fixedarray(bytes)
}

///|
fn read_tagged_string(reader : BytesView) -> (String, BytesView) raise {
  let (num_tagged_fields, reader) = read_uvarint(reader)
  if num_tagged_fields > 0 {
    let (tag, reader) = read_uvarint(reader)
    if tag == 0 { // Tag 0 is BrokerSoftwareVersion
      let (len, reader) = read_uvarint(reader)
      if len > 0 {
        let real_len = len.reinterpret_as_int() - 1
        return (reader[:real_len].to_string(), reader[real_len:])
      }
    }
  }
  fail("BrokerSoftwareVersion not found")
}

///|
fn skip_api_keys(reader : BytesView) -> BytesView raise {
  // Read compact array size
  let (count, reader) = read_uvarint(reader)
  let mut r = reader
  for i in 0..<count.reinterpret_as_int() {
    // Each ApiKey entry is:
    // api_key: i16be
    // min_version: i16be
    // max_version: i16be
    guard r is [u16be(_), u16be(_), u16be(_), .. reader] else {
      fail("Invalid ApiKey entry format")
    }
    // Skip tagged fields
    let (num_tags, reader) = read_uvarint(reader)
    for j in 0..<num_tags.reinterpret_as_int() {
      let (_tag, reader) = read_uvarint(reader)
      let (len, reader) = read_uvarint(reader)
      r = reader[len.reinterpret_as_int():]
    }
  }
  r
}

///|
pub fn decode_api_versions_response(data : Bytes) -> String raise {
  let reader = data[:]

  // Response header: correlation_id (i32) + tagged fields
  guard reader is [u32be(_), .. reader] else {
    fail("Failed to read correlation id")
  }
  let (_header_tags, reader) = read_uvarint(reader)

  // Error code
  guard reader is [u16be(error_code), .. reader] else {
    fail("Failed to read error code")
  }
  if error_code != 0 {
    fail("Received error code: \{error_code}")
  }

  // Skip ApiKeys
  let reader = skip_api_keys(reader)

  // Throttle time
  guard reader is [u32be(_), .. reader] else {
    fail("Failed to read throttle time")
  }

  // Read BrokerSoftwareVersion from tagged fields
  read_tagged_string(reader).0
}

///|
fn read_compact_string(r : BytesView) -> (String, BytesView) raise {
  let (len, r) = read_uvarint(r)
  if len == 0 {
    return ("", r)
  }
  // len is actual_length + 1
  let real_len = (len - 1).reinterpret_as_int()
  if real_len == 0 {
    return ("", r)
  }
  return (@encoding/utf8.decode(r[:real_len]), r[real_len:])
}

///|
fn skip_compact_array(
  r : BytesView,
  skip_fn : (BytesView) -> BytesView raise,
) -> BytesView raise {
  let (count, r) = read_uvarint(r)
  if count == 0 {
    return r
  }
  let real_count = count - 1
  let mut r = r
  for i in 0..<real_count.reinterpret_as_int() {
    r = skip_fn(r)
  }
  r
}

// 在 Kafka 协议中， UNSIGNED_VARINT 是用来编码一个32位无符号整数的。
// 格式规则：
// 延续位 (Continuation Bit)：每个字节的最高位（Most Significant Bit, MSB）是一个特殊的标志位。
// 如果 MSB 是 1，表示后面还有字节属于同一个整数。
// 如果 MSB 是 0，表示这是这个整数的最后一个字节。
// 数据位：每个字节剩下的 7 位用于存储数据。
// 字节顺序：编码采用小端序（Little-Endian），即整数的低位字节在前。
// 在 Kafka 协议中，为了节省网络传输的数据量，很多地方都使用了这种可变长度编码，特别是在“紧凑”格式（Compact format）中，例如：
// - 表示数组的长度。
// - 表示字符串的长度。
// - 表示标签字段（Tagged Fields）的数量和标签号。

///|
fn read_uvarint(data : BytesView) -> (UInt, BytesView) raise {
  let mut result : UInt = 0
  let mut shift = 0
  for i, b in data.iter().iter2() {
    let byte = b.to_uint()
    result = result | ((byte & 0x7F) << shift)
    if (byte & 0x80) == 0 {
      return (result, data[i + 1:]) // Return the remaining bytes after reading the varint
    }
    shift += 7
    if shift >= 64 {
      fail("Variable-length integer too long")
    }
  }
  fail("Incomplete variable-length integer")
}

///|
fn write_uvarint(buf : @buffer.Buffer, value : UInt) -> Unit {
  let mut value = value
  while value >= 0x80 {
    buf.write_byte(((value & 0x7F) | 0x80).to_byte())
    value = value >> 7
  }
  buf.write_byte((value & 0x7F).to_byte())
}
