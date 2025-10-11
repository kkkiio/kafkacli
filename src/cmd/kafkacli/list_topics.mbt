///|
pub async fn list_topics(broker : String) -> Unit {
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

  // Create empty MetadataRequest to get all topics
  let body = @protocol.MetadataRequest::new(@protocol.default_version, [])
  let req = @protocol.Request::{ body, correlation_id: 123, client_id: "kafkacli" }
  let req_packet = @protocol.encode(req)
  socket.write(req_packet)

  // Read response size
  guard (socket.read_exactly(4) catch {
      e => fail("Failed to read response size: \{e}")
    })
    is [u32be(response_size)] else {
    fail("Failed to read response size")
  }

  // Read response body
  let response_bytes = socket.read_exactly(response_size.reinterpret_as_int())
  guard response_bytes is [u32be(_), .. payload]

  // Decode MetadataResponse
  let response = @protocol.MetadataResponse::default()
  @protocol.versioned_decode(payload, response, body.version)

  // Print topic names, filtering out internal topics
  for topic in response.topics {
    if !topic.is_internal && topic.err.int_value() == 0 {
      println(topic.name)
    }
  }
}