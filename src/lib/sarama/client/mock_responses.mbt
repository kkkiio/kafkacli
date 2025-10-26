///|
/// MockResponse is a response builder interface it defines one method that
/// allows generating a response based on a request body. MockResponses are used
/// to program behavior of MockBroker in tests.
pub typealias (@protocol.ProtocolBodyAdapter) -> &@protocol.ProtocolBody as MockResponse

///|
/// MockOffsetResponse is an `OffsetResponse` builder.
pub struct MockOffsetResponse {
  offsets : Map[String, Map[Int, Map[Int64, Int64]]]
}

///|
pub fn MockOffsetResponse::new() -> MockOffsetResponse {
  { offsets: Map::new() }
}

///|
pub fn MockOffsetResponse::set_offset(
  self : MockOffsetResponse,
  topic : String,
  partition : Int,
  time : Int64,
  offset : Int64,
) -> Unit {
  let partitions = self.offsets.get_or_init(topic, fn() { Map::new() })
  let times = partitions.get_or_init(partition, fn() { Map::new() })
  times[time] = offset
}

///|
pub fn MockOffsetResponse::for_request(
  self : MockOffsetResponse,
  reqBody : @protocol.ProtocolBodyAdapter,
) -> @protocol.OffsetResponse {
  ...
}

///|
pub fn MockOffsetResponse::get_offset(
  self : MockOffsetResponse,
  topic : String,
  partition : Int,
  time : Int64,
) -> Int64 raise {
  guard self.offsets.get(topic) is Some(partitions) else {
    fail("missing topic: \{topic}")
  }
  let times = partitions.get(partition)
  guard times is Some(times) else { fail("missing partition: \{partition}") }
  let offset = times.get(time)
  guard offset is Some(offset) else { fail("missing time: \{time}") }
  offset
}

///|
/// mockMessage is a message that used to be mocked for `FetchResponse`
struct MockMessage {
  key : &@protocol.MessageEncoder?
  msg : &@protocol.MessageEncoder
}

///|
pub fn MockMessage::new(
  key : &@protocol.MessageEncoder?,
  msg : &@protocol.MessageEncoder,
) -> MockMessage {
  { key, msg }
}

///|
/// MockFetchResponse is a `FetchResponse` builder.
struct MockFetchResponse {
  messages : Map[String, Map[Int, Map[Int64, MockMessage]]]
  highWaterMarks : Map[String, Map[Int, Int64]]
  batchSize : Int
}

///|
pub fn MockFetchResponse::new(batchSize : Int) -> MockFetchResponse {
  ...
}

///|
pub fn MockFetchResponse::set_message(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
  msg : &@protocol.MessageEncoder,
) -> Unit {
  return self.set_message_with_key(topic, partition, offset, None, msg)
}

///|
pub fn MockFetchResponse::set_message_with_key(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
  key : &@protocol.MessageEncoder?,
  msg : &@protocol.MessageEncoder,
) -> Unit {
  let partitions = self.messages.get_or_init(topic, fn() { Map::new() })
  let messages = partitions.get_or_init(partition, fn() { Map::new() })
  messages[offset] = MockMessage::new(key, msg)
}

///|
pub fn MockFetchResponse::set_high_water_mark(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
) -> Unit {
  let partitions = self.highWaterMarks.get_or_init(topic, fn() { Map::new() })
  partitions[partition] = offset
}

///|
fn encode_kv(
  key : &@protocol.MessageEncoder?,
  value : &@protocol.MessageEncoder?,
) -> (Bytes, Bytes) raise {
  let kb = if key is Some(key) { key.encode() } else { b"" }
  let vb = if value is Some(value) { value.encode() } else { b"" }
  (kb, vb)
}

///|
pub fn MockFetchResponse::for_request(
  self : MockFetchResponse,
  reqBody : @protocol.ProtocolBodyAdapter,
) -> @protocol.FetchResponse {
  guard reqBody is Fetch(fetchRequest)
  let fetchResponse = @protocol.FetchResponse::{
    version: fetchRequest.version,
    throttle_time_ms: 0,
    error_code: 0,
    session_id: 0,
    blocks: Map::new(),
  }
  for topic, partitions in fetchRequest.blocks {
    for partition, block in partitions {
      let initialOffset = block.fetch_offset
      let mut offset = initialOffset
      let maxOffset = initialOffset +
        self.get_message_count(topic, partition).to_int64()
      let mut i = 0
      while i < self.batchSize && offset < maxOffset {
        let msg = self.get_message(topic, partition, offset)
        if msg is Some(msg) {
          fetch_response_add_message(
            fetchResponse,
            topic,
            partition,
            msg.key,
            msg.msg,
            offset,
          )
          i += 1
        }
        offset = offset + 1
      }
      let fb = fetchResponse
        .get_block(topic, partition)
        .or_else(fn() {
          fetchResponse.add_error(topic, partition, @protocol.ErrNoError)
          fetchResponse.get_block(topic, partition).unwrap()
        })
      fb.high_watermark_offset = self.get_high_water_mark(topic, partition)
    }
  }
  fetchResponse
}

///|
pub fn MockFetchResponse::get_message(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
  offset : Int64,
) -> MockMessage? {
  guard self.messages.get(topic) is Some(partitions) else { return None }
  guard partitions.get(partition) is Some(messages) else { return None }
  guard messages.get(offset) is Some(msg) else { return None }
  Some(msg)
}

///|
pub fn MockFetchResponse::get_message_count(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
) -> Int {
  guard self.messages.get(topic) is Some(partitions) else { return 0 }
  guard partitions.get(partition) is Some(messages) else { return 0 }
  messages.length()
}

///|
pub fn MockFetchResponse::get_high_water_mark(
  self : MockFetchResponse,
  topic : String,
  partition : Int,
) -> Int64 {
  guard self.highWaterMarks.get(topic) is Some(partitions) else { return 0 }
  guard partitions.get(partition) is Some(offset) else { return 0 }
  offset
}

///|
/// MockMetadataResponse is a `MetadataResponse` builder.
pub struct MockMetadataResponse {
  controller_id : Int
  errors : Map[String, Int16]
  leaders : Map[String, Map[Int, Int]]
  brokers : Map[String, Int]
}

///|
pub fn MockMetadataResponse::new() -> MockMetadataResponse {
  {
    controller_id: 0,
    errors: Map::new(),
    leaders: Map::new(),
    brokers: Map::new(),
  }
}

///|
pub fn MockMetadataResponse::set_error(
  self : MockMetadataResponse,
  topic : String,
  kerror : Int16,
) -> Unit {
  self.errors[topic] = kerror
}

///|
pub fn MockMetadataResponse::set_leader(
  self : MockMetadataResponse,
  topic : String,
  partition : Int,
  brokerID : Int,
) -> Unit {
  let partitions = self.leaders.get_or_init(topic, fn() { Map::new() })
  partitions[partition] = brokerID
}

///|
pub fn MockMetadataResponse::set_broker(
  self : MockMetadataResponse,
  addr : String,
  brokerID : Int,
) -> Unit {
  self.brokers[addr] = brokerID
}

///|
pub fn MockMetadataResponse::for_request(
  self : MockMetadataResponse,
  reqBody : @protocol.ProtocolBodyAdapter,
) -> @protocol.MetadataResponse {
  guard reqBody is Metadata(reqBody)
  let metadataResponse = @protocol.MetadataResponse::{
    version: reqBody.version,
    controller_id: self.controller_id,
    throttle_time_ms: 0,
    brokers: Array::new(),
    cluster_id: None,
    topics: Array::new(),
    cluster_authorized_operations: 0,
  }
  for addr, brokerID in self.brokers {
    metadata_response_add_broker(metadataResponse, addr, brokerID)
  }

  // Generate set of replicas
  let replicas = self.brokers.values().to_array()
  let offlineReplicas = []
  if reqBody.topics.length() == 0 {
    for topic, partitions in self.leaders {
      for partition, brokerID in partitions {
        let _ = metadata_response_add_topic_partition(
          metadataResponse,
          topic,
          partition,
          brokerID,
          replicas,
          replicas,
          offlineReplicas,
          ErrNoError,
        )

      }
    }
    for topic, err in self.errors {
      let _ = metadata_response_add_topic(metadataResponse, topic, err)

    }
    return metadataResponse
  }
  for topic in reqBody.topics {
    let leaders = self.leaders.get(topic)
    guard leaders is Some(leaders) else {
      // if err, ok := mmr.errors[topic]; ok {
      if self.errors.get(topic) is Some(err) {
        let _ = metadata_response_add_topic(metadataResponse, topic, err)

      } else {
        let _ = metadata_response_add_topic(
          metadataResponse,
          topic,
          @protocol.ErrUnknownTopicOrPartition,
        )

      }
      continue
    }
    for partition, brokerID in leaders {
      let _ = metadata_response_add_topic_partition(
        metadataResponse,
        topic,
        partition,
        brokerID,
        replicas,
        replicas,
        offlineReplicas,
        @protocol.ErrNoError,
      )

    }
  }
  return metadataResponse
}

///|
fn metadata_response_add_broker(
  r : @protocol.MetadataResponse,
  addr : String,
  id : Int,
) -> Unit {
  let (host, port) = try! @protocol.split_host_port(addr)
  r.brokers.push(@protocol.BrokerMetadata::{
    id,
    host,
    port,
    rack: None,
    version: 0,
  })
}

///|
fn metadata_response_add_topic(
  r : @protocol.MetadataResponse,
  topic : String,
  err : Int16,
) -> @protocol.TopicMetadata {
  let tm = r.topics
    .iter()
    .find_first(tm => tm.name == topic)
    .unwrap_or_else(fn() {
      let tm = @protocol.TopicMetadata::{
        name: topic,
        err,
        partitions: Array::new(),
        version: 0,
        uuid: @protocol.null_uuid,
        is_internal: false,
        topic_authorized_operations: 0,
      }
      r.topics.push(tm)
      tm
    })
  tm.err = err
  return tm
}

///|
fn metadata_response_add_topic_partition(
  r : @protocol.MetadataResponse,
  topic : String,
  partition : Int,
  brokerID : Int,
  replicas : Array[Int],
  isr : Array[Int],
  offline : Array[Int],
  err : Int16,
) -> @protocol.PartitionMetadata {
  let tm = metadata_response_add_topic(r, topic, @protocol.ErrNoError)
  // for _, pm := range tmatch.Partitions {
  // 	if pm.ID == partition {
  // 		pmatch = pm
  // 		goto foundPartition
  // 	}
  // }
  let pmatch = tm.partitions
    .iter()
    .find_first(pm => pm.id == partition)
    .unwrap_or_else(fn() {
      let pmatch = @protocol.PartitionMetadata::{
        id: partition,
        leader: brokerID,
        replicas,
        isr,
        offline_replicas: offline,
        version: 0,
        err,
        leader_epoch: 0,
      }
      tm.partitions.push(pmatch)
      pmatch
    })
  pmatch.leader = brokerID
  pmatch.replicas = replicas
  pmatch.isr = isr
  pmatch.offline_replicas = offline
  pmatch.err = err
  return pmatch
}

///|
using @protocol {ErrNoError, type FetchResponse, type FetchResponseBlock}

///|
fn fetch_response_add_message(
  fetchResponse : FetchResponse,
  topic : String,
  partition : Int,
  key : &@protocol.MessageEncoder?,
  value : &@protocol.MessageEncoder,
  offset : Int64,
) -> Unit {
  // fetch_response_add_message_with_timestamp(
  //   self, topic, partition, key, value, offset, 0, 0,
  // )
  ...
}

///|
fn fetch_response_add_message_with_timestamp(
  self : FetchResponse,
  topic : String,
  partition : Int,
  key : &@protocol.MessageEncoder,
  value : &@protocol.MessageEncoder,
  offset : Int64,
  ms_timestamp : Int64,
  version : Byte,
) -> Unit {
  ...
  // let frb = self.get_or_create_block(topic, partition)
  // let (kb, vb) = encode_kv(key, value)
  // let msg = @protocol.Message::{
  //   key: kb,
  //   value: vb,
  //   log_append_time: self.log_append_time,
  //   timestamp: ms_timestamp,
  //   version,
  // }
  // let msg_block = @protocol.MessageBlock::{ msg, offset }
  // if frb.records_set.length() == 0 {
  //   let records = new_legacy_records(@protocol.MessageSet::new())
  //   frb.records_set = [records]
  // }
  // let set = frb.records_set[0].msg_set
  // set.messages.push(msg_block)
}
