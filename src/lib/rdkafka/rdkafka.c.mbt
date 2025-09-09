///|
#external
type RdKafkaConf

///| Moonbit managed reference type for RdKafkaConf
#external
type RdKafkaConfRef

///|
pub extern "C" fn rd_kafka_conf_ref_new() -> RdKafkaConfRef = "__rd_kafka_conf_ref_new"

///|
pub extern "C" fn rd_kafka_conf_ref_get(conf : RdKafkaConfRef) -> RdKafkaConf = "__rd_kafka_conf_ref_get"

///|
pub const RD_KAFKA_CONF_UNKNOWN : Int = -2

///|
pub const RD_KAFKA_CONF_INVALID : Int = -1

///|
pub const RD_KAFKA_CONF_OK : Int = 0

///|
#borrow(conf, name, value, errstr)
pub extern "C" fn rd_kafka_conf_set(
  conf : RdKafkaConf,
  name : Bytes,
  value : Bytes,
  errstr : Bytes,
  errstr_size : Int
) -> Int = "rd_kafka_conf_set"

///|
#external
type RdKafka

///|
#external
type RdKafkaRef

///| Creates a new Kafka client instance.
#borrow(conf, errstr)
pub extern "C" fn rd_kafka_ref_new(
  client_type : Int, // rd_kafka_type_t, e.g. RD_KAFKA_CONSUMER
  conf : RdKafkaConfRef,
  errstr : Bytes,
  errstr_size : Int
) -> RdKafkaRef = "__rd_kafka_ref_new"

///| Returns true if the client is not NULL.
#borrow(client)
pub extern "C" fn rd_kafka_ref_is_not_null(client : RdKafkaRef) -> Bool = "__rd_kafka_ref_is_not_null"

///| Returns the Kafka client from a RdKafkaRef.
#borrow(client)
pub extern "C" fn rd_kafka_ref_get(client : RdKafkaRef) -> RdKafka = "__rd_kafka_ref_get"

///|
#external
pub type RdKafkaTopicPartitionList

///|
#external
pub type RdKafkaTopicPartitionListRef

///| Creates a new topic+partition list reference.
pub extern "C" fn rd_kafka_topic_partition_list_ref_new(
  size : Int
) -> RdKafkaTopicPartitionListRef = "__rd_kafka_topic_partition_list_ref_new"

///| Returns the underlying topic partition list from a reference.
#borrow(self)
pub extern "C" fn RdKafkaTopicPartitionListRef::get(
  self : RdKafkaTopicPartitionListRef
) -> RdKafkaTopicPartitionList = "__rd_kafka_topic_partition_list_ref_get"

///| Adds a topic/partition to a list.
#borrow(rktparlist, topic)
pub extern "C" fn rd_kafka_topic_partition_list_add(
  rktparlist : RdKafkaTopicPartitionList,
  topic : Bytes,
  partition : Int
) -> RdKafkaTopicPartition = "rd_kafka_topic_partition_list_add"

///| Subscribes a consumer to a list of topics.
#borrow(client, topics)
pub extern "C" fn rd_kafka_subscribe(
  client : RdKafka,
  topics : RdKafkaTopicPartitionList
) -> RdKafkaRespErr = "rd_kafka_subscribe"

///| Kafka message opaque type
#external
type RdKafkaMessage

///| Moonbit managed reference type for RdKafkaMessage
#external
type RdKafkaMessageRef

///| Polls the consumer for messages or events.
/// Creates a referenced message that will be automatically destroyed on GC.
#borrow(client)
pub extern "C" fn rd_kafka_message_ref_poll(
  client : RdKafka,
  timeout_ms : Int
) -> RdKafkaMessageRef = "__rd_kafka_message_ref_poll"

///| Returns true if the message reference is not NULL.
///
/// If the message reference is NULL, it means that the message is not available (poll timed out).
#borrow(self)
pub extern "C" fn RdKafkaMessageRef::is_not_null(
  self : RdKafkaMessageRef
) -> Bool = "__rd_kafka_message_ref_is_not_null"

///| Get the underlying message from a message reference.
#borrow(self)
pub extern "C" fn RdKafkaMessageRef::get(
  self : RdKafkaMessageRef
) -> RdKafkaMessage = "__rd_kafka_message_ref_get"

///| Gets the error code from a message.
pub extern "C" fn rd_kafka_message_err(msg : RdKafkaMessage) -> RdKafkaRespErr = "rd_kafka_message_err"

///| Gets the payload from a message.
#borrow(target)
pub extern "C" fn rd_kafka_message_read_payload(
  msg : RdKafkaMessage,
  target : Bytes,
  len : Int
) -> Unit = "rd_kafka_message_read_payload"

///| Gets the length of the payload.
pub extern "C" fn rd_kafka_message_len(msg : RdKafkaMessage) -> Int = "rd_kafka_message_len"

///| Gets the offset of the message.
pub extern "C" fn rd_kafka_message_offset(msg : RdKafkaMessage) -> Int64 = "rd_kafka_message_offset"

///| Gets the length of the topic name.
pub extern "C" fn rd_kafka_message_topic_name_len(msg : RdKafkaMessage) -> Int = "rd_kafka_message_topic_name_len"

///| Reads the topic name from a message.
#borrow(target)
pub extern "C" fn rd_kafka_message_read_topic_name(
  msg : RdKafkaMessage,
  target : Bytes,
  len : Int
) -> Unit = "rd_kafka_message_read_topic_name"

///| Gets the topic partition from a message.
pub extern "C" fn rd_kafka_message_topic_partition(msg : RdKafkaMessage) -> Int = "rd_kafka_message_topic_partition"

///| Gets the error string from a response error code.
#borrow(err, errstr, errstr_size)
pub extern "C" fn rd_kafka_err2str(
  err : RdKafkaRespErr,
  errstr : Bytes,
  errstr_size : Int
) -> Unit = "__rd_kafka_err2str"

///| Topic partition opaque type
#external
type RdKafkaTopicPartition

///| Kafka response error code
typealias Int as RdKafkaRespErr

///| Kafka client type: Consumer
pub const RD_KAFKA_CONSUMER : Int = 1

///| Unassigned partition for topic subscription (use for whole topic)
pub const RD_KAFKA_PARTITION_UA : Int = -1

///| Success error code from librdkafka
pub const RD_KAFKA_RESP_ERR_NO_ERROR : Int = 0

///| Partition EOF error code from librdkafka, not a fatal error.
pub const RD_KAFKA_RESP_ERR__PARTITION_EOF : Int = -191
