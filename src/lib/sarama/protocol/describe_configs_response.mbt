///|
/// Synonym entry inside DescribeConfigs response.
pub(all) struct DescribeConfigsSynonym {
  mut version : Int16
  mut name : String
  mut value : String?
  mut source : Int
} derive(Show, ToJson, Eq)

///|
pub impl KafkaEncoder for DescribeConfigsSynonym with encode(self, pe) {
  if self.version < 1 || self.version > 4 {
    raise PacketEncodingError(
      "invalid DescribeConfigsSynonym version (\{self.version})",
    )
  }

  if self.version >= 4 {
    pe.put_compact_string(self.name)
    pe.put_nullable_compact_string(self.value)
  } else {
    pe.put_string(self.name)
    pe.put_nullable_string(self.value)
  }
  pe.put_byte(self.source.to_byte())

  if self.version >= 4 {
    pe.put_empty_tagged_field_array()
  }
}

///|
pub fn[T : PacketDecoder] DescribeConfigsSynonym::decode(
  pd : T,
  version : Int16,
) -> DescribeConfigsSynonym raise PacketDecodingError {
  if version < 1 || version > 4 {
    raise PacketDecodingError(
      "invalid DescribeConfigsSynonym version (\{version})",
    )
  }

  let name = if version >= 4 {
    pd.get_compact_string()
  } else {
    pd.get_string()
  }
  let value = if version >= 4 {
    pd.get_compact_nullable_string()
  } else {
    pd.get_nullable_string()
  }
  let source = pd.get_byte().to_int()

  if version >= 4 {
    ignore(pd.get_empty_tagged_field_array())
  }

  { version, name, value, source }
}

///|
/// Configuration entry returned by DescribeConfigs.
pub(all) struct DescribeConfigsConfig {
  mut version : Int16
  mut name : String
  mut value : String?
  mut read_only : Bool
  mut config_source : Int
  mut is_sensitive : Bool
  mut synonyms : Array[DescribeConfigsSynonym]
  mut config_type : Int
  mut documentation : String?
} derive(Show, ToJson, Eq)

///|
pub impl KafkaEncoder for DescribeConfigsConfig with encode(self, pe) {
  if self.version < 1 || self.version > 4 {
    raise PacketEncodingError(
      "invalid DescribeConfigsConfig version (\{self.version})",
    )
  }

  if self.version >= 4 {
    pe.put_compact_string(self.name)
    pe.put_nullable_compact_string(self.value)
  } else {
    pe.put_string(self.name)
    pe.put_nullable_string(self.value)
  }
  pe.put_bool(self.read_only)
  pe.put_byte(self.config_source.to_byte())
  pe.put_bool(self.is_sensitive)

  if self.version >= 4 {
    pe.put_compact_array_length(self.synonyms.length())
  } else {
    pe.put_array_length(self.synonyms.length())
  }
  for synonym in self.synonyms {
    synonym.version = self.version
    synonym.encode(pe)
  }

  if self.version >= 3 {
    pe.put_byte(self.config_type.to_byte())
    if self.version >= 4 {
      pe.put_nullable_compact_string(self.documentation)
    } else {
      pe.put_nullable_string(self.documentation)
    }
  }

  if self.version >= 4 {
    pe.put_empty_tagged_field_array()
  }
}

///|
pub fn[T : PacketDecoder] DescribeConfigsConfig::decode(
  pd : T,
  version : Int16,
) -> DescribeConfigsConfig raise PacketDecodingError {
  if version < 1 || version > 4 {
    raise PacketDecodingError(
      "invalid DescribeConfigsConfig version (\{version})",
    )
  }

  let name = if version >= 4 { pd.get_compact_string() } else { pd.get_string() }
  let value = if version >= 4 {
    pd.get_compact_nullable_string()
  } else {
    pd.get_nullable_string()
  }
  let read_only = pd.get_bool()
  let config_source = pd.get_byte().to_int()
  let is_sensitive = pd.get_bool()

  let synonyms = Array::new()
  if version >= 4 {
    let length = pd.get_compact_array_length()
    if length > 0 {
      synonyms.reserve_capacity(length)
    }
    for _ in 0..<length {
      let synonym = DescribeConfigsSynonym::decode(pd, version)
      synonyms.push(synonym)
    }
  } else {
    let length = pd.get_int()
    if length > 0 {
      synonyms.reserve_capacity(length)
      for _ in 0..<length {
        let synonym = DescribeConfigsSynonym::decode(pd, version)
        synonyms.push(synonym)
      }
    } else if length < 0 {
      raise PacketDecodingError("synonyms array length < 0 in DescribeConfigsConfig")
    }
  }

  let config_type = if version >= 3 { pd.get_byte().to_int() } else { 0 }
  let documentation = if version >= 3 {
    if version >= 4 {
      pd.get_compact_nullable_string()
    } else {
      pd.get_nullable_string()
    }
  } else {
    None
  }

  if version >= 4 {
    ignore(pd.get_empty_tagged_field_array())
  }

  {
    version,
    name,
    value,
    read_only,
    config_source,
    is_sensitive,
    synonyms,
    config_type,
    documentation,
  }
}

///|
/// Response entry for a single resource.
pub(all) struct DescribeConfigsResource {
  mut version : Int16
  mut error_code : Int16
  mut error_message : String?
  mut resource_type : Int
  mut resource_name : String
  mut configs : Array[DescribeConfigsConfig]
} derive(Show, ToJson, Eq)

///|
pub impl KafkaEncoder for DescribeConfigsResource with encode(self, pe) {
  if self.version < 1 || self.version > 4 {
    raise PacketEncodingError(
      "invalid DescribeConfigsResource version (\{self.version})",
    )
  }

  pe.put_int16(self.error_code)
  if self.version >= 4 {
    pe.put_nullable_compact_string(self.error_message)
  } else {
    pe.put_nullable_string(self.error_message)
  }
  pe.put_byte(self.resource_type.to_byte())
  if self.version >= 4 {
    pe.put_compact_string(self.resource_name)
    pe.put_compact_array_length(self.configs.length())
  } else {
    pe.put_string(self.resource_name)
    pe.put_array_length(self.configs.length())
  }

  for config in self.configs {
    config.version = self.version
    config.encode(pe)
  }

  if self.version >= 4 {
    pe.put_empty_tagged_field_array()
  }
}

///|
pub fn[T : PacketDecoder] DescribeConfigsResource::decode(
  pd : T,
  version : Int16,
) -> DescribeConfigsResource raise PacketDecodingError {
  if version < 1 || version > 4 {
    raise PacketDecodingError(
      "invalid DescribeConfigsResource version (\{version})",
    )
  }

  let error_code = pd.get_int16()
  let error_message = if version >= 4 {
    pd.get_compact_nullable_string()
  } else {
    pd.get_nullable_string()
  }
  let resource_type = pd.get_byte().to_int()
  let resource_name = if version >= 4 {
    pd.get_compact_string()
  } else {
    pd.get_string()
  }

  let configs = Array::new()
  if version >= 4 {
    let length = pd.get_compact_array_length()
    if length > 0 {
      configs.reserve_capacity(length)
    }
    for _ in 0..<length {
      let config = DescribeConfigsConfig::decode(pd, version)
      configs.push(config)
    }
  } else {
    let length = pd.get_int()
    if length > 0 {
      configs.reserve_capacity(length)
      for _ in 0..<length {
        let config = DescribeConfigsConfig::decode(pd, version)
        configs.push(config)
      }
    } else if length < 0 {
      raise PacketDecodingError("configs array length < 0 in DescribeConfigsResponse")
    }
  }

  if version >= 4 {
    ignore(pd.get_empty_tagged_field_array())
  }

  {
    version,
    error_code,
    error_message,
    resource_type,
    resource_name,
    configs,
  }
}

///|
/// DescribeConfigs response body returned by broker.
pub(all) struct DescribeConfigsResponse {
  mut version : Int16
  mut throttle_time_ms : Int
  mut resources : Array[DescribeConfigsResource]
} derive(Show, ToJson, Eq)

///|
pub impl KafkaEncoder for DescribeConfigsResponse with encode(self, pe) {
  if self.version < 1 || self.version > 4 {
    raise PacketEncodingError(
      "invalid DescribeConfigsResponse version (\{self.version})",
    )
  }

  pe.put_int(self.throttle_time_ms)
  if self.version >= 4 {
    pe.put_compact_array_length(self.resources.length())
  } else {
    pe.put_array_length(self.resources.length())
  }
  for resource in self.resources {
    resource.version = self.version
    resource.encode(pe)
  }

  if self.version >= 4 {
    pe.put_empty_tagged_field_array()
  }
}

///|
pub fn[T : PacketDecoder] DescribeConfigsResponse::decode(
  pd : T,
  version : Int16,
) -> DescribeConfigsResponse raise PacketDecodingError {
  if version < 1 || version > 4 {
    raise PacketDecodingError(
      "invalid DescribeConfigsResponse version (\{version})",
    )
  }

  let throttle_time_ms = pd.get_int()
  let resources = Array::new()
  if version >= 4 {
    let length = pd.get_compact_array_length()
    if length > 0 {
      resources.reserve_capacity(length)
    }
    for _ in 0..<length {
      let resource = DescribeConfigsResource::decode(pd, version)
      resources.push(resource)
    }
  } else {
    let length = pd.get_int()
    if length > 0 {
      resources.reserve_capacity(length)
      for _ in 0..<length {
        let resource = DescribeConfigsResource::decode(pd, version)
        resources.push(resource)
      }
    } else if length < 0 {
      raise PacketDecodingError("resources array length < 0 in DescribeConfigsResponse")
    }
  }

  if version >= 4 {
    ignore(pd.get_empty_tagged_field_array())
  }

  { version, throttle_time_ms, resources }
}
