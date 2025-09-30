///|
pub trait ProtocolBody: Encoder + VersionedDecoder + Show {
  key(Self) -> Int16
  version(Self) -> Int16
  set_version(Self, Int16) -> Unit
  header_version(Self) -> Int16
  is_valid_version(Self) -> Bool
  required_version(Self) -> KafkaVersion
}

///|
pub(all) struct Request {
  mut correlation_id : Int
  mut client_id : String
  mut body : &ProtocolBody?
} derive(Default, Show)

///|
pub impl Encoder for Request with encode(self, pe) {
  pe.push(LengthField::default())
  guard self.body is Some(body) else {
    raise PacketEncodingError("body is None")
  }
  pe.put_int16(body.key())
  pe.put_int16(body.version())
  pe.put_int32(self.correlation_id)
  if body.header_version() >= 1 {
    pe.put_string(self.client_id)
  }
  if body.header_version() >= 2 {
    // we don't use tag headers at the moment so we just put an array length of 0
    pe.put_uvarint(0)
  }
  body.encode(pe)
  return pe.pop()
}

///|
pub impl Decoder for Request with decode(self, pd) {
  let key = pd.get_int16()
  let version = pd.get_int16()
  self.correlation_id = pd.get_int32()
  self.client_id = pd.get_string()
  guard allocate_body(key, version) is Some(body) else {
    raise PacketDecodingError("unknown request key (\{key})")
  }
  self.body = Some(body)
  if body.header_version() >= 2 {
    // tagged field
    ignore(pd.get_uvarint())
  }
  VersionedDecoder::decode(body, pd, version)
}

///|
pub async fn decode_request(r : &@io.Reader) -> (Request, Int) {
  let lengthBytes = r.read_exactly(4)
  let mut bytesRead = lengthBytes.length()
  let length = (lengthBytes[0].to_uint() << 24) |
    (lengthBytes[1].to_uint() << 16) |
    (lengthBytes[2].to_uint() << 8) |
    lengthBytes[3].to_uint()
  if length <= 4 || length > MaxRequestSize {
    raise PacketDecodingError(
      "message of length \{length} too large or too small",
    )
  }
  let encodedReq = r.read_exactly(length.reinterpret_as_int())
  bytesRead += encodedReq.length()
  let req = Request::default()
  decode(encodedReq.to_array(), req)
  return (req, bytesRead)
}

///|
pub fn allocate_body(key : Int16, version : Int16) -> &ProtocolBody? {
  let body : &ProtocolBody = match key {
    // apiKeyProduce => ProduceRequest::new(version)
    // apiKeyFetch => FetchRequest::new(version)
    // apiKeyListOffsets => OffsetRequest::new(version)
    // apiKeyMetadata => MetadataRequest::new(version)
    // 4: LeaderAndIsrRequest
    // 5: StopReplicaRequest
    // 6: UpdateMetadataRequest
    // 7: ControlledShutdownRequest
    // apiKeyOffsetCommit => OffsetCommitRequest::new(version)
    // apiKeyOffsetFetch => OffsetFetchRequest::new(version)
    // apiKeyFindCoordinator => FindCoordinatorRequest::new(version)
    // apiKeyJoinGroup => JoinGroupRequest::new(version)
    // apiKeyHeartbeat => HeartbeatRequest::new(version)
    // apiKeyLeaveGroup => LeaveGroupRequest::new(version)
    // apiKeySyncGroup => SyncGroupRequest::new(version)
    // apiKeyDescribeGroups => DescribeGroupsRequest::new(version)
    // apiKeyListGroups => ListGroupsRequest::new(version)
    // apiKeySaslHandshake => SaslHandshakeRequest::new(version)
    apiKeyApiVersions => ApiVersionsRequest::new(version)
    // apiKeyCreateTopics => CreateTopicsRequest::new(version)
    // apiKeyDeleteTopics => DeleteTopicsRequest::new(version)
    // apiKeyDeleteRecords => DeleteRecordsRequest::new(version)
    // apiKeyInitProducerId => InitProducerIDRequest::new(version)
    // 23: OffsetForLeaderEpochRequest
    // apiKeyAddPartitionsToTxn => AddPartitionsToTxnRequest::new(version)
    // apiKeyAddOffsetsToTxn => AddOffsetsToTxnRequest::new(version)
    // apiKeyEndTxn => EndTxnRequest::new(version)
    // 27: WriteTxnMarkersRequest
    // apiKeyTxnOffsetCommit => TxnOffsetCommitRequest::new(version)
    // apiKeyDescribeAcls => DescribeAclsRequest::new(version)
    // apiKeyCreateAcls => CreateAclsRequest::new(version)
    // apiKeyDeleteAcls => DeleteAclsRequest::new(version)
    // apiKeyDescribeConfigs => DescribeConfigsRequest::new(version)
    // apiKeyAlterConfigs => AlterConfigsRequest::new(version)
    // 34: AlterReplicaLogDirsRequest
    // apiKeyDescribeLogDirs => DescribeLogDirsRequest::new(version)
    // apiKeySASLAuth => SaslAuthenticateRequest::new(version)
    // apiKeyCreatePartitions => CreatePartitionsRequest::new(version)
    // 38: CreateDelegationTokenRequest
    // 39: RenewDelegationTokenRequest
    // 40: ExpireDelegationTokenRequest
    // 41: DescribeDelegationTokenRequest
    // apiKeyDeleteGroups => DeleteGroupsRequest::new(version)
    // apiKeyElectLeaders => ElectLeadersRequest::new(version)
    // apiKeyIncrementalAlterConfigs =>
    //   IncrementalAlterConfigsRequest::new(version)
    // apiKeyAlterPartitionReassignments =>
    //   AlterPartitionReassignmentsRequest::new(version)
    // apiKeyListPartitionReassignments =>
    //   ListPartitionReassignmentsRequest::new(version)
    // apiKeyOffsetDelete => DeleteOffsetsRequest::new(version)
    // apiKeyDescribeClientQuotas => DescribeClientQuotasRequest::new(version)
    // apiKeyAlterClientQuotas => AlterClientQuotasRequest::new(version)
    // apiKeyDescribeUserScramCredentials =>
    //   DescribeUserScramCredentialsRequest::new(version)
    // apiKeyAlterUserScramCredentials =>
    //   AlterUserScramCredentialsRequest::new(version)
    // 52: VoteRequest
    // 53: BeginQuorumEpochRequest
    // 54: EndQuorumEpochRequest
    // 55: DescribeQuorumRequest
    // 56: AlterPartitionRequest
    // 57: UpdateFeaturesRequest
    // 58: EnvelopeRequest
    // 59: FetchSnapshotRequest
    // 60: DescribeClusterRequest
    // 61: DescribeProducersRequest
    // 62: BrokerRegistrationRequest
    // 63: BrokerHeartbeatRequest
    // 64: UnregisterBrokerRequest
    // 65: DescribeTransactionsRequest
    // 66: ListTransactionsRequest
    // 67: AllocateProducerIdsRequest
    // 68: ConsumerGroupHeartbeatRequest
    _ => return None
  }
  Some(body)
}
