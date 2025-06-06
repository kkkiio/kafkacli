///|
pub(all) struct Config {
  contexts : Map[String, Context]
  current_context : String
} derive(@json.FromJson, ToJson)

///|
struct TlsConfig {
  enabled : Bool
  ca : String?
  cert : String?
  certKey : String?
  insecure : Bool? // defaults to false
} derive(@json.FromJson, ToJson)

///|
struct TokenProviderConfig {
  plugin : String
  options : Map[String, String]?
} derive(@json.FromJson, ToJson)

///|
struct SaslConfig {
  enabled : Bool
  username : String?
  password : String?
  mechanism : String? // defaults to plaintext
  tokenprovider : TokenProviderConfig?
} derive(@json.FromJson, ToJson)

///|
struct MatchExpression {
  key : String
  operator : String
  values : Array[String]?
} derive(@json.FromJson, ToJson)

///|
struct NodeSelectorTerm {
  matchExpressions : Array[MatchExpression]?
} derive(@json.FromJson, ToJson)

///|
struct RequiredDuringSchedulingIgnoredDuringExecution {
  nodeSelectorTerms : Array[NodeSelectorTerm]
} derive(@json.FromJson, ToJson)

///|
struct NodeAffinity {
  requiredDuringSchedulingIgnoredDuringExecution : RequiredDuringSchedulingIgnoredDuringExecution?
  // TODO: Add preferredDuringSchedulingIgnoredDuringExecution
} derive(@json.FromJson, ToJson)

///|
struct AffinityConfig {
  nodeAffinity : NodeAffinity?
  // TODO: Add podAffinity, podAntiAffinity
} derive(@json.FromJson, ToJson)

///|
struct Toleration {
  key : String?
  operator : String?
  value : String?
  effect : String?
  tolerationSeconds : Int?
} derive(@json.FromJson, ToJson)

///|
struct KubernetesConfig {
  enabled : Bool
  binary : String?
  kubeConfig : String?
  kubeContext : String?
  namespace : String?
  image : String?
  imagePullSecret : String?
  serviceAccount : String?
  keepPod : Bool?
  labels : Map[String, String]?
  annotations : Map[String, String]?
  nodeSelector : Map[String, String]?
  affinity : AffinityConfig?
  tolerations : Array[Toleration]?
} derive(@json.FromJson, ToJson)

///|
struct AvroConfig {
  jsonCodec : String? // defaults to standard
} derive(@json.FromJson, ToJson)

///|
struct SchemaRegistryConfig {
  url : String
  requestTimeout : String? // e.g. "10s"
  username : String?
  password : String?
  tls : TlsConfig?
} derive(@json.FromJson, ToJson)

///|
struct ProtobufMarshalOptions {
  allowPartial : Bool?
  useProtoNames : Bool?
  useEnumNumbers : Bool?
  emitUnpopulated : Bool?
  emitDefaultValues : Bool?
} derive(@json.FromJson, ToJson)

///|
struct ProtobufConfig {
  importPaths : Array[String]?
  protoFiles : Array[String]?
  protosetFiles : Array[String]?
  marshalOptions : ProtobufMarshalOptions?
} derive(@json.FromJson, ToJson)

///|
struct ProducerConfig {
  partitioner : String? // e.g. "hash"
  requiredAcks : String? // e.g. "WaitForAll"
  maxMessageBytes : Int?
} derive(@json.FromJson, ToJson)

///|
struct ConsumerConfig {
  isolationLevel : String? // e.g. ReadUncommitted
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
