///|
pub(all) struct Config {
  contexts : Map[String, Context]
  current_context : String
} derive(@json.FromJson, ToJson)

///|
pub(all) struct Context {
  brokers : Array[String]
  // tls : TlsConfig?
  // sasl : SaslConfig?
  // kubernetes : KubernetesConfig?
  // clientID : String?
  // kafkaVersion : String?
  // requestTimeout : String? // e.g. "10s"
  // avro : AvroConfig?
  // schemaRegistry : SchemaRegistryConfig?
  // protobuf : ProtobufConfig?
  // producer : ProducerConfig?
  // consumer : ConsumerConfig?
} derive(@json.FromJson, ToJson)
