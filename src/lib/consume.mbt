///|
pub(all) enum Offset {
  Earliest
  Latest
}

///|
priv suberror ConsumeError {
  ClientCreationFailed(errstr~ : String)
  SubscriptionFailed(errstr~ : String)
  MessageError(errstr~ : String)
} derive(Show)

///| consume messages from kafka
pub fn consume(
  broker : String,
  topics : Array[String],
  group : String,
  offset : Offset,
  debug~ : Bool = false
) -> Unit raise {
  // Create configuration reference
  let conf_ref = @rdkafka.rd_kafka_conf_ref_new()

  // Create error buffer for client creation
  let errstr = Bytes::new(1024)

  // Set broker list
  set_conf(conf_ref, "bootstrap.servers", broker, errstr)

  // Enable debugging
  if debug {
    set_conf(conf_ref, "debug", "all", errstr)
  }

  // Set consumer group
  set_conf(conf_ref, "group.id", group, errstr)

  // Set auto offset reset based on offset parameter
  match offset {
    Offset::Earliest =>
      set_conf(conf_ref, "auto.offset.reset", "earliest", errstr)
    Offset::Latest => set_conf(conf_ref, "auto.offset.reset", "latest", errstr)
  }

  // Create consumer instance
  let kafka_ref = @rdkafka.rd_kafka_ref_new(
    @rdkafka.RD_KAFKA_CONSUMER,
    conf_ref,
    errstr,
    errstr.length(),
  )
  if not(@rdkafka.rd_kafka_ref_is_not_null(kafka_ref)) {
    raise ConsumeError::ClientCreationFailed(errstr=errstr.to_string())
  }

  // Get actual Kafka client
  let client = @rdkafka.rd_kafka_ref_get(kafka_ref)

  // Create topic partition list and add topic
  let topic_list = @rdkafka.rd_kafka_topic_partition_list_ref_new(1)
  for topic in topics {
    @rdkafka.rd_kafka_topic_partition_list_add(
      topic_list.get(),
      to_cstr(topic),
      @rdkafka.RD_KAFKA_PARTITION_UA,
    )
    |> ignore
  }

  // Subscribe to topic
  match @rdkafka.rd_kafka_subscribe(client, topic_list.get()) {
    0 => ()
    err => {
      @rdkafka.rd_kafka_err2str(err, errstr, errstr.length())
      raise ConsumeError::SubscriptionFailed(errstr=cstr_to_str(errstr))
    }
  }
  let bytes_buf = Bytes::new(10 * 1024 * 1024) // 10 MB
  let decoder = @encoding.decoder(UTF8)
  // Message consumption loop
  while true {
    let msg_ref = @rdkafka.rd_kafka_message_ref_poll(client, 1000)
    if not(@rdkafka.RdKafkaMessageRef::is_not_null(msg_ref)) {
      continue
    }
    let msg = msg_ref.get()
    match @rdkafka.rd_kafka_message_err(msg) {
      @rdkafka.RD_KAFKA_RESP_ERR_NO_ERROR => {
        let topic_len = @rdkafka.rd_kafka_message_topic_name_len(msg)
        if topic_len > bytes_buf.length() {
          raise ConsumeError::MessageError(errstr="Topic name is too large")
        }
        @rdkafka.rd_kafka_message_read_topic_name(msg, bytes_buf, topic_len)
        let topic = @encoding.decoder(UTF8).decode_lossy(
          bytes_buf[:topic_len].to_bytes(),
        )
        let len = @rdkafka.rd_kafka_message_len(msg)
        if len > bytes_buf.length() {
          raise ConsumeError::MessageError(errstr="Message is too large")
        }
        let partition = @rdkafka.rd_kafka_message_topic_partition(msg)
        let offset = @rdkafka.rd_kafka_message_offset(msg)
        @rdkafka.rd_kafka_message_read_payload(msg, bytes_buf, len)
        let str = decoder.decode_lossy(bytes_buf[:len].to_bytes())
        let json_data = @json.parse(str) catch {
          e => fail("Failed to parse JSON: \{e}, str=\{str}")
        }
        let full : Json = {
          "topic": topic.to_string(),
          "partition": partition,
          "offset": offset,
          "data": json_data,
        }
        println(full.stringify(indent=2))
      }
      @rdkafka.RD_KAFKA_RESP_ERR__PARTITION_EOF =>
        println("Reached end of partition")
      err => {
        @rdkafka.rd_kafka_err2str(err, errstr, errstr.length())
        raise ConsumeError::MessageError(errstr=cstr_to_str(errstr))
      }
    }
  }
}

///|
fn cstr_to_str(errstr : Bytes) -> String {
  for i in 0..<errstr.length() {
    let u = errstr[i]
    if u == 0 {
      let decoder = @encoding.decoder(UTF8)
      break decoder.decode_lossy(errstr[:i].data())
    }
  } else {
    ""
  }
}
