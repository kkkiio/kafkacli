///|
pub async fn api_versions(broker : String) -> Unit {
  let parts = broker.split(":").to_array()
  if parts.length() != 2 {
    fail("Invalid broker address format. Expected host:port")
  }
  let host = parts[0]
  let port = @strconv.parse_int(parts[1])
  let addr = @socket.Addr::resolve(host.to_string(), port~) catch {
    err => fail("Failed to resolve address: \{err}, host=\{host}, port=\{port}")
  }
  let socket = @socket.TCP::connect(addr) catch {
    err => fail("Failed to connect to broker: \{err}, addr=\{addr}")
  }
  defer socket.close()
  let body = @protocol.ApiVersionsRequest::{
    version: 3,
    client_software_name: "sarama",
    client_software_version: "0.10.0",
  }
  let req = @protocol.Request::{ body, correlation_id: 123, client_id: "foo" }
  let req_packet = @protocol.encode(req)
  // let request = b"\x00\x00\x00\x24\x00\x12\x00\x03\x00\x00\x00\x01\x00\x07\x72\x64\x6b\x61\x66\x6b\x61\x00\x0b\x6c\x69\x62\x72\x64\x6b\x61\x66\x6b\x61\x06\x32\x2e\x30\x2e\x32\x00"
  socket.write(req_packet)
  guard (socket.read_exactly(4) catch {
      e => fail("Failed to read response size: \{e}")
    })
    is [u32be(response_size)] else {
    fail("Failed to read response size")
  }
  let response_bytes = socket.read_exactly(response_size.reinterpret_as_int())
  guard response_bytes is [u32be(_), .. payload]
  let response = @protocol.ApiVersionsResponse::default()
  @protocol.versioned_decode(payload, response, 3)
  println("response: \{response}")
}
