///|
enum Transport {
  Console
  Sink
}

///|
pub suberror InvalidTransport StringView derive(Show)

///|
pub fn transport(transport : StringView) -> Transport raise {
  let schema = StringBuilder::new()
  let path : StringView = loop transport {
    [] as path => break path
    [':', .. rest] => break rest
    [c, .. rest] => {
      schema.write_char(c)
      continue rest
    }
  }
  match schema.to_string() {
    "console" => {
      if path != "" {
        raise InvalidTransport(transport)
      }
      Transport::Console
    }
    schema => raise InvalidTransport(schema)
  }
}

///|
async fn Transport::write(self : Transport, content : Json) -> Unit {
  match self {
    Console => println(content.stringify())
    Sink => ()
  }
}

///|
fn Transport::close(self : Transport) -> Unit {
  match self {
    Console => ()
    Sink => ()
  }
}

///|
pub fn Transport::console() -> Transport {
  Transport::Console
}

///|
pub fn Transport::sink() -> Transport {
  Transport::Sink
}
