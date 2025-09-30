// ErrOutOfBrokers is the error returned when the client has run out of brokers to talk to because all of them errored
// or otherwise failed to respond.

///|
let err_out_of_brokers : Error = Failure(
  "kafka: client has run out of available brokers to talk to",
)

// ErrBrokerNotFound is the error returned when there's no broker found for the requested ID.

///|
let err_broker_not_found : Error = Failure("kafka: broker for ID is not found")

// ErrClosedClient is the error returned when a method is called on a client that has been closed.

///|
let err_closed_client : Error = Failure(
  "kafka: tried to use a client that was closed",
)

// ErrIncompleteResponse is the error returned when the server returns a syntactically valid response, but it does
// not contain the expected information.

///|
let err_incomplete_response : Error = Failure(
  "kafka: response did not contain all the expected topic/partition blocks",
)

// ErrInvalidPartition is the error returned when a partitioner returns an invalid partition index
// (meaning one outside of the range [0...numPartitions-1]).

///|
let err_invalid_partition : Error = Failure(
  "kafka: partitioner returned an invalid partition index",
)

// ErrAlreadyConnected is the error returned when calling Open() on a Broker that is already connected or connecting.

///|
let err_already_connected : Error = Failure(
  "kafka: broker connection already initiated",
)

// ErrNotConnected is the error returned when trying to send or call Close() on a Broker that is not connected.

///|
let err_not_connected : Error = Failure("kafka: broker not connected")

// ErrInsufficientData is returned when decoding and the packet is truncated. This can be expected
// when requesting messages, since as an optimization the server is allowed to return a partial message at the end
// of the message set.

///|
let err_insufficient_data : PacketDecodingError = PacketDecodingError(
  "kafka: insufficient data to decode packet, more bytes expected",
)

// ErrShuttingDown is returned when a producer receives a message during shutdown.

///|
let err_shutting_down : Error = Failure(
  "kafka: message received by producer in process of shutting down",
)

// ErrMessageTooLarge is returned when the next message to consume is larger than the configured Consumer.Fetch.Max

///|
let err_message_too_large : Error = Failure(
  "kafka: message is larger than Consumer.Fetch.Max",
)

// ErrConsumerOffsetNotAdvanced is returned when a partition consumer didn't advance its offset after parsing
// a RecordBatch.

///|
let err_consumer_offset_not_advanced : Error = Failure(
  "kafka: consumer offset was not advanced after a RecordBatch",
)

// ErrControllerNotAvailable is returned when server didn't give correct controller id. May be kafka server's version
// is lower than 0.10.0.0.

///|
let err_controller_not_available : Error = Failure(
  "kafka: controller is not available",
)

// ErrNoTopicsToUpdateMetadata is returned when Meta.Full is set to false but no specific topics were found to update
// the metadata.

///|
let err_no_topics_to_update_metadata : Error = Failure(
  "kafka: no specific topics to update metadata",
)

// ErrUnknownScramMechanism is returned when user tries to AlterUserScramCredentials with unknown SCRAM mechanism

///|
let err_unknown_scram_mechanism : Error = Failure(
  "kafka: unknown SCRAM mechanism provided",
)

// ErrReassignPartitions is returned when altering partition assignments for a topic fails

///|
let err_reassign_partitions : Error = Failure(
  "failed to reassign partitions for topic",
)

// ErrDeleteRecords is the type of error returned when fail to delete the required records

///|
let err_delete_records : Error = Failure(
  "kafka server: failed to delete records",
)

// ErrCreateACLs is the type of error returned when ACL creation failed

///|
let err_create_acls : Error = Failure(
  "kafka server: failed to create one or more ACL rules",
)

// ErrAddPartitionsToTxn is returned when AddPartitionsToTxn failed multiple times

///|
let err_add_partitions_to_txn : Error = Failure(
  "transaction manager: failed to send partitions to transaction",
)

// ErrTxnOffsetCommit is returned when TxnOffsetCommit failed multiple times

///|
let err_txn_offset_commit : Error = Failure(
  "transaction manager: failed to send offsets to transaction",
)

// ErrTransactionNotReady when transaction status is invalid for the current action.

///|
let err_transaction_not_ready : Error = Failure(
  "transaction manager: transaction is not ready",
)

// ErrNonTransactedProducer when calling BeginTxn, CommitTxn or AbortTxn on a non transactional producer.

///|
let err_non_transacted_producer : Error = Failure(
  "transaction manager: you need to add TransactionalID to producer",
)

// ErrTransitionNotAllowed when txnmgr state transition is not valid.

///|
let err_transition_not_allowed : Error = Failure(
  "transaction manager: invalid transition attempted",
)

// ErrCannotTransitionNilError when transition is attempted with an nil error.

///|
let err_cannot_transition_nil_error : Error = Failure(
  "transaction manager: cannot transition with a nil error",
)

// ErrTxnUnableToParseResponse when response is nil

///|
let err_txn_unable_to_parse_response : Error = Failure(
  "transaction manager: unable to parse response",
)

// ErrUnknownMessage when the protocol message key is not recognized

///|
let err_unknown_message : Error = Failure("kafka: unknown protocol message key")

// struct  SentinelError {
// 	sentinel :Error?
// 	wrapped  :Error?
// }

// impl Show for SentinelError with output(self,logger) {
// 	let msg = if self.wrapped is Some(wrapped) {
// 		"\{self.sentinel}: \{wrapped}"
// 	} else {
// 		self.sentinel.to_string()
// 	}
// 	logger.write_string(msg)
// }

// func (err sentinelError) Is(target error) bool {
// 	return errors.Is(err.sentinel, target) || errors.Is(err.wrapped, target)
// }

// func (err sentinelError) Unwrap() error {
// 	return err.wrapped
// }

// func Wrap(sentinel error, wrapped ...error) sentinelError {
// 	return sentinelError{sentinel: sentinel, wrapped: errors.Join(wrapped...)}
// }

// PacketEncodingError is returned from a failure while encoding a Kafka packet. This can happen, for example,
// if you try to encode a string over 2^15 characters in length, since Kafka's encoding rules do not permit that.

///|
pub suberror PacketEncodingError String

///|
impl Show for PacketEncodingError with output(self, logger) {
  logger.write_string("kafka: error encoding packet: \{self}")
}

// PacketDecodingError is returned when there was an error (other than truncated data) decoding the Kafka broker's response.
// This can be a bad CRC or length field, or any other invalid value.

///|
suberror PacketDecodingError String

///|
impl Show for PacketDecodingError with output(self, logger) {
  logger.write_string("kafka: error decoding packet: \{self}")
}

// ConfigurationError is the type of error returned from a constructor (e.g. NewClient, or NewConsumer)
// when the specified configuration is invalid.

///|
suberror ConfigurationError String

///|
impl Show for ConfigurationError with output(self, logger) {
  logger.write_string("kafka: invalid configuration (\{self})")
}

// KError is the type of error that can be returned directly by the Kafka broker.
// See https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol#AGuideToTheKafkaProtocol-ErrorCodes

///|
suberror KError Int16

// Numeric error codes returned by the Kafka server.

///|
const ErrUnknown = -1 // Errors.UNKNOWN_SERVER_ERROR

///|
const ErrNoError = 0 // Errors.NONE

///|
const ErrOffsetOutOfRange = 1 // Errors.OFFSET_OUT_OF_RANGE

///|
const ErrInvalidMessage = 2 // Errors.CORRUPT_MESSAGE

///|
const ErrUnknownTopicOrPartition = 3 // Errors.UNKNOWN_TOPIC_OR_PARTITION

///|
const ErrInvalidMessageSize = 4 // Errors.INVALID_FETCH_SIZE

///|
const ErrLeaderNotAvailable = 5 // Errors.LEADER_NOT_AVAILABLE

///|
const ErrNotLeaderForPartition = 6 // Errors.NOT_LEADER_OR_FOLLOWER

///|
const ErrRequestTimedOut = 7 // Errors.REQUEST_TIMED_OUT

///|
const ErrBrokerNotAvailable = 8 // Errors.BROKER_NOT_AVAILABLE

///|
const ErrReplicaNotAvailable = 9 // Errors.REPLICA_NOT_AVAILABLE

///|
const ErrMessageSizeTooLarge = 10 // Errors.MESSAGE_TOO_LARGE

///|
const ErrStaleControllerEpochCode = 11 // Errors.STALE_CONTROLLER_EPOCH

///|
const ErrOffsetMetadataTooLarge = 12 // Errors.OFFSET_METADATA_TOO_LARGE

///|
const ErrNetworkException = 13 // Errors.NETWORK_EXCEPTION

///|
const ErrOffsetsLoadInProgress = 14 // Errors.COORDINATOR_LOAD_IN_PROGRESS

///|
const ErrConsumerCoordinatorNotAvailable = 15 // Errors.COORDINATOR_NOT_AVAILABLE

///|
const ErrNotCoordinatorForConsumer = 16 // Errors.NOT_COORDINATOR

///|
const ErrInvalidTopic = 17 // Errors.INVALID_TOPIC_EXCEPTION

///|
const ErrMessageSetSizeTooLarge = 18 // Errors.RECORD_LIST_TOO_LARGE

///|
const ErrNotEnoughReplicas = 19 // Errors.NOT_ENOUGH_REPLICAS

///|
const ErrNotEnoughReplicasAfterAppend = 20 // Errors.NOT_ENOUGH_REPLICAS_AFTER_APPEND

///|
const ErrInvalidRequiredAcks = 21 // Errors.INVALID_REQUIRED_ACKS

///|
const ErrIllegalGeneration = 22 // Errors.ILLEGAL_GENERATION

///|
const ErrInconsistentGroupProtocol = 23 // Errors.INCONSISTENT_GROUP_PROTOCOL

///|
const ErrInvalidGroupId = 24 // Errors.INVALID_GROUP_ID

///|
const ErrUnknownMemberId = 25 // Errors.UNKNOWN_MEMBER_ID

///|
const ErrInvalidSessionTimeout = 26 // Errors.INVALID_SESSION_TIMEOUT

///|
const ErrRebalanceInProgress = 27 // Errors.REBALANCE_IN_PROGRESS

///|
const ErrInvalidCommitOffsetSize = 28 // Errors.INVALID_COMMIT_OFFSET_SIZE

///|
const ErrTopicAuthorizationFailed = 29 // Errors.TOPIC_AUTHORIZATION_FAILED

///|
const ErrGroupAuthorizationFailed = 30 // Errors.GROUP_AUTHORIZATION_FAILED

///|
const ErrClusterAuthorizationFailed = 31 // Errors.CLUSTER_AUTHORIZATION_FAILED

///|
const ErrInvalidTimestamp = 32 // Errors.INVALID_TIMESTAMP

///|
const ErrUnsupportedSASLMechanism = 33 // Errors.UNSUPPORTED_SASL_MECHANISM

///|
const ErrIllegalSASLState = 34 // Errors.ILLEGAL_SASL_STATE

///|
const ErrUnsupportedVersion = 35 // Errors.UNSUPPORTED_VERSION

///|
const ErrTopicAlreadyExists = 36 // Errors.TOPIC_ALREADY_EXISTS

///|
const ErrInvalidPartitions = 37 // Errors.INVALID_PARTITIONS

///|
const ErrInvalidReplicationFactor = 38 // Errors.INVALID_REPLICATION_FACTOR

///|
const ErrInvalidReplicaAssignment = 39 // Errors.INVALID_REPLICA_ASSIGNMENT

///|
const ErrInvalidConfig = 40 // Errors.INVALID_CONFIG

///|
const ErrNotController = 41 // Errors.NOT_CONTROLLER

///|
const ErrInvalidRequest = 42 // Errors.INVALID_REQUEST

///|
const ErrUnsupportedForMessageFormat = 43 // Errors.UNSUPPORTED_FOR_MESSAGE_FORMAT

///|
const ErrPolicyViolation = 44 // Errors.POLICY_VIOLATION

///|
const ErrOutOfOrderSequenceNumber = 45 // Errors.OUT_OF_ORDER_SEQUENCE_NUMBER

///|
const ErrDuplicateSequenceNumber = 46 // Errors.DUPLICATE_SEQUENCE_NUMBER

///|
const ErrInvalidProducerEpoch = 47 // Errors.INVALID_PRODUCER_EPOCH

///|
const ErrInvalidTxnState = 48 // Errors.INVALID_TXN_STATE

///|
const ErrInvalidProducerIDMapping = 49 // Errors.INVALID_PRODUCER_ID_MAPPING

///|
const ErrInvalidTransactionTimeout = 50 // Errors.INVALID_TRANSACTION_TIMEOUT

///|
const ErrConcurrentTransactions = 51 // Errors.CONCURRENT_TRANSACTIONS

///|
const ErrTransactionCoordinatorFenced = 52 // Errors.TRANSACTION_COORDINATOR_FENCED

///|
const ErrTransactionalIDAuthorizationFailed = 53 // Errors.TRANSACTIONAL_ID_AUTHORIZATION_FAILED

///|
const ErrSecurityDisabled = 54 // Errors.SECURITY_DISABLED

///|
const ErrOperationNotAttempted = 55 // Errors.OPERATION_NOT_ATTEMPTED

///|
const ErrKafkaStorageError = 56 // Errors.KAFKA_STORAGE_ERROR

///|
const ErrLogDirNotFound = 57 // Errors.LOG_DIR_NOT_FOUND

///|
const ErrSASLAuthenticationFailed = 58 // Errors.SASL_AUTHENTICATION_FAILED

///|
const ErrUnknownProducerID = 59 // Errors.UNKNOWN_PRODUCER_ID

///|
const ErrReassignmentInProgress = 60 // Errors.REASSIGNMENT_IN_PROGRESS

///|
const ErrDelegationTokenAuthDisabled = 61 // Errors.DELEGATION_TOKEN_AUTH_DISABLED

///|
const ErrDelegationTokenNotFound = 62 // Errors.DELEGATION_TOKEN_NOT_FOUND

///|
const ErrDelegationTokenOwnerMismatch = 63 // Errors.DELEGATION_TOKEN_OWNER_MISMATCH

///|
const ErrDelegationTokenRequestNotAllowed = 64 // Errors.DELEGATION_TOKEN_REQUEST_NOT_ALLOWED

///|
const ErrDelegationTokenAuthorizationFailed = 65 // Errors.DELEGATION_TOKEN_AUTHORIZATION_FAILED

///|
const ErrDelegationTokenExpired = 66 // Errors.DELEGATION_TOKEN_EXPIRED

///|
const ErrInvalidPrincipalType = 67 // Errors.INVALID_PRINCIPAL_TYPE

///|
const ErrNonEmptyGroup = 68 // Errors.NON_EMPTY_GROUP

///|
const ErrGroupIDNotFound = 69 // Errors.GROUP_ID_NOT_FOUND

///|
const ErrFetchSessionIDNotFound = 70 // Errors.FETCH_SESSION_ID_NOT_FOUND

///|
const ErrInvalidFetchSessionEpoch = 71 // Errors.INVALID_FETCH_SESSION_EPOCH

///|
const ErrListenerNotFound = 72 // Errors.LISTENER_NOT_FOUND

///|
const ErrTopicDeletionDisabled = 73 // Errors.TOPIC_DELETION_DISABLED

///|
const ErrFencedLeaderEpoch = 74 // Errors.FENCED_LEADER_EPOCH

///|
const ErrUnknownLeaderEpoch = 75 // Errors.UNKNOWN_LEADER_EPOCH

///|
const ErrUnsupportedCompressionType = 76 // Errors.UNSUPPORTED_COMPRESSION_TYPE

///|
const ErrStaleBrokerEpoch = 77 // Errors.STALE_BROKER_EPOCH

///|
const ErrOffsetNotAvailable = 78 // Errors.OFFSET_NOT_AVAILABLE

///|
const ErrMemberIdRequired = 79 // Errors.MEMBER_ID_REQUIRED

///|
const ErrPreferredLeaderNotAvailable = 80 // Errors.PREFERRED_LEADER_NOT_AVAILABLE

///|
const ErrGroupMaxSizeReached = 81 // Errors.GROUP_MAX_SIZE_REACHED

///|
const ErrFencedInstancedId = 82 // Errors.FENCED_INSTANCE_ID

///|
const ErrEligibleLeadersNotAvailable = 83 // Errors.ELIGIBLE_LEADERS_NOT_AVAILABLE

///|
const ErrElectionNotNeeded = 84 // Errors.ELECTION_NOT_NEEDED

///|
const ErrNoReassignmentInProgress = 85 // Errors.NO_REASSIGNMENT_IN_PROGRESS

///|
const ErrGroupSubscribedToTopic = 86 // Errors.GROUP_SUBSCRIBED_TO_TOPIC

///|
const ErrInvalidRecord = 87 // Errors.INVALID_RECORD

///|
const ErrUnstableOffsetCommit = 88 // Errors.UNSTABLE_OFFSET_COMMIT

///|
const ErrThrottlingQuotaExceeded = 89 // Errors.THROTTLING_QUOTA_EXCEEDED

///|
const ErrProducerFenced = 90 // Errors.PRODUCER_FENCED

///|
pub impl Show for KError with output(self, logger) {
  // Error messages stolen/adapted from
  // https://kafka.apache.org/protocol#protocol_error_codes
  guard self is KError(v)
  let msg = match v.to_int() {
    ErrNoError => "kafka server: Not an error, why are you printing me?"
    ErrUnknown => "kafka server: Unexpected (unknown?) server error"
    ErrOffsetOutOfRange =>
      "kafka server: The requested offset is outside the range of offsets maintained by the server for the given topic/partition"
    ErrInvalidMessage => "kafka server: Message contents does not match its CRC"
    ErrUnknownTopicOrPartition =>
      "kafka server: Request was for a topic or partition that does not exist on this broker"
    ErrInvalidMessageSize => "kafka server: The message has a negative size"
    ErrLeaderNotAvailable =>
      "kafka server: In the middle of a leadership election, there is currently no leader for this partition and hence it is unavailable for writes"
    ErrNotLeaderForPartition =>
      "kafka server: Tried to send a message to a replica that is not the leader for some partition. Your metadata is out of date"
    ErrRequestTimedOut =>
      "kafka server: Request exceeded the user-specified time limit in the request"
    ErrBrokerNotAvailable =>
      "kafka server: Broker not available. Not a client facing error, we should never receive this!!!"
    ErrReplicaNotAvailable =>
      "kafka server: Replica information not available, one or more brokers are down"
    ErrMessageSizeTooLarge =>
      "kafka server: Message was too large, server rejected it to avoid allocation error"
    ErrStaleControllerEpochCode =>
      "kafka server: StaleControllerEpochCode (internal error code for broker-to-broker communication)"
    ErrOffsetMetadataTooLarge =>
      "kafka server: Specified a string larger than the configured maximum for offset metadata"
    ErrNetworkException =>
      "kafka server: The server disconnected before a response was received"
    ErrOffsetsLoadInProgress =>
      "kafka server: The coordinator is still loading offsets and cannot currently process requests"
    ErrConsumerCoordinatorNotAvailable =>
      "kafka server: The coordinator is not available"
    ErrNotCoordinatorForConsumer =>
      "kafka server: Request was for a consumer group that is not coordinated by this broker"
    ErrInvalidTopic =>
      "kafka server: The request attempted to perform an operation on an invalid topic"
    ErrMessageSetSizeTooLarge =>
      "kafka server: The request included message batch larger than the configured segment size on the server"
    ErrNotEnoughReplicas =>
      "kafka server: Messages are rejected since there are fewer in-sync replicas than required"
    ErrNotEnoughReplicasAfterAppend =>
      "kafka server: Messages are written to the log, but to fewer in-sync replicas than required"
    ErrInvalidRequiredAcks =>
      "kafka server: The number of required acks is invalid (should be either -1, 0, or 1)"
    ErrIllegalGeneration =>
      "kafka server: The provided generation id is not the current generation"
    ErrInconsistentGroupProtocol =>
      "kafka server: The provider group protocol type is incompatible with the other members"
    ErrInvalidGroupId => "kafka server: The provided group id was empty"
    ErrUnknownMemberId =>
      "kafka server: The provided member is not known in the current generation"
    ErrInvalidSessionTimeout =>
      "kafka server: The provided session timeout is outside the allowed range"
    ErrRebalanceInProgress =>
      "kafka server: A rebalance for the group is in progress. Please re-join the group"
    ErrInvalidCommitOffsetSize =>
      "kafka server: The provided commit metadata was too large"
    ErrTopicAuthorizationFailed =>
      "kafka server: The client is not authorized to access this topic"
    ErrGroupAuthorizationFailed =>
      "kafka server: The client is not authorized to access this group"
    ErrClusterAuthorizationFailed =>
      "kafka server: The client is not authorized to send this request type"
    ErrInvalidTimestamp =>
      "kafka server: The timestamp of the message is out of acceptable range"
    ErrUnsupportedSASLMechanism =>
      "kafka server: The broker does not support the requested SASL mechanism"
    ErrIllegalSASLState =>
      "kafka server: Request is not valid given the current SASL state"
    ErrUnsupportedVersion => "kafka server: The version of API is not supported"
    ErrTopicAlreadyExists => "kafka server: Topic with this name already exists"
    ErrInvalidPartitions => "kafka server: Number of partitions is invalid"
    ErrInvalidReplicationFactor => "kafka server: Replication-factor is invalid"
    ErrInvalidReplicaAssignment => "kafka server: Replica assignment is invalid"
    ErrInvalidConfig => "kafka server: Configuration is invalid"
    ErrNotController =>
      "kafka server: This is not the correct controller for this cluster"
    ErrInvalidRequest =>
      "kafka server: This most likely occurs because of a request being malformed by the client library or the message was sent to an incompatible broker. See the broker logs for more details"
    ErrUnsupportedForMessageFormat =>
      "kafka server: The requested operation is not supported by the message format version"
    ErrPolicyViolation =>
      "kafka server: Request parameters do not satisfy the configured policy"
    ErrOutOfOrderSequenceNumber =>
      "kafka server: The broker received an out of order sequence number"
    ErrDuplicateSequenceNumber =>
      "kafka server: The broker received a duplicate sequence number"
    ErrInvalidProducerEpoch =>
      "kafka server: Producer attempted an operation with an old epoch"
    ErrInvalidTxnState =>
      "kafka server: The producer attempted a transactional operation in an invalid state"
    ErrInvalidProducerIDMapping =>
      "kafka server: The producer attempted to use a producer id which is not currently assigned to its transactional id"
    ErrInvalidTransactionTimeout =>
      "kafka server: The transaction timeout is larger than the maximum value allowed by the broker (as configured by max.transaction.timeout.ms)"
    ErrConcurrentTransactions =>
      "kafka server: The producer attempted to update a transaction while another concurrent operation on the same transaction was ongoing"
    ErrTransactionCoordinatorFenced =>
      "kafka server: The transaction coordinator sending a WriteTxnMarker is no longer the current coordinator for a given producer"
    ErrTransactionalIDAuthorizationFailed =>
      "kafka server: Transactional ID authorization failed"
    ErrSecurityDisabled => "kafka server: Security features are disabled"
    ErrOperationNotAttempted =>
      "kafka server: The broker did not attempt to execute this operation"
    ErrKafkaStorageError =>
      "kafka server: Disk error when trying to access log file on the disk"
    ErrLogDirNotFound =>
      "kafka server: The specified log directory is not found in the broker config"
    ErrSASLAuthenticationFailed => "kafka server: SASL Authentication failed"
    ErrUnknownProducerID =>
      "kafka server: The broker could not locate the producer metadata associated with the Producer ID"
    ErrReassignmentInProgress =>
      "kafka server: A partition reassignment is in progress"
    ErrDelegationTokenAuthDisabled =>
      "kafka server: Delegation Token feature is not enabled"
    ErrDelegationTokenNotFound =>
      "kafka server: Delegation Token is not found on server"
    ErrDelegationTokenOwnerMismatch =>
      "kafka server: Specified Principal is not valid Owner/Renewer"
    ErrDelegationTokenRequestNotAllowed =>
      "kafka server: Delegation Token requests are not allowed on PLAINTEXT/1-way SSL channels and on delegation token authenticated channels"
    ErrDelegationTokenAuthorizationFailed =>
      "kafka server: Delegation Token authorization failed"
    ErrDelegationTokenExpired => "kafka server: Delegation Token is expired"
    ErrInvalidPrincipalType =>
      "kafka server: Supplied principalType is not supported"
    ErrNonEmptyGroup => "kafka server: The group is not empty"
    ErrGroupIDNotFound => "kafka server: The group id does not exist"
    ErrFetchSessionIDNotFound =>
      "kafka server: The fetch session ID was not found"
    ErrInvalidFetchSessionEpoch =>
      "kafka server: The fetch session epoch is invalid"
    ErrListenerNotFound =>
      "kafka server: There is no listener on the leader broker that matches the listener on which metadata request was processed"
    ErrTopicDeletionDisabled => "kafka server: Topic deletion is disabled"
    ErrFencedLeaderEpoch =>
      "kafka server: The leader epoch in the request is older than the epoch on the broker"
    ErrUnknownLeaderEpoch =>
      "kafka server: The leader epoch in the request is newer than the epoch on the broker"
    ErrUnsupportedCompressionType =>
      "kafka server: The requesting client does not support the compression type of given partition"
    ErrStaleBrokerEpoch => "kafka server: Broker epoch has changed"
    ErrOffsetNotAvailable =>
      "kafka server: The leader high watermark has not caught up from a recent leader election so the offsets cannot be guaranteed to be monotonically increasing"
    ErrMemberIdRequired =>
      "kafka server: The group member needs to have a valid member id before actually entering a consumer group"
    ErrPreferredLeaderNotAvailable =>
      "kafka server: The preferred leader was not available"
    ErrGroupMaxSizeReached =>
      "kafka server: Consumer group The consumer group has reached its max size. already has the configured maximum number of members"
    ErrFencedInstancedId =>
      "kafka server: The broker rejected this static consumer since another consumer with the same group.instance.id has registered with a different member.id"
    ErrEligibleLeadersNotAvailable =>
      "kafka server: Eligible topic partition leaders are not available"
    ErrElectionNotNeeded =>
      "kafka server: Leader election not needed for topic partition"
    ErrNoReassignmentInProgress =>
      "kafka server: No partition reassignment is in progress"
    ErrGroupSubscribedToTopic =>
      "kafka server: Deleting offsets of a topic is forbidden while the consumer group is actively subscribed to it"
    ErrInvalidRecord =>
      "kafka server: This record has failed the validation on broker and hence will be rejected"
    ErrUnstableOffsetCommit =>
      "kafka server: There are unstable offsets that need to be cleared"
    v => "Unknown error, how did this happen? Error code = \{v}"
  }
  logger.write_string(msg)
}
