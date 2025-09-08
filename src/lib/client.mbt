///|
pub fn set_conf(
  conf : @rdkafka.RdKafkaConfRef,
  name : String,
  value : String,
  errstr_buf : Bytes
) -> Unit raise RdKafkaConfError {
  match
    @rdkafka.rd_kafka_conf_set(
      @rdkafka.rd_kafka_conf_ref_get(conf),
      to_cstr(name),
      to_cstr(value),
      errstr_buf,
      errstr_buf.length(),
    ) {
    @rdkafka.RD_KAFKA_CONF_OK => ()
    @rdkafka.RD_KAFKA_CONF_INVALID =>
      raise RdKafkaConfError::InvalidConfigValue(
        name~,
        value~,
        errstr=errstr_buf.to_string(),
      )
    @rdkafka.RD_KAFKA_CONF_UNKNOWN =>
      raise RdKafkaConfError::UnknownConfig(
        name~,
        errstr=errstr_buf.to_string(),
      )
    _ => panic()
  }
}

///|
suberror RdKafkaConfError {
  UnknownConfig(name~ : String, errstr~ : String)
  InvalidConfigValue(name~ : String, value~ : String, errstr~ : String)
}

///|
pub fn to_cstr(s : String) -> Bytes {
  let buf = @buffer.new()
  @encoding.encode_to(s, buf, encoding=UTF8)
  buf.write_byte(0)
  buf.to_bytes()
}
