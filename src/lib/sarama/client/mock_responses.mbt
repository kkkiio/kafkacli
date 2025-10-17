///|
/// Mock responses for testing Kafka protocol functionality
/// This module provides mock response builders for testing Kafka client behavior

///|
/// Core trait for all mock responses
/// MockResponse is a response builder interface that defines one method that
/// allows generating a response based on a request body. MockResponses are used
/// to program behavior of MockBroker in tests.
pub trait MockResponse {
  /// Generate a response based on the request body
  for_(self : Self, req_body : &@protocol.VersionedDecoder) -> &@protocol.EncoderWithHeader
}

///|
/// Enum to represent different types of coordinators (replacing interface{})
pub enum MockCoordinator {
  Broker(broker_id~ : Int, addr~ : String)
  Error(error_code~ : Int16)
}

///|
/// Enum to represent different config value types (replacing interface{})
pub enum MockConfigValue {
  StringValue(string~ : String)
  IntValue(int~ : Int)
  BoolValue(bool~ : Bool)
  JsonValue(json~ : Json)
}

///|
/// MockWrapper is a mock response builder that returns a particular concrete
/// response regardless of the actual request passed to the `for_` method.
pub struct MockWrapper {
  res : &@protocol.EncoderWithHeader
}

///|
/// Create a new MockWrapper with the specified response
pub fn mock_wrapper_new(res : &@protocol.EncoderWithHeader) -> MockWrapper {
  { res, }
}

///|
/// Implement MockResponse for MockWrapper
pub impl MockResponse for MockWrapper with for_(self, req_body) {
  self.res
}

///|
/// MockSequence is a mock response builder that is created from a sequence of
/// concrete responses. Every time when a `MockBroker` calls its `for_` method
/// the next response from the sequence is returned. When the end of the
/// sequence is reached the last element from the sequence is returned.
pub struct MockSequence {
  responses : Array[&MockResponse]
}

///|
/// Create a new MockSequence from the specified responses
pub fn mock_sequence_new(responses : Array[&MockResponse]) -> MockSequence {
  { responses, }
}

///|
/// Implement MockResponse for MockSequence
pub impl MockResponse for MockSequence with for_(self, req_body) {
  if self.responses.is_empty() {
    panic() // No responses available
  }
  let response = self.responses[0]
  // If we have more than one response, shift the array
  if self.responses.length() > 1 {
    // self.responses = self.responses[1:]
    self.responses.remove(0) |> ignore
  }
  response.for_(req_body)
}

///|
/// MockListGroupsResponse is a `ListGroupsResponse` builder.
pub struct MockListGroupsResponse {
  groups : Map[String, String]
}

///|
/// Create a new MockListGroupsResponse
pub fn mock_list_groups_response_new() -> MockListGroupsResponse {
  { groups: Map::new() }
}

///|
/// Add a group to the response
pub fn MockListGroupsResponse::add_group(
  self : MockListGroupsResponse,
  group_id : String,
  protocol_type : String,
) -> MockListGroupsResponse {
  self.groups[group_id] = protocol_type
  self
}

///|
/// Implement MockResponse for MockListGroupsResponse
pub impl MockResponse for MockListGroupsResponse with for_(self, req_body) {
  // This would need to decode the request and create a response
  // For now, return a basic response structure
  // let response = @protocol.ListGroupsResponse::new()
  // response.groups = self.groups
  // response
  ...
}

///|
/// MockDescribeGroupsResponse is a `DescribeGroupsResponse` builder.
pub struct MockDescribeGroupsResponse {
  groups : Map[String, GroupDescription]
}

///|
/// Group description structure
pub struct GroupDescription {
  group_id : String
  protocol_type : String
  state : String
  members : Array[GroupMember]
}

///|
/// Group member structure
pub struct GroupMember {
  member_id : String
  client_id : String
  client_host : String
  metadata : Bytes
  assignment : Bytes
}

///|
/// Create a new MockDescribeGroupsResponse
pub fn mock_describe_groups_response_new() -> MockDescribeGroupsResponse {
  { groups: Map::new() }
}

///|
/// Add a group description to the response
pub fn MockDescribeGroupsResponse::add_group_description(
  self : MockDescribeGroupsResponse,
  group_id : String,
  description : GroupDescription,
) -> MockDescribeGroupsResponse {
  self.groups[group_id] = description
  self
}

///|
/// Implement MockResponse for MockDescribeGroupsResponse
pub impl MockResponse for MockDescribeGroupsResponse with for_(self, req_body) {
  // Create response based on request
  // let response = @protocol.DescribeGroupsResponse::new()
  // for group_id, description in self.groups {
  //   response.add_group(description)
  // }
  // response
  ...
}

///|
/// MockMetadataResponse is a `MetadataResponse` builder.
pub struct MockMetadataResponse {
  mut controller_id : Int
  errors : Map[String, Int16]
  leaders : Map[String, Map[Int, Int]]
  brokers : Map[String, Int]
}

///|
/// Create a new MockMetadataResponse
pub fn mock_metadata_response_new() -> MockMetadataResponse {
  {
    controller_id: 0,
    errors: Map::new(),
    leaders: Map::new(),
    brokers: Map::new(),
  }
}

///|
/// Set an error for a topic
pub fn MockMetadataResponse::set_error(
  self : MockMetadataResponse,
  topic : String,
  error_code : Int16,
) -> MockMetadataResponse {
  self.errors[topic] = error_code
  self
}

///|
/// Set the leader for a topic partition
pub fn MockMetadataResponse::set_leader(
  self : MockMetadataResponse,
  topic : String,
  partition : Int,
  broker_id : Int,
) -> MockMetadataResponse {
  if not(self.brokers.contains(topic)) {
    self.leaders[topic] = Map::new()
  }
  self.leaders[topic][partition] = broker_id
  self
}

///|
/// Set a broker
pub fn MockMetadataResponse::set_broker(
  self : MockMetadataResponse,
  addr : String,
  broker_id : Int,
) -> MockMetadataResponse {
  self.brokers[addr] = broker_id
  self
}

///|
/// Set the controller ID
pub fn MockMetadataResponse::set_controller(
  self : MockMetadataResponse,
  broker_id : Int,
) -> MockMetadataResponse {
  self.controller_id = broker_id
  self
}

///|
/// Implement MockResponse for MockMetadataResponse
pub impl MockResponse for MockMetadataResponse with for_(self, req_body) {
  // let response = @protocol.MetadataResponse::new()
  // response.controller_id = self.controller_id

  // // Add brokers
  // for addr, broker_id in self.brokers {
  //   response.add_broker(addr, broker_id)
  // }

  // // Generate replica set from all brokers
  // let replicas = Array::new()
  // for broker_id in self.brokers.values() {
  //   replicas.push(broker_id)
  // }

  // // Add topic partitions
  // for topic, partitions in self.leaders {
  //   for partition, broker_id in partitions {
  //     let error_code = self.errors.get(topic).unwrap_or(0) // ErrNoError
  //     response.add_topic_partition(
  //       topic,
  //       partition,
  //       broker_id,
  //       replicas,
  //       replicas,
  //       Array::new(),
  //       error_code,
  //     )
  //   }
  // }
  // response
  ...
}

///|
/// Mock message structure for fetch responses
pub struct MockMessage {
  key : Bytes
  value : Bytes
}

///|
/// Create a new mock message
pub fn mock_message_new(key : Bytes, value : Bytes) -> MockMessage {
  { key, value }
}

///|
/// MockFetchResponse is a `FetchResponse` builder.
pub struct MockFetchResponse {
  messages : Map[String, Map[Int, Map[Int64, MockMessage]]]
  high_water_marks : Map[String, Map[Int, Int64]]
  batch_size : Int
}

///|
/// Create a new MockFetchResponse
pub fn mock_fetch_response_new(batch_size : Int) -> MockFetchResponse {
  { messages: Map::new(), high_water_marks: Map::new(), batch_size }
}

///|
/// Set a message for a specific topic/partition/offset
pub fn MockFetchResponse::set_message(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
  message : MockMessage,
) -> MockFetchResponse {
  if not(self.messages.contains(topic)) {
    self.messages[topic] = Map::new()
  }
  if not(self.messages[topic].contains(partition)) {
    self.messages[topic][partition] = Map::new()
  }
  self.messages[topic][partition][offset] = message
  self
}

///|
/// Set a message with key and value for a specific topic/partition/offset
pub fn MockFetchResponse::set_message_with_key(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
  key : Bytes,
  value : Bytes,
) -> MockFetchResponse {
  let message = mock_message_new(key, value)
  self.set_message(topic, partition, offset, message)
}

///|
/// Set high water mark for a topic/partition
pub fn MockFetchResponse::set_high_water_mark(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
) -> MockFetchResponse {
  if not(self.high_water_marks.contains(topic)) {
    self.high_water_marks[topic] = Map::new()
  }
  self.high_water_marks[topic][partition] = offset
  self
}

///|
/// Implement MockResponse for MockFetchResponse
pub impl MockResponse for MockFetchResponse with for_(self, req_body) {
  // let response = @protocol.FetchResponse::new()

  // // Process each topic/partition from the request
  // // This is a simplified implementation
  // for topic, partitions in self.messages {
  //   for partition, messages in partitions {
  //     let high_water_mark = self.high_water_marks
  //       .get(topic)
  //       .bind(_.get(partition))
  //       .unwrap_or(0L)

  //     // Add messages to response (simplified)
  //     for offset, message in messages {
  //       response.add_message(
  //         topic,
  //         partition,
  //         message.key,
  //         message.value,
  //         offset,
  //       )
  //     }

  //     // Set high water mark
  //     let block = response.get_block(topic, partition)
  //     if block is Some(block) {
  //       block.high_water_mark_offset = high_water_mark
  //     }
  //   }
  // }
  // response
  ...
}

///|
/// MockProduceResponse is a `ProduceResponse` builder.
pub struct MockProduceResponse {
  mut version : Int16
  errors : Map[String, Map[Int, Int16]]
}

///|
/// Create a new MockProduceResponse
pub fn mock_produce_response_new() -> MockProduceResponse {
  { version: 0, errors: Map::new() }
}

///|
/// Set the version for the response
pub fn MockProduceResponse::set_version(
  self : MockProduceResponse,
  version : Int16,
) -> MockProduceResponse {
  self.version = version
  self
}

///|
/// Set an error for a topic/partition
pub fn MockProduceResponse::set_error(
  self : MockProduceResponse,
  topic : String,
  partition : Int,
  error_code : Int16,
) -> MockProduceResponse {
  if not(self.errors.contains(topic)) {
    self.errors[topic] = Map::new()
  }
  self.errors[topic][partition] = error_code
  self
}

///|
/// Implement MockResponse for MockProduceResponse
pub impl MockResponse for MockProduceResponse with for_(self, req_body) {
  // let response = @protocol.ProduceResponse::new()
  // response.version = self.version

  // // Add errors for each topic/partition
  // for topic, partitions in self.errors {
  //   for partition, error_code in partitions {
  //     response.add_topic_partition(topic, partition, error_code)
  //   }
  // }
  // response
  ...
}

///|
/// MockOffsetResponse is an `OffsetResponse` builder.
pub struct MockOffsetResponse {
  offsets : Map[String, Map[Int, Map[Int64, Int64]]]
}

///|
/// Create a new MockOffsetResponse
pub fn mock_offset_response_new() -> MockOffsetResponse {
  { offsets: Map::new() }
}

///|
/// Set an offset for a topic/partition/time
pub fn MockOffsetResponse::set_offset(
  self : MockOffsetResponse,
  topic : String,
  partition : Int,
  time : Int64,
  offset : Int64,
) -> MockOffsetResponse {
  if not(self.offsets.contains(topic)) {
    self.offsets[topic] = Map::new()
  }
  if not(self.offsets[topic].contains(partition)) {
    self.offsets[topic][partition] = Map::new()
  }
  self.offsets[topic][partition][time] = offset
  self
}

///|
/// Get offset for a topic/partition/time
pub fn MockOffsetResponse::get_offset(
  self : MockOffsetResponse,
  topic : String,
  partition : Int,
  time : Int64,
) -> Int64 raise {
  match self.offsets.get(topic) {
    Some(partitions) =>
      match partitions.get(partition) {
        Some(times) =>
          match times.get(time) {
            Some(offset) => offset
            None => fail("Missing time: " + time.to_string())
          }
        None => fail("Missing partition: " + partition.to_string())
      }
    None => fail("Missing topic: " + topic)
  }
}

///|
/// Implement MockResponse for MockOffsetResponse
pub impl MockResponse for MockOffsetResponse with for_(self, req_body) {
  // let response = OffsetResponse::new()

  // // Process each topic/partition from the request
  // // This is a simplified implementation
  // for topic, partitions in self.offsets {
  //   for partition, times in partitions {
  //     for time, offset in times {
  //       response.add_topic_partition(topic, partition, offset)
  //     }
  //   }
  // }
  // response
  ...
}

///|
/// MockJoinGroupResponse is a `JoinGroupResponse` builder.
pub struct MockJoinGroupResponse {
  mut throttle_time : Int
  mut error_code : Int16
  mut generation_id : Int
  mut group_protocol : String
  mut leader_id : String
  mut member_id : String
  members : Array[GroupMember]
}

///|
/// Create a new MockJoinGroupResponse
pub fn mock_join_group_response_new() -> MockJoinGroupResponse {
  {
    throttle_time: 0,
    error_code: 0, // ErrNoError
    generation_id: 0,
    group_protocol: "",
    leader_id: "",
    member_id: "",
    members: Array::new(),
  }
}

///|
/// Set throttle time
pub fn MockJoinGroupResponse::set_throttle_time(
  self : MockJoinGroupResponse,
  throttle_time : Int,
) -> MockJoinGroupResponse {
  self.throttle_time = throttle_time
  self
}

///|
/// Set error code
pub fn MockJoinGroupResponse::set_error(
  self : MockJoinGroupResponse,
  error_code : Int16,
) -> MockJoinGroupResponse {
  self.error_code = error_code
  self
}

///|
/// Set generation ID
pub fn MockJoinGroupResponse::set_generation_id(
  self : MockJoinGroupResponse,
  generation_id : Int,
) -> MockJoinGroupResponse {
  self.generation_id = generation_id
  self
}

///|
/// Set group protocol
pub fn MockJoinGroupResponse::set_group_protocol(
  self : MockJoinGroupResponse,
  protocol : String,
) -> MockJoinGroupResponse {
  self.group_protocol = protocol
  self
}

///|
/// Set leader ID
pub fn MockJoinGroupResponse::set_leader_id(
  self : MockJoinGroupResponse,
  leader_id : String,
) -> MockJoinGroupResponse {
  self.leader_id = leader_id
  self
}

///|
/// Set member ID
pub fn MockJoinGroupResponse::set_member_id(
  self : MockJoinGroupResponse,
  member_id : String,
) -> MockJoinGroupResponse {
  self.member_id = member_id
  self
}

///|
/// Add a member to the response
pub fn MockJoinGroupResponse::add_member(
  self : MockJoinGroupResponse,
  member_id : String,
  client_id : String,
  client_host : String,
  metadata : Bytes,
) -> MockJoinGroupResponse {
  let member = { member_id, client_id, client_host, metadata, assignment: b"" }
  self.members.push(member)
  self
}

///|
/// Implement MockResponse for MockJoinGroupResponse
pub impl MockResponse for MockJoinGroupResponse with for_(self, req_body) {
  // let response = JoinGroupResponse::new()
  // response.throttle_time_ms = self.throttle_time
  // response.error_code = self.error_code
  // response.generation_id = self.generation_id
  // response.group_protocol = self.group_protocol
  // response.leader_id = self.leader_id
  // response.member_id = self.member_id
  // response.members = self.members
  // response
  ...
}

///|
/// MockSyncGroupResponse is a `SyncGroupResponse` builder.
pub struct MockSyncGroupResponse {
  mut error_code : Int16
  mut member_assignment : Bytes
}

///|
/// Create a new MockSyncGroupResponse
pub fn mock_sync_group_response_new() -> MockSyncGroupResponse {
  {
    error_code: 0, // ErrNoError
    member_assignment: b"",
  }
}

///|
/// Set error code
pub fn MockSyncGroupResponse::set_error(
  self : MockSyncGroupResponse,
  error_code : Int16,
) -> MockSyncGroupResponse {
  self.error_code = error_code
  self
}

///|
/// Set member assignment
pub fn MockSyncGroupResponse::set_member_assignment(
  self : MockSyncGroupResponse,
  assignment : Bytes,
) -> MockSyncGroupResponse {
  self.member_assignment = assignment
  self
}

///|
/// Implement MockResponse for MockSyncGroupResponse
pub impl MockResponse for MockSyncGroupResponse with for_(self, req_body) {
  // let response = SyncGroupResponse::new()
  // response.error_code = self.error_code
  // response.member_assignment = self.member_assignment
  // response
  ...
}

///|
/// MockHeartbeatResponse is a `HeartbeatResponse` builder.
pub struct MockHeartbeatResponse {
  mut error_code : Int16
}

///|
/// Create a new MockHeartbeatResponse
pub fn mock_heartbeat_response_new() -> MockHeartbeatResponse {
  { error_code: 0 } // ErrNoError
}

///|
/// Set error code
pub fn MockHeartbeatResponse::set_error(
  self : MockHeartbeatResponse,
  error_code : Int16,
) -> MockHeartbeatResponse {
  self.error_code = error_code
  self
}

///|
/// Implement MockResponse for MockHeartbeatResponse
pub impl MockResponse for MockHeartbeatResponse with for_(self, req_body) {
  // let response = @protocol.HeartbeatResponse::new()
  // response.error_code = self.error_code
  // response
  ...
}

///|
/// MockLeaveGroupResponse is a `LeaveGroupResponse` builder.
pub struct MockLeaveGroupResponse {
  mut error_code : Int16
}

///|
/// Create a new MockLeaveGroupResponse
pub fn mock_leave_group_response_new() -> MockLeaveGroupResponse {
  { error_code: 0 } // ErrNoError
}

///|
/// Set error code
pub fn MockLeaveGroupResponse::set_error(
  self : MockLeaveGroupResponse,
  error_code : Int16,
) -> MockLeaveGroupResponse {
  self.error_code = error_code
  self
}

///|
/// Implement MockResponse for MockLeaveGroupResponse
pub impl MockResponse for MockLeaveGroupResponse with for_(self, req_body) {
  // let response = LeaveGroupResponse::new()
  // response.error_code = self.error_code
  // response
  ...
}

///|
/// MockDescribeConfigsResponse is a `DescribeConfigsResponse` builder.
pub struct MockDescribeConfigsResponse {
  resources : Array[MockConfigResource]
}

///|
/// Mock config resource structure
pub struct MockConfigResource {
  resource_type : Int
  name : String
  config_entries : Array[MockConfigEntry]
  error_code : Int16
  error_message : String?
}

///|
/// Mock config entry structure
pub struct MockConfigEntry {
  name : String
  value : String
  is_default : Bool
  is_sensitive : Bool
  read_only : Bool
  source : Int16 // ConfigSource
}

///|
/// Create a new MockDescribeConfigsResponse
pub fn mock_describe_configs_response_new() -> MockDescribeConfigsResponse {
  { resources: Array::new() }
}

///|
/// Add a resource to the response
pub fn MockDescribeConfigsResponse::add_resource(
  self : MockDescribeConfigsResponse,
  resource_type : Int,
  name : String,
) -> MockDescribeConfigsResponse {
  let resource = {
    resource_type,
    name,
    config_entries: Array::new(),
    error_code: 0, // ErrNoError
    error_message: None,
  }
  self.resources.push(resource)
  self
}

///|
/// Add a config entry to the last added resource
pub fn MockDescribeConfigsResponse::add_config_entry(
  self : MockDescribeConfigsResponse,
  name : String,
  value : String,
  is_default : Bool,
  is_sensitive : Bool,
  read_only : Bool,
  source : Int16,
) -> MockDescribeConfigsResponse {
  if not(self.resources.is_empty()) {
    let entry = { name, value, is_default, is_sensitive, read_only, source }
    let last_resource = self.resources[self.resources.length() - 1]
    last_resource.config_entries.push(entry)
  }
  self
}

///|
/// Set error for the last added resource
pub fn MockDescribeConfigsResponse::set_resource_error(
  self : MockDescribeConfigsResponse,
  error_code : Int16,
  error_message : String,
) -> MockDescribeConfigsResponse {
  // if not(self.resources.is_empty()) {
  //   let last_resource = self.resources[self.resources.length() - 1]
  //   last_resource.error_code = error_code
  //   last_resource.error_message = Some(error_message)
  // }
  // self
  ...
}

///|
/// Implement MockResponse for MockDescribeConfigsResponse
pub impl MockResponse for MockDescribeConfigsResponse with for_(self, req_body) {
  // let response = DescribeConfigsResponse::new()

  // // Add all resources to response
  // for resource in self.resources {
  //   response.add_resource(
  //     resource.resource_type,
  //     resource.name,
  //     resource.config_entries,
  //     resource.error_code,
  //     resource.error_message,
  //   )
  // }
  // response
  ...
}

///|
/// MockAlterConfigsResponse is an `AlterConfigsResponse` builder.
pub struct MockAlterConfigsResponse {
  resources : Array[MockAlterConfigResource]
}

///|
/// Mock alter config resource structure
pub struct MockAlterConfigResource {
  resource_type : Int
  name : String
  error_code : Int16
  error_message : String
}

///|
/// Create a new MockAlterConfigsResponse
pub fn mock_alter_configs_response_new() -> MockAlterConfigsResponse {
  { resources: Array::new() }
}

///|
/// Add a resource response
pub fn MockAlterConfigsResponse::add_resource(
  self : MockAlterConfigsResponse,
  resource_type : Int,
  name : String,
  error_code : Int16,
  error_message : String,
) -> MockAlterConfigsResponse {
  let resource = { resource_type, name, error_code, error_message }
  self.resources.push(resource)
  self
}

///|
/// Implement MockResponse for MockAlterConfigsResponse
pub impl MockResponse for MockAlterConfigsResponse with for_(self, req_body) {
  // let response = AlterConfigsResponse::new()

  // // Add all resources to response
  // for resource in self.resources {
  //   response.add_resource(
  //     resource.resource_type,
  //     resource.name,
  //     resource.error_code,
  //     resource.error_message,
  //   )
  // }
  // response
  ...
}

///|
/// MockApiVersionsResponse is an `ApiVersionsResponse` builder.
pub struct MockApiVersionsResponse {
  mut api_keys : Array[MockApiKey]
  mut error_code : Int16
}

///|
/// Mock API key structure
pub struct MockApiKey {
  api_key : Int16
  min_version : Int16
  max_version : Int16
}

///|
/// Create a new MockApiVersionsResponse
pub fn mock_api_versions_response_new() -> MockApiVersionsResponse {
  { api_keys: Array::new(), error_code: 0 } // ErrNoError
}

///|
/// Set error code
pub fn MockApiVersionsResponse::set_error(
  self : MockApiVersionsResponse,
  error_code : Int16,
) -> MockApiVersionsResponse {
  self.error_code = error_code
  self
}

///|
/// Add an API key
pub fn MockApiVersionsResponse::add_api_key(
  self : MockApiVersionsResponse,
  api_key : Int16,
  min_version : Int16,
  max_version : Int16,
) -> MockApiVersionsResponse {
  let key = { api_key, min_version, max_version }
  self.api_keys.push(key)
  self
}

///|
/// Set API keys (replace all)
pub fn MockApiVersionsResponse::set_api_keys(
  self : MockApiVersionsResponse,
  api_keys : Array[MockApiKey],
) -> MockApiVersionsResponse {
  self.api_keys = api_keys
  self
}

///|
/// Implement MockResponse for MockApiVersionsResponse
pub impl MockResponse for MockApiVersionsResponse with for_(self, req_body) {
  let response = @protocol.ApiVersionsResponse::default()
  response.error_code = self.error_code

  // Add all API keys to response
  // for api_key in self.api_keys {
  //   response.add_api_key(
  //     api_key.api_key,
  //     api_key.min_version,
  //     api_key.max_version,
  //   )
  // }
  // response
  ...
}

///|
/// MockInitProducerIDResponse is an `InitProducerIDResponse` builder.
pub struct MockInitProducerIDResponse {
  mut producer_id : Int64
  mut producer_epoch : Int16
  mut error_code : Int16
}

///|
/// Create a new MockInitProducerIDResponse
pub fn mock_init_producer_id_response_new() -> MockInitProducerIDResponse {
  { producer_id: 0L, producer_epoch: 0, error_code: 0 } // ErrNoError
}

///|
/// Set producer ID
pub fn MockInitProducerIDResponse::set_producer_id(
  self : MockInitProducerIDResponse,
  producer_id : Int64,
) -> MockInitProducerIDResponse {
  self.producer_id = producer_id
  self
}

///|
/// Set producer epoch
pub fn MockInitProducerIDResponse::set_producer_epoch(
  self : MockInitProducerIDResponse,
  producer_epoch : Int16,
) -> MockInitProducerIDResponse {
  self.producer_epoch = producer_epoch
  self
}

///|
/// Set error code
pub fn MockInitProducerIDResponse::set_error(
  self : MockInitProducerIDResponse,
  error_code : Int16,
) -> MockInitProducerIDResponse {
  self.error_code = error_code
  self
}

///|
/// Implement MockResponse for MockInitProducerIDResponse
pub impl MockResponse for MockInitProducerIDResponse with for_(self, req_body) {
  // let response = InitProducerIDResponse::new()
  // response.producer_id = self.producer_id
  // response.producer_epoch = self.producer_epoch
  // response.error_code = self.error_code
  // response
  ...
}
