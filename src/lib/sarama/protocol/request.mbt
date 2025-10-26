///|
pub trait ProtocolBody: KafkaEncoder + ToJson {
  key(Self) -> Int16
  version(Self) -> Int16
  header_version(Self) -> Int16
  is_valid_version(Self) -> Bool
  required_version(Self) -> KafkaVersion
}

///|
pub(all) struct Request[T] {
  correlation_id : Int
  client_id : String
  body : T
} derive(ToJson)

///|
pub impl[T : ProtocolBody] KafkaEncoder for Request[T] with encode(self, pe) {
  pe.push(LengthField::default())
  let body = self.body
  pe.put_int16(body.key())
  pe.put_int16(body.version())
  pe.put_int(self.correlation_id)
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
pub fn Request::decode(
  pd : &PacketDecoder,
) -> Request[ProtocolBodyAdapter] raise PacketDecodingError {
  let key = pd.get_int16()
  let version = pd.get_int16()
  let correlation_id = pd.get_int()
  let client_id = pd.get_string()
  guard allocate_body(key, version) is Some((header_version, decode_fn)) else {
    raise PacketDecodingError("unknown request key (\{key})")
  }
  if header_version >= 2 {
    // tagged field
    ignore(pd.get_uvarint())
  }
  let body = decode_fn(pd, version)
  { correlation_id, client_id, body }
}

///|
pub async fn decode_request(
  r : &@io.Reader,
) -> (Request[ProtocolBodyAdapter], Int) {
  let lengthBytes = r.read_exactly(4)
  guard lengthBytes is [u32be(length)]
  if length <= 4 || length > MaxRequestSize {
    raise PacketDecodingError(
      "message of length \{length} too large or too small",
    )
  }
  let encodedReq = r.read_exactly(length.reinterpret_as_int())
  let bytesRead = 4 + encodedReq.length()
  let req = decode(encodedReq, Request::decode)
  return (req, bytesRead)
}

///|
pub fn allocate_body(
  key : Int16,
  version : Int16,
) -> (
  Int16,
  (&PacketDecoder, Int16) -> ProtocolBodyAdapter raise PacketDecodingError,
)? {
  let res = match key {
    // apiKeyProduce => ProduceRequest::new(version)
    ApiKeyFetch =>
      (
        FetchRequest::header_version(),
        fn(pd, version) raise PacketDecodingError {
          Fetch(FetchRequest::decode(pd, version))
        },
      )
    // apiKeyListOffsets => OffsetRequest::new(version)
    ApiKeyMetadata =>
      (
        MetadataRequest::header_version(version),
        fn(pd, version) raise PacketDecodingError {
          Metadata(MetadataRequest::decode(pd, version))
        },
      )
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
    ApiKeyListGroups =>
      (
        ListGroupsRequest::header_version(version),
        fn(pd, version) raise PacketDecodingError {
          ListGroups(ListGroupsRequest::decode(pd, version))
        },
      )
    ApiKeyDescribeConfigs =>
      (
        DescribeConfigsRequest::header_version(version),
        fn(pd, version) raise PacketDecodingError {
          DescribeConfigs(DescribeConfigsRequest::decode(pd, version))
        },
      )
    // apiKeySaslHandshake => SaslHandshakeRequest::new(version)
    ApiKeyApiVersions =>
      (
        ApiVersionsRequest::header_version(version),
        fn(pd, version) raise PacketDecodingError {
          ApiVersions(ApiVersionsRequest::decode(pd, version))
        },
      )
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
  Some(res)
}

///|
pub(all) enum ProtocolBodyAdapter {
  ApiVersions(ApiVersionsRequest)
  Metadata(MetadataRequest)
  Fetch(FetchRequest)
  ListGroups(ListGroupsRequest)
  ListGroupsResponse(ListGroupsResponse)
  DescribeConfigs(DescribeConfigsRequest)
} derive(Show, ToJson)

///|
pub impl ProtocolBody for ProtocolBodyAdapter with key(self) {
  match self {
    ApiVersions(body) => body.key()
    Metadata(body) => body.key()
    Fetch(body) => body.key()
    ListGroups(body) => body.key()
    ListGroupsResponse(body) => body.key()
    DescribeConfigs(body) => body.key()
  }
}

///|
pub impl ProtocolBody for ProtocolBodyAdapter with version(self) {
  match self {
    ApiVersions(body) => body.version()
    Metadata(body) => body.version()
    Fetch(body) => body.version()
    ListGroups(body) => body.version()
    ListGroupsResponse(body) => body.version()
    DescribeConfigs(body) => body.version()
  }
}

///|
pub impl ProtocolBody for ProtocolBodyAdapter with header_version(self) {
  match self {
    ApiVersions(body) => ProtocolBody::header_version(body)
    Metadata(body) => ProtocolBody::header_version(body)
    Fetch(body) => ProtocolBody::header_version(body)
    ListGroups(body) => ProtocolBody::header_version(body)
    ListGroupsResponse(body) => ProtocolBody::header_version(body)
    DescribeConfigs(body) => ProtocolBody::header_version(body)
  }
}

///|
pub impl ProtocolBody for ProtocolBodyAdapter with is_valid_version(self) {
  match self {
    ApiVersions(body) => body.is_valid_version()
    Metadata(body) => body.is_valid_version()
    Fetch(body) => body.is_valid_version()
    ListGroups(body) => body.is_valid_version()
    ListGroupsResponse(body) => body.is_valid_version()
    DescribeConfigs(body) => body.is_valid_version()
  }
}

///|
pub impl ProtocolBody for ProtocolBodyAdapter with required_version(self) {
  match self {
    ApiVersions(body) => body.required_version()
    Metadata(body) => body.required_version()
    Fetch(body) => body.required_version()
    ListGroups(body) => body.required_version()
    ListGroupsResponse(body) => body.required_version()
    DescribeConfigs(body) => body.required_version()
  }
}

///|
pub impl KafkaEncoder for ProtocolBodyAdapter with encode(self, pe) {
  match self {
    ApiVersions(body) => body.encode(pe)
    Metadata(body) => body.encode(pe)
    Fetch(body) => body.encode(pe)
    ListGroups(body) => body.encode(pe)
    ListGroupsResponse(body) => body.encode(pe)
    DescribeConfigs(body) => body.encode(pe)
  }
}
