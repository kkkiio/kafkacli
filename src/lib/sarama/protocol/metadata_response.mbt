///|
/// Metadata response structures for Kafka protocol
/// Translated from ../sarama/metadata_response.go
/// This replaces the simple definitions in types.mbt

///|
/// Partition metadata contains each partition in the topic
pub(all) struct PartitionMetadata {
  mut version : Int16
  mut err : KError
  mut id : Int
  mut leader : Int
  mut leader_epoch : Int
  mut replicas : Array[Int]
  mut isr : Array[Int]
  mut offline_replicas : Array[Int]
} derive(Show, ToJson, Eq)

///|
/// Encode partition metadata to packet encoder
pub impl Encoder for PartitionMetadata with encode(self, pe) {
  pe.put_int16(self.err.int_value())
  pe.put_int32(self.id)
  pe.put_int32(self.leader)

  // Encode leader epoch for versions 7+
  if self.version >= 7 {
    pe.put_int32(self.leader_epoch)
  }

  // Encode replicas array
  if self.version < 9 {
    pe.put_int32_array(self.replicas)
  } else {
    pe.put_compact_int32_array(self.replicas)
  }

  // Encode ISR array
  if self.version < 9 {
    pe.put_int32_array(self.isr)
  } else {
    pe.put_compact_int32_array(self.isr)
  }

  // Encode offline replicas for versions 5+
  if self.version >= 5 {
    if self.version < 9 {
      pe.put_int32_array(self.offline_replicas)
    } else {
      pe.put_compact_int32_array(self.offline_replicas)
    }
  }

  // Add tagged fields for versions 9+
  if self.version >= 9 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode partition metadata from packet decoder
pub impl VersionedDecoder for PartitionMetadata with decode(self, pd, version) {
  self.version = version
  self.err = KError(pd.get_int16())
  self.id = pd.get_int32()
  self.leader = pd.get_int32()

  // Decode leader epoch for versions 7+
  if self.version >= 7 {
    self.leader_epoch = pd.get_int32()
  }

  // Decode replicas array
  if self.version < 9 {
    self.replicas = pd.get_int32_array()
  } else {
    self.replicas = pd.get_compact_int32_array()
  }

  // Decode ISR array
  if self.version < 9 {
    self.isr = pd.get_int32_array()
  } else {
    self.isr = pd.get_compact_int32_array()
  }

  // Decode offline replicas for versions 5+
  if self.version >= 5 {
    if self.version < 9 {
      self.offline_replicas = pd.get_int32_array()
    } else {
      self.offline_replicas = pd.get_compact_int32_array()
    }
  }

  // Skip tagged fields for versions 9+
  if self.version >= 9 {
    ignore(pd.get_empty_tagged_field_array())
  }
}

///|
/// Topic metadata contains each topic in the response
pub(all) struct TopicMetadata {
  mut version : Int16
  mut err : KError
  mut name : String
  mut uuid : @uuid.UUID
  mut is_internal : Bool
  mut partitions : Array[PartitionMetadata]
  mut topic_authorized_operations : Int
} derive(Show, Eq)

///|
pub impl ToJson for TopicMetadata with to_json(self) {
  {
    "err": self.err.int_value(),
    "name": self.name,
    "uuid": self.uuid.to_string(),
    "is_internal": self.is_internal,
    "partitions": self.partitions.map(partition => partition.to_json()),
    "topic_authorized_operations": self.topic_authorized_operations,
  }
}

///|
/// Encode topic metadata to packet encoder
pub impl Encoder for TopicMetadata with encode(self, pe) {
  pe.put_int16(self.err.int_value())

  // Encode topic name
  if self.version < 9 {
    pe.put_string(self.name)
  } else {
    pe.put_compact_string(self.name)
  }

  // Encode UUID for versions 10+
  if self.version >= 10 {
    pe.put_raw_bytes(self.uuid.to_bytes())
  }

  // Encode is_internal flag for versions 1+
  if self.version >= 1 {
    pe.put_bool(self.is_internal)
  }

  // Encode partitions array
  if self.version < 9 {
    pe.put_array_length(self.partitions.length())
  } else {
    pe.put_compact_array_length(self.partitions.length())
  }
  for partition in self.partitions {
    partition.encode(pe)
  }

  // Encode authorized operations for versions 8+
  if self.version >= 8 {
    pe.put_int32(self.topic_authorized_operations)
  }

  // Add tagged fields for versions 9+
  if self.version >= 9 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode topic metadata from packet decoder
pub impl VersionedDecoder for TopicMetadata with decode(self, pd, version) {
  self.version = version
  self.err = KError(pd.get_int16())

  // Decode topic name
  if self.version < 9 {
    self.name = pd.get_string()
  } else {
    self.name = pd.get_compact_string()
  }

  // Decode UUID for versions 10+
  if self.version >= 10 {
    let uuid_bytes = pd.get_raw_bytes(16)
    self.uuid = (uuid_bytes.to_bytes() |> @uuid.from_bytes) catch {
      e =>
        raise PacketDecodingError("invalid UUID bytes in topic metadata: \{e}")
    }
  }

  // Decode is_internal flag for versions 1+
  if self.version >= 1 {
    self.is_internal = pd.get_bool()
  }

  // Decode partitions array
  let partition_count = if self.version < 9 {
    pd.get_array_length()
  } else {
    pd.get_compact_array_length()
  }
  if partition_count > 0 {
    self.partitions = Array::new(capacity=partition_count)
    for _ in 0..<partition_count {
      let partition = PartitionMetadata::{
        version: self.version,
        err: KError(0),
        id: 0,
        leader: 0,
        leader_epoch: 0,
        replicas: Array::new(),
        isr: Array::new(),
        offline_replicas: Array::new(),
      }
      partition.decode(pd, self.version)
      self.partitions.push(partition)
    }
  }

  // Decode authorized operations for versions 8+
  if self.version >= 8 {
    self.topic_authorized_operations = pd.get_int32()
  }

  // Skip tagged fields for versions 9+
  if self.version >= 9 {
    ignore(pd.get_empty_tagged_field_array())
  }
}

///|
/// Metadata response structure
pub(all) struct MetadataResponse {
  mut version : Int16
  mut throttle_time_ms : Int
  mut brokers : Array[BrokerMetadata]
  mut cluster_id : String?
  mut controller_id : Int
  mut topics : Array[TopicMetadata]
  mut cluster_authorized_operations : Int
} derive(Show, ToJson, Default, Eq)

///|
/// Get API key for metadata response
pub impl ProtocolBody for MetadataResponse with key(_) {
  ApiKeyMetadata
}

///|
/// Get version of metadata response
pub impl ProtocolBody for MetadataResponse with version(self) {
  self.version
}

///|
/// Set version of metadata response
pub impl ProtocolBody for MetadataResponse with set_version(self, version) {
  self.version = version
}

///|
/// Get header version based on response version
pub impl ProtocolBody for MetadataResponse with header_version(self) {
  if self.version >= 9 {
    1
  } else {
    0
  }
}

///|
/// Check if version is valid
pub impl ProtocolBody for MetadataResponse with is_valid_version(self) {
  self.version >= 0 && self.version <= 10
}

///|
/// Get required Kafka version for response version
pub impl ProtocolBody for MetadataResponse with required_version(self) {
  match self.version {
    10 => v2_8_0_0
    9 => v2_4_0_0
    8 => v2_3_0_0
    7 => v2_1_0_0
    6 => v2_0_0_0
    5 => v1_0_0_0
    3 | 4 => v0_11_0_0
    2 => v0_10_1_0
    1 => v0_10_0_0
    0 => v0_8_2_0
    _ => v2_8_0_0
  }
}

///|
/// Encode metadata response to packet encoder
pub impl Encoder for MetadataResponse with encode(self, pe) {
  // Encode throttle time for versions 3+
  if self.version >= 3 {
    pe.put_int32(self.throttle_time_ms)
  }

  // Encode brokers array
  if self.version < 9 {
    pe.put_array_length(self.brokers.length())
  } else {
    pe.put_compact_array_length(self.brokers.length())
  }
  for broker in self.brokers {
    broker.encode(pe)
  }

  // Encode cluster ID for versions 2+
  if self.version >= 2 {
    if self.version < 9 {
      pe.put_nullable_string(self.cluster_id)
    } else {
      pe.put_nullable_compact_string(self.cluster_id)
    }
  }

  // Encode controller ID for versions 1+
  if self.version >= 1 {
    pe.put_int32(self.controller_id)
  }

  // Encode topics array
  if self.version < 9 {
    pe.put_array_length(self.topics.length())
  } else {
    pe.put_compact_array_length(self.topics.length())
  }
  for topic in self.topics {
    topic.encode(pe)
  }

  // Encode cluster authorized operations for versions 8+
  if self.version >= 8 {
    pe.put_int32(self.cluster_authorized_operations)
  }

  // Add tagged fields for versions 9+
  if self.version >= 9 {
    pe.put_empty_tagged_field_array()
  }
}

///|
/// Decode metadata response from packet decoder
pub impl VersionedDecoder for MetadataResponse with decode(self, pd, version) {
  self.version = version

  // Decode throttle time for versions 3+
  if self.version >= 3 {
    self.throttle_time_ms = pd.get_int32()
  }

  // Decode brokers array
  let broker_count = if self.version < 9 {
    pd.get_array_length()
  } else {
    pd.get_compact_array_length()
  }
  if broker_count > 0 {
    self.brokers = Array::new(capacity=broker_count)
    for _ in 0..<broker_count {
      let broker = BrokerMetadata::{
        id: 0,
        host: "",
        port: 0,
        rack: None,
        version: 0,
      }
      broker.decode(pd, self.version)
      self.brokers.push(broker)
    }
  }

  // Decode cluster ID for versions 2+
  if self.version >= 2 {
    if self.version < 9 {
      self.cluster_id = pd.get_nullable_string()
    } else {
      self.cluster_id = pd.get_compact_nullable_string()
    }
  }

  // Decode controller ID for versions 1+
  if self.version >= 1 {
    self.controller_id = pd.get_int32()
  }

  // Decode topics array
  let topic_count = if self.version < 9 {
    pd.get_array_length()
  } else {
    pd.get_compact_array_length()
  }
  if topic_count > 0 {
    self.topics = Array::new(capacity=topic_count)
    for _ in 0..<topic_count {
      let topic = TopicMetadata::{
        version: self.version,
        err: KError(0),
        name: "",
        uuid: null_uuid,
        is_internal: false,
        partitions: Array::new(),
        topic_authorized_operations: 0,
      }
      topic.decode(pd, self.version)
      self.topics.push(topic)
    }
  }

  // Decode cluster authorized operations for versions 8+
  if self.version >= 8 {
    self.cluster_authorized_operations = pd.get_int32()
  }

  // Skip tagged fields for versions 9+
  if self.version >= 9 {
    ignore(pd.get_empty_tagged_field_array())
  }
}
