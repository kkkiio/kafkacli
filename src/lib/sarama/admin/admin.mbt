///|
/// Administrative functionality for the Sarama Kafka client library
/// This module provides cluster administration capabilities

///|
/// Config resource types
pub enum ConfigResourceType {
  UnknownResource
  TopicResource
  BrokerResource
  BrokerLoggerResource
} derive(Eq, Show, ToJson)

///|
/// Convert ConfigResourceType to int8
pub fn config_resource_type_to_int(resource_type : ConfigResourceType) -> Int {
  match resource_type {
    UnknownResource => 0
    TopicResource => 2
    BrokerResource => 4
    BrokerLoggerResource => 8
  }
}

///|
/// Convert int8 to ConfigResourceType
pub fn int_to_config_resource_type(
  value : Int,
) -> Result[ConfigResourceType, String] {
  match value {
    0 => Ok(UnknownResource)
    2 => Ok(TopicResource)
    4 => Ok(BrokerResource)
    8 => Ok(BrokerLoggerResource)
    _ => Err("Invalid config resource type: " + value.to_string())
  }
}

///|
/// ACL operation types
pub enum AclOperation {
  Unknown
  Any
  All
  Read
  Write
  Create
  Delete
  Alter
  Describe
  ClusterAction
  DescribeConfigs
  AlterConfigs
  IdempotentWrite
} derive(Eq, Show, ToJson)

///|
/// Convert AclOperation to string
pub fn acl_operation_to_string(operation : AclOperation) -> String {
  match operation {
    Unknown => "Unknown"
    Any => "Any"
    All => "All"
    Read => "Read"
    Write => "Write"
    Create => "Create"
    Delete => "Delete"
    Alter => "Alter"
    Describe => "Describe"
    ClusterAction => "ClusterAction"
    DescribeConfigs => "DescribeConfigs"
    AlterConfigs => "AlterConfigs"
    IdempotentWrite => "IdempotentWrite"
  }
}

///|
/// Parse string to AclOperation
pub fn string_to_acl_operation(text : String) -> Result[AclOperation, String] {
  match text.to_lower() {
    "unknown" => Ok(Unknown)
    "any" => Ok(Any)
    "all" => Ok(All)
    "read" => Ok(Read)
    "write" => Ok(Write)
    "create" => Ok(Create)
    "delete" => Ok(Delete)
    "alter" => Ok(Alter)
    "describe" => Ok(Describe)
    "clusteraction" => Ok(ClusterAction)
    "describeconfigs" => Ok(DescribeConfigs)
    "alterconfigs" => Ok(AlterConfigs)
    "idempotentwrite" => Ok(IdempotentWrite)
    _ => Err("No ACL operation with name " + text)
  }
}

///|
/// ACL permission types
pub enum AclPermissionType {
  Unknown
  Any
  Deny
  Allow
} derive(Eq, Show, ToJson)

///|
/// Convert AclPermissionType to string
pub fn acl_permission_type_to_string(permission : AclPermissionType) -> String {
  match permission {
    Unknown => "Unknown"
    Any => "Any"
    Deny => "Deny"
    Allow => "Allow"
  }
}

///|
/// ACL resource types
pub enum AclResourceType {
  Unknown
  Any
  Topic
  Group
  Cluster
  TransactionalId
  DelegationToken
} derive(Eq, Show, ToJson)

///|
/// Convert AclResourceType to string
pub fn acl_resource_type_to_string(resource_type : AclResourceType) -> String {
  match resource_type {
    Unknown => "Unknown"
    Any => "Any"
    Topic => "Topic"
    Group => "Group"
    Cluster => "Cluster"
    TransactionalId => "TransactionalId"
    DelegationToken => "DelegationToken"
  }
}

///|
/// ACL resource pattern types
pub enum AclResourcePatternType {
  Unknown
  Any
  Match
  Literal
  Prefixed
} derive(Eq, Show, ToJson)

///|
/// Convert AclResourcePatternType to string
pub fn acl_resource_pattern_type_to_string(
  pattern_type : AclResourcePatternType,
) -> String {
  match pattern_type {
    Unknown => "Unknown"
    Any => "Any"
    Match => "Match"
    Literal => "Literal"
    Prefixed => "Prefixed"
  }
}

///|
/// ACL resource structure
pub struct AclResource {
  resource_type : AclResourceType
  name : String
  pattern_type : AclResourcePatternType
} derive(Show, ToJson)

///|
/// ACL structure
pub struct Acl {
  principal : String
  host : String
  operation : AclOperation
  permission_type : AclPermissionType
} derive(Show, ToJson)

///|
/// Topic detail structure
pub(all) struct TopicDetail {
  mut num_partitions : Int
  mut replication_factor : Int
  mut replica_assignment : Map[Int, Array[Int]]?
  mut config_entries : Map[String, String]?
} derive(Show, ToJson)

///|
const ConfigSourceDefault : Int = 5

///|
fn build_topic_detail_from_metadata(
  topic : @protocol.TopicMetadata,
) -> TopicDetail raise {
  if topic.err != @protocol.KErrorCode(@protocol.ErrNoError) {
    fail("metadata error for topic \{topic.name}: \{topic.err.to_string()}")
  }
  let num_partitions = topic.partitions.length()
  let replication_factor = if num_partitions > 0 {
    topic.partitions[0].replicas.length()
  } else {
    0
  }
  let replica_assignment = if num_partitions == 0 {
    None
  } else {
    let assignment : Map[Int, Array[Int]] = Map::new()
    for partition in topic.partitions {
      if partition.err != @protocol.KErrorCode(@protocol.ErrNoError) {
        fail(
          "metadata error for topic \{topic.name} partition \{partition.id}: \{partition.err.to_string()}",
        )
      }
      let replicas = Array::new()
      for replica in partition.replicas {
        replicas.push(replica)
      }
      assignment[partition.id] = replicas
    }
    Some(assignment)
  }
  {
    num_partitions,
    replication_factor,
    replica_assignment,
    config_entries: None,
  }
}

///|
fn merge_config_entries(
  topic_details : Map[String, TopicDetail],
  describe_response : @protocol.DescribeConfigsResponse,
) -> Unit raise {
  for resource in describe_response.resources {
    if resource.error_code != @protocol.ErrNoError {
      let err_msg = @protocol.KErrorCode(resource.error_code).to_string()
      fail(
        "describe configs error for topic \{resource.resource_name}: \{err_msg}",
      )
    }
    guard topic_details.get(resource.resource_name) is Some(detail) else {
      continue
    }
    let configs : Map[String, String] = Map::new()
    for entry in resource.configs {
      if entry.is_sensitive {
        continue
      }
      if entry.config_source == ConfigSourceDefault {
        continue
      }
      match entry.value {
        Some(value) => configs[entry.name] = value
        None => ()
      }
    }
    detail.config_entries = Some(configs)
    topic_details[resource.resource_name] = detail
  }
}

///|
/// Config resource structure
pub struct ConfigResource {
  resource_type : ConfigResourceType
  name : String
} derive(Show, ToJson)

///|
/// Config entry structure
pub struct ConfigEntry {
  name : String
  value : String?
  is_default : Bool
  is_sensitive : Bool
  is_read_only : Bool
  source : Int
} derive(Show, ToJson)

///|
/// Incremental alter configs entry structure
pub struct IncrementalAlterConfigsEntry {
  operation : String // "SET", "DELETE", "APPEND", "SUBTRACT"
  value : String?
} derive(Show, ToJson)

///|
/// Topic metadata structure (simplified for admin)
pub struct TopicMetadata {
  error : String?
  is_internal : Bool
  topic : String
  partition_metadata : Array[PartitionMetadata]
} derive(Show, ToJson)

///|
/// Partition metadata structure (simplified for admin)
pub struct PartitionMetadata {
  error : String?
  partition : Int
  leader : Int
  replicas : Array[Int]
  isr : Array[Int]
  offline_replicas : Array[Int]
} derive(Show, ToJson)

///|
/// Partition replica reassignments status
pub struct PartitionReplicaReassignmentsStatus {
  adding_replicas : Array[Int]
  removing_replicas : Array[Int]
} derive(Show, ToJson)

///|
/// User SCRAM credentials description
pub struct UserScramCredentialsDescription {
  name : String
  mechanism : Int
  iterations : Int
} derive(Show, ToJson)

///|
/// User SCRAM credential upsertion
pub struct UserScramCredentialUpsertion {
  name : String
  mechanism : Int
  iterations : Int
  password : String
  salt : Bytes?
} derive(Show, ToJson)

///|
/// User SCRAM credential deletion
pub struct UserScramCredentialDeletion {
  name : String
  mechanism : Int
} derive(Show, ToJson)

///|
/// Client quota filter component
pub struct ClientQuotaFilterComponent {
  entity_type : String
  match_type : String
  name : String?
} derive(Show, ToJson)

///|
/// Client quota description
pub struct ClientQuotaDescription {
  components : Array[ClientQuotaFilterComponent]
  entries : Map[String, Double]
} derive(Show, ToJson)

///|
/// Client quota alter entry
pub struct ClientQuotaAlterEntry {
  components : Array[ClientQuotaFilterComponent]
  operation : String // "SET", "REMOVE"
  value : Double?
} derive(Show, ToJson)

///|
/// Summary information for a consumer group
pub struct ConsumerGroupSummary {
  group_id : String
  protocol_type : String
  state : String
  group_type : String
} derive(Show, ToJson)

///|
/// Offset detail for a consumer group partition
pub struct ConsumerGroupOffset {
  topic : String
  partition : Int
  committed_offset : Int64
  committed_leader_epoch : Int
  metadata : String?
  error_code : Int16
} derive(Show, ToJson)

///|
/// Cluster admin implementation
pub struct KafkaClusterAdmin {
  client : @client.KafkaClient
  conf : @core.Config
  is_closed : Bool
} derive(Show)

///|
/// Create a new cluster admin
pub fn KafkaClusterAdmin::new(
  client : @client.KafkaClient,
) -> KafkaClusterAdmin raise {
  if @client.kafka_client_closed(client) {
    fail("Client is closed")
  }
  { client, conf: @client.kafka_client_config(client), is_closed: false }
}

///|
async fn open_connection(broker : @client.Broker) -> @socket.Tcp {
  let address = @client.broker_address(broker)
  let parts = address.split(":").to_array()
  if parts.length() != 2 {
    fail("invalid broker address: \{address}")
  }
  let host = parts[0]
  let port = @strconv.parse_int(parts[1]) catch {
    err => fail("invalid broker port \{parts[1]}: \{err}")
  }
  let resolved = @socket.Addr::resolve(host.to_string(), port~) catch {
    err => fail("failed to resolve broker address \{host}:\{port}: \{err}")
  }
  @socket.Tcp::connect(resolved) catch {
    err => fail("failed to connect to broker \{address}: \{err}")
  }
}

///|
async fn[T : @protocol.ProtocolBody] send_kafka_request(
  socket : @socket.Tcp,
  request : @protocol.Request[T],
) -> Bytes {
  let packet = @protocol.encode(request)
  socket.write(packet) catch {
    err => fail("failed to send request: \{err}")
  }
  let size_buffer = socket.read_exactly(4) catch {
    err => fail("failed to read response size: \{err}")
  }
  guard size_buffer is [u32be(response_size)] else {
    fail("invalid response size header")
  }
  let response = socket.read_exactly(response_size.reinterpret_as_int()) catch {
    err => fail("failed to read response body: \{err}")
  }
  response
}

///|
pub fn build_consumer_group_summaries(
  response : @protocol.ListGroupsResponse,
) -> Array[ConsumerGroupSummary] {
  let summaries = Array::new()
  for group_id, protocol_type in response.groups {
    let group_data = response.groups_data.get(group_id)
    let state = match group_data {
      Some(data) => data.group_state
      None => ""
    }
    let group_type = match group_data {
      Some(data) => data.group_type
      None => ""
    }
    summaries.push(ConsumerGroupSummary::{
      group_id,
      protocol_type,
      state,
      group_type,
    })
  }
  summaries
}

///|
pub fn build_consumer_group_offsets(
  response : @protocol.OffsetFetchResponse,
) -> Array[ConsumerGroupOffset] {
  let offsets = Array::new()
  for topic_entry in response.topics {
    let topic_name = topic_entry.name
    let partitions = topic_entry.partitions
    for partition in partitions {
      offsets.push(ConsumerGroupOffset::{
        topic: topic_name,
        partition: partition.partition_index,
        committed_offset: partition.committed_offset,
        committed_leader_epoch: partition.committed_leader_epoch,
        metadata: partition.metadata,
        error_code: partition.error_code,
      })
    }
  }
  offsets
}

///|
/// Create topic (placeholder implementation)
pub fn cluster_admin_create_topic(
  admin : KafkaClusterAdmin,
  topic : String,
  detail : TopicDetail,
  validate_only : Bool,
) -> Unit raise {
  // TODO: Implement actual topic creation logic
  ...
}

///|
/// List topics 
async fn cluster_admin_list_topics_impl(
  admin : KafkaClusterAdmin,
  topics : Array[String],
) -> Map[String, TopicDetail] {
  if admin.is_closed {
    fail("cluster admin is closed")
  }
  let brokers = @client.kafka_client_brokers(admin.client)
  if brokers.length() == 0 {
    fail("no brokers available")
  }
  let broker = brokers[0]
  let socket = open_connection(broker)
  defer socket.close()
  let metadata_request = @protocol.MetadataRequest::new(
    admin.conf.version,
    topics,
  )
  let metadata_version = metadata_request.version()
  let metadata_envelope = @protocol.Request::{
    correlation_id: 1,
    client_id: admin.conf.client_id,
    body: metadata_request,
  }
  let metadata_bytes = send_kafka_request(socket, metadata_envelope)
  guard metadata_bytes is [u32be(_), .. metadata_payload] else {
    fail("invalid metadata response payload")
  }
  let metadata_response = @protocol.versioned_decode(
    metadata_payload,
    @protocol.MetadataResponse::decode,
    metadata_version,
  )
  let topics_detail : Map[String, TopicDetail] = Map::new()
  let describe_resources : Array[@protocol.DescribeConfigsRequestResource] = []
  for topic in metadata_response.topics {
    let detail = build_topic_detail_from_metadata(topic)
    topics_detail[topic.name] = detail
    let resource = @protocol.DescribeConfigsRequestResource::new(
      config_resource_type_to_int(TopicResource),
      topic.name,
      None,
    )
    describe_resources.push(resource)
  }
  if describe_resources.length() == 0 {
    return topics_detail
  }
  let describe_request = @protocol.DescribeConfigsRequest::new(
    admin.conf.version,
    describe_resources,
  )
  let describe_version = describe_request.version()
  let describe_envelope = @protocol.Request::{
    correlation_id: 2,
    client_id: admin.conf.client_id,
    body: describe_request,
  }
  let describe_bytes = send_kafka_request(socket, describe_envelope)
  guard describe_bytes is [u32be(_), .. describe_payload] else {
    fail("invalid describe configs response payload")
  }
  let describe_response = @protocol.versioned_decode(
    describe_payload,
    @protocol.DescribeConfigsResponse::decode,
    describe_version,
  )
  merge_config_entries(topics_detail, describe_response)
  topics_detail
}

///|
pub async fn cluster_admin_list_topics(
  admin : KafkaClusterAdmin,
) -> Map[String, TopicDetail] {
  cluster_admin_list_topics_impl(admin, [])
}

///|
pub async fn cluster_admin_list_topics_filtered(
  admin : KafkaClusterAdmin,
  topics : Array[String],
) -> Map[String, TopicDetail] {
  cluster_admin_list_topics_impl(admin, topics)
}

///|
fn error_to_string(err : Error) -> String {
  "\{err}"
}

///|
async fn cluster_admin_list_consumer_groups_impl(
  admin : KafkaClusterAdmin,
) -> Array[ConsumerGroupSummary] {
  if admin.is_closed {
    fail("cluster admin is closed")
  }
  let brokers = @client.kafka_client_brokers(admin.client)
  if brokers.length() == 0 {
    fail("no brokers available")
  }
  let broker = brokers[0]
  let socket = open_connection(broker)
  defer socket.close()
  let request = @protocol.ListGroupsRequest::with_version(5)
  let request_version = request.version()
  let envelope = @protocol.Request::{
    correlation_id: 1,
    client_id: admin.conf.client_id,
    body: request,
  }
  let raw_response = send_kafka_request(socket, envelope)
  guard raw_response is [u32be(_), .. payload] else {
    fail("invalid ListGroupsResponse payload")
  }
  let response = @protocol.versioned_decode(
    payload,
    @protocol.ListGroupsResponse::decode,
    request_version,
  )
  if response.error != @protocol.ErrNoError {
    fail(@protocol.KErrorCode(response.error).to_string())
  }
  let summaries = build_consumer_group_summaries(response)
  summaries
}

///|
pub async fn cluster_admin_list_consumer_groups(
  admin : KafkaClusterAdmin,
) -> Array[ConsumerGroupSummary] {
  cluster_admin_list_consumer_groups_impl(admin)
}

///|
pub async fn cluster_admin_describe_consumer_group_offsets(
  admin : KafkaClusterAdmin,
  group_ids : Array[String],
) -> Map[String, Array[ConsumerGroupOffset]] {
  if admin.is_closed {
    fail("cluster admin is closed")
  }
  let result : Map[String, Array[ConsumerGroupOffset]] = Map::new()
  for group_id in group_ids {
    let broker = @client.kafka_client_coordinator(admin.client, group_id)
    let socket = open_connection(broker)
    defer socket.close()
    let request = @protocol.OffsetFetchRequest::default(group_id.to_string())
    let request_version = request.version()
    let envelope = @protocol.Request::{
      correlation_id: 1,
      client_id: admin.conf.client_id,
      body: request,
    }
    let raw_response = send_kafka_request(socket, envelope)
    guard raw_response is [u32be(_), .. payload] else {
      fail("invalid OffsetFetchResponse payload")
    }
    let response = @protocol.versioned_decode(
      payload,
      @protocol.OffsetFetchResponse::decode,
      request_version,
    )
    if response.error_code != @protocol.ErrNoError {
      fail(@protocol.KErrorCode(response.error_code).to_string())
    }
    let offsets = build_consumer_group_offsets(response)
    result[group_id] = offsets
  }
  result
}

///|
/// Describe topics (placeholder implementation)
pub fn cluster_admin_describe_topics(
  admin : KafkaClusterAdmin,
  topics : Array[String],
) -> Result[Array[TopicMetadata], String] {
  // TODO: Implement actual topic description logic
  Ok([])
}

///|
/// Delete topic (placeholder implementation)
pub fn cluster_admin_delete_topic(
  admin : KafkaClusterAdmin,
  topic : String,
) -> Result[Unit, String] {
  // TODO: Implement actual topic deletion logic
  Ok(())
}

///|
/// Create partitions (placeholder implementation)
pub fn cluster_admin_create_partitions(
  admin : KafkaClusterAdmin,
  topic : String,
  count : Int,
  assignment : Array[Array[Int]],
  validate_only : Bool,
) -> Result[Unit, String] {
  // TODO: Implement actual partition creation logic
  Ok(())
}

///|
/// Alter partition reassignments (placeholder implementation)
pub fn cluster_admin_alter_partition_reassignments(
  admin : KafkaClusterAdmin,
  topic : String,
  assignment : Array[Array[Int]],
) -> Result[Unit, String] {
  // TODO: Implement actual partition reassignment logic
  Ok(())
}

///|
/// List partition reassignments (placeholder implementation)
pub fn cluster_admin_list_partition_reassignments(
  admin : KafkaClusterAdmin,
  topic : String,
  partitions : Array[Int],
) -> Result[Map[String, Map[Int, PartitionReplicaReassignmentsStatus]], String] {
  // TODO: Implement actual partition reassignment listing logic
  Ok(Map::new())
}

///|
/// Delete records (placeholder implementation)
pub fn cluster_admin_delete_records(
  admin : KafkaClusterAdmin,
  topic : String,
  partition_offsets : Map[Int, Int64],
) -> Result[Unit, String] {
  // TODO: Implement actual record deletion logic
  Ok(())
}

///|
/// Describe config (placeholder implementation)
pub fn cluster_admin_describe_config(
  admin : KafkaClusterAdmin,
  resource : ConfigResource,
) -> Result[Array[ConfigEntry], String] {
  // TODO: Implement actual config description logic
  Ok([])
}

///|
/// Alter config (placeholder implementation)
pub fn cluster_admin_alter_config(
  admin : KafkaClusterAdmin,
  resource_type : ConfigResourceType,
  name : String,
  entries : Map[String, String],
  validate_only : Bool,
) -> Result[Unit, String] {
  // TODO: Implement actual config alteration logic
  Ok(())
}

///|
/// Incremental alter config (placeholder implementation)
pub fn cluster_admin_incremental_alter_config(
  admin : KafkaClusterAdmin,
  resource_type : ConfigResourceType,
  name : String,
  entries : Map[String, IncrementalAlterConfigsEntry],
  validate_only : Bool,
) -> Result[Unit, String] {
  // TODO: Implement actual incremental config alteration logic
  Ok(())
}

///|
/// Create single ACL (placeholder implementation)
pub fn cluster_admin_create_acl(
  admin : KafkaClusterAdmin,
  resource : AclResource,
  acl : Acl,
) -> Result[Unit, String] {
  // TODO: Implement actual ACL creation logic
  Ok(())
}

///|
/// Describe user SCRAM credentials (placeholder implementation)
pub fn cluster_admin_describe_user_scram_credentials(
  admin : KafkaClusterAdmin,
  users : Array[String],
) -> Result[Array[UserScramCredentialsDescription], String] {
  // TODO: Implement actual user SCRAM credentials description logic
  Ok([])
}

///|
/// Alter user SCRAM credentials (placeholder implementation)
pub fn cluster_admin_alter_user_scram_credentials(
  admin : KafkaClusterAdmin,
  upsertions : Array[UserScramCredentialUpsertion],
  deletions : Array[UserScramCredentialDeletion],
) -> Result[Unit, String] {
  // TODO: Implement actual user SCRAM credentials alteration logic
  Ok(())
}

///|
/// Describe client quotas (placeholder implementation)
pub fn cluster_admin_describe_client_quotas(
  admin : KafkaClusterAdmin,
  components : Array[ClientQuotaFilterComponent],
  strict : Bool,
) -> Result[Array[ClientQuotaDescription], String] {
  // TODO: Implement actual client quotas description logic
  Ok([])
}

///|
/// Alter client quotas (placeholder implementation)
pub fn cluster_admin_alter_client_quotas(
  admin : KafkaClusterAdmin,
  entries : Array[ClientQuotaAlterEntry],
  validate_only : Bool,
) -> Result[Unit, String] {
  // TODO: Implement actual client quotas alteration logic
  Ok(())
}

///|
/// Close cluster admin (placeholder implementation)
pub fn cluster_admin_close(admin : KafkaClusterAdmin) -> Result[Unit, String] {
  // TODO: Implement actual close logic
  Ok(())
}
