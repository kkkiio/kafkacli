///|
pub async fn api_versions(
  _tg : @async.TaskGroup[Unit],
  broker : String,
) -> String {
  let parts = broker.split(":").to_array()
  if parts.length() != 2 {
    fail("Invalid broker address format. Expected host:port")
  }
  let host = parts[0]
  let port = @strconv.parse_int(parts[1])
  let addr = @socket.Addr::resolve(@encoding/utf8.encode(host), port~) catch {
    err => fail("Failed to resolve address: \{err}, host=\{host}, port=\{port}")
  }
  println("Resolved \{host}:\{port} to \{addr}")
  let socket = @socket.TCP::connect(addr) catch {
    err => fail("Failed to connect to broker: \{err}, addr=\{addr}")
  }
  defer socket.close()
  let request = encode_api_versions_request(1, "rdkafka", "librdkafka", "2.0.2")
  // let request = b"\x00\x00\x00\x24\x00\x12\x00\x03\x00\x00\x00\x01\x00\x07\x72\x64\x6b\x61\x66\x6b\x61\x00\x0b\x6c\x69\x62\x72\x64\x6b\x61\x66\x6b\x61\x06\x32\x2e\x30\x2e\x32\x00"
  println(
    "Request size: \{request.length()}, bytes: \{@crypto.bytes_to_hex_string(request)}",
  )
  socket.write(request)
  guard (socket.read_exactly(4) catch {
      e => fail("Failed to read response size: \{e}")
    })
    is [u32be(response_size)] else {
    fail("Failed to read response size")
  }
  println("Response size: \{response_size}")
  let response_bytes = socket.read_exactly(response_size.reinterpret_as_int())
  println("Response bytes size: \{response_bytes.length()}")
  decode_api_versions_response(response_bytes)
}
