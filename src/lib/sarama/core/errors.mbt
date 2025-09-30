///|
/// Error types and constants for the Sarama Kafka client library

///|
/// Custom error type for Sarama
pub enum SaramaError {
  OutOfBrokers
  BrokerNotFound
  ClosedClient
  IncompleteResponse
  InvalidPartition
  AlreadyConnected
  NotConnected
  InsufficientData
  ShuttingDown
  MessageTooLarge
  ConsumerOffsetNotAdvanced
  ControllerNotAvailable
  Unknown(String)
} derive(Eq, Show, ToJson)

///|
/// Convert SaramaError to string representation
pub fn error_to_string(err : SaramaError) -> String {
  match err {
    OutOfBrokers => "kafka: client has run out of available brokers to talk to"
    BrokerNotFound => "kafka: broker for ID is not found"
    ClosedClient => "kafka: tried to use a client that was closed"
    IncompleteResponse => "kafka: response did not contain all the expected topic/partition blocks"
    InvalidPartition => "kafka: partitioner returned an invalid partition index"
    AlreadyConnected => "kafka: broker connection already initiated"
    NotConnected => "kafka: broker not connected"
    InsufficientData => "kafka: insufficient data to decode packet, more bytes expected"
    ShuttingDown => "kafka: message received by producer in process of shutting down"
    MessageTooLarge => "kafka: message is larger than Consumer.Fetch.Max"
    ConsumerOffsetNotAdvanced => "kafka: consumer offset was not advanced after a RecordBatch"
    ControllerNotAvailable => "kafka: controller is not available"
    Unknown(msg) => "kafka: " + msg
  }
}

///|
/// Producer retry buffer overflow error
pub fn producer_retry_buffer_overflow() -> SaramaError {
  Unknown("retry buffer full: message discarded to prevent buffer overflow")
}