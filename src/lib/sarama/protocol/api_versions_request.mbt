///|
pub(all) struct ApiVersionsRequest {
  // Version defines the protocol version to use for encode and decode
  mut version : Int16
  // ClientSoftwareName contains the name of the client.
  mut client_software_name : String
  // ClientSoftwareVersion contains the version of the client.
  mut client_software_version : String
} derive(Show, ToJson, Default)

///|
pub impl Encoder for ApiVersionsRequest with encode(self, pe) {
  if self.version >= 3 {
    pe.put_compact_string(self.client_software_name)
    pe.put_compact_string(self.client_software_version)
    pe.put_empty_tagged_field_array()
  }
}

///|
pub fn[T : PacketDecoder] ApiVersionsRequest::decode(
  pd : T,
  version : Int16,
) -> ApiVersionsRequest raise PacketDecodingError {
  let (client_software_name, client_software_version) = if version >= 3 {
    let client_software_name = pd.get_compact_string()
    let client_software_version = pd.get_compact_string()
    ignore(pd.get_empty_tagged_field_array())
    (client_software_name, client_software_version)
  } else {
    ("", "")
  }
  { version, client_software_name, client_software_version }
}

///|
pub impl ProtocolBody for ApiVersionsRequest with key(self) {
  ApiKeyApiVersions
}

///|
pub impl ProtocolBody for ApiVersionsRequest with version(self) {
  return self.version
}

///|
pub fn ApiVersionsRequest::header_version(version : Int16) -> Int16 {
  if version >= 3 {
    2
  } else {
    1
  }
}

///|
pub impl ProtocolBody for ApiVersionsRequest with header_version(self) {
  ApiVersionsRequest::header_version(self.version)
}

///|
pub impl ProtocolBody for ApiVersionsRequest with is_valid_version(self) {
  return self.version >= 0 && self.version <= 3
}

///|
pub impl ProtocolBody for ApiVersionsRequest with required_version(self) {
  match self.version {
    3 => v2_4_0_0
    2 => v2_0_0_0
    1 => v0_11_0_0
    0 => v0_10_0_0
    _ => v2_4_0_0
  }
}
