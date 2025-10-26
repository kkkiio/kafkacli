///|
/// DescribeConfigs request resource represents a single Kafka resource to inspect.
pub(all) struct DescribeConfigsRequestResource {
  mut version : Int16
  mut resource_type : Int
  mut resource_name : String
  mut configuration_keys : Array[String]?
} derive(Show, ToJson, Eq)

///|
/// Create a new DescribeConfigs resource entry.
pub fn DescribeConfigsRequestResource::new(
  resource_type : Int,
  resource_name : String,
  configuration_keys : Array[String]?,
) -> DescribeConfigsRequestResource {
  {
    version: 1,
    resource_type,
    resource_name,
    configuration_keys,
  }
}

///|
/// Encode DescribeConfigs resource according to protocol version.
pub impl KafkaEncoder for DescribeConfigsRequestResource with encode(self, pe) {
  if self.version < 1 || self.version > 4 {
    raise PacketEncodingError(
      "invalid DescribeConfigsRequestResource version (\{self.version})",
    )
  }

  pe.put_byte(self.resource_type.to_byte())
  if self.version >= 4 {
    pe.put_compact_string(self.resource_name)
  } else {
    pe.put_string(self.resource_name)
  }

  match self.configuration_keys {
    None => {
      if self.version >= 4 {
        pe.put_uvarint(0)
      } else {
        pe.put_array_length(-1)
      }
    }
    Some(keys) => {
      if self.version >= 4 {
        pe.put_compact_array_length(keys.length())
        for key in keys {
          pe.put_compact_string(key)
        }
      } else {
        pe.put_array_length(keys.length())
        for key in keys {
          pe.put_string(key)
        }
      }
    }
  }

  if self.version >= 4 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode DescribeConfigs resource entry from packet decoder.
pub fn[T : PacketDecoder] DescribeConfigsRequestResource::decode(
  pd : T,
  version : Int16,
) -> DescribeConfigsRequestResource raise PacketDecodingError {
  if version < 1 || version > 4 {
    raise PacketDecodingError(
      "invalid DescribeConfigsRequestResource version (\{version})",
    )
  }

  let resource_type = pd.get_byte().to_int()
  let resource_name = if version >= 4 {
    pd.get_compact_string()
  } else {
    pd.get_string()
  }

  let configuration_keys = if version >= 4 {
    let length_indicator = pd.get_uvarint()
    if length_indicator == 0 {
      None
    } else {
      let length = length_indicator.to_int() - 1
      let keys = Array::new()
      if length > 0 {
        keys.reserve_capacity(length)
        for _ in 0..<length {
          keys.push(pd.get_compact_string())
        }
      }
      Some(keys)
    }
  } else {
    let length = pd.get_int()
    if length < 0 {
      None
    } else {
      let keys = Array::new()
      if length > 0 {
        keys.reserve_capacity(length)
        for _ in 0..<length {
          keys.push(pd.get_string())
        }
      }
      Some(keys)
    }
  }

  if version >= 4 {
    ignore(pd.get_empty_tagged_field_array())
  }

  {
    version,
    resource_type,
    resource_name,
    configuration_keys,
  }
}

///|
/// DescribeConfigs request payload for querying topic or broker configuration.
pub(all) struct DescribeConfigsRequest {
  mut version : Int16
  mut resources : Array[DescribeConfigsRequestResource]
  mut include_synonyms : Bool
  mut include_documentation : Bool
} derive(Show, ToJson, Eq)

///|
/// Construct DescribeConfigs request by negotiating Kafka core version.
pub fn DescribeConfigsRequest::new(
  kafka_version : KafkaVersion,
  resources : Array[DescribeConfigsRequestResource],
) -> DescribeConfigsRequest {
  let mut version : Int16 = 1
  if kafka_version.is_at_least(v2_3_0_0) {
    version = 4
  } else if kafka_version.is_at_least(v2_0_0_0) {
    version = 3
  } else if kafka_version.is_at_least(v1_1_0_0) {
    version = 2
  } else if kafka_version.is_at_least(v0_11_0_0) {
    version = 1
  }
  {
    version,
    resources,
    include_synonyms: false,
    include_documentation: false,
  }
}

///|
/// Helper to create request with explicit protocol version.
pub fn DescribeConfigsRequest::with_version(
  version : Int16,
  resources : Array[DescribeConfigsRequestResource],
) -> DescribeConfigsRequest {
  {
    version,
    resources,
    include_synonyms: false,
    include_documentation: false,
  }
}

///|
pub impl Default for DescribeConfigsRequest with default() {
  {
    version: 1,
    resources: [],
    include_synonyms: false,
    include_documentation: false,
  }
}

///|
/// Encode DescribeConfigs request body.
pub impl KafkaEncoder for DescribeConfigsRequest with encode(self, pe) {
  if self.version < 1 || self.version > 4 {
    raise PacketEncodingError(
      "invalid DescribeConfigsRequest version (\{self.version})",
    )
  }

  if self.version >= 4 {
    pe.put_compact_array_length(self.resources.length())
  } else {
    pe.put_array_length(self.resources.length())
  }
  for resource in self.resources {
    resource.version = self.version
    resource.encode(pe)
  }

  pe.put_bool(self.include_synonyms)
  if self.version >= 3 {
    pe.put_bool(self.include_documentation)
  }

  if self.version >= 4 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode DescribeConfigs request body.
pub fn[T : PacketDecoder] DescribeConfigsRequest::decode(
  pd : T,
  version : Int16,
) -> DescribeConfigsRequest raise PacketDecodingError {
  if version < 1 || version > 4 {
    raise PacketDecodingError(
      "invalid DescribeConfigsRequest version (\{version})",
    )
  }

  let resources = Array::new()
  if version >= 4 {
    let length = pd.get_compact_array_length()
    if length > 0 {
      resources.reserve_capacity(length)
    }
    for _ in 0..<length {
      let resource = DescribeConfigsRequestResource::decode(pd, version)
      resources.push(resource)
    }
  } else {
    let length = pd.get_int()
    if length > 0 {
      resources.reserve_capacity(length)
      for _ in 0..<length {
        let resource = DescribeConfigsRequestResource::decode(pd, version)
        resources.push(resource)
      }
    } else if length < 0 {
      raise PacketDecodingError("resources array length < 0 in DescribeConfigsRequest")
    }
  }

  let include_synonyms = pd.get_bool()
  let include_documentation = if version >= 3 { pd.get_bool() } else { false }

  if version >= 4 {
    ignore(pd.get_empty_tagged_field_array())
  }

  {
    version,
    resources,
    include_synonyms,
    include_documentation,
  }
}

///|
pub impl ProtocolBody for DescribeConfigsRequest with key(_) {
  ApiKeyDescribeConfigs
}

///|
pub impl ProtocolBody for DescribeConfigsRequest with version(self) {
  self.version
}

///|
pub fn DescribeConfigsRequest::header_version(version : Int16) -> Int16 {
  if version >= 4 { 2 } else { 1 }
}

///|
pub impl ProtocolBody for DescribeConfigsRequest with header_version(self) {
  DescribeConfigsRequest::header_version(self.version)
}

///|
pub impl ProtocolBody for DescribeConfigsRequest with is_valid_version(self) {
  self.version >= 1 && self.version <= 4
}

///|
pub impl ProtocolBody for DescribeConfigsRequest with required_version(self) {
  match self.version {
    4 => v2_3_0_0
    3 => v2_0_0_0
    2 => v1_1_0_0
    1 => v0_11_0_0
    _ => v2_0_0_0
  }
}
