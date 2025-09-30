///|
struct ApiVersionRange {
  minVersion : Int16
  maxVersion : Int16
}

///|
typealias Map[Int16, ApiVersionRange] as ApiVersionMap

// restrictApiVersion selects the appropriate API version for a given protocol body according to
// the client and broker version ranges. By default, it selects the maximum version supported by both
// client and broker, capped by the maximum Kafka version from Config.
// It then calls setVersion() on the protocol body.
// If no valid version is found, an error is returned.

///|
pub fn restrictApiVersion(
  pb : &ProtocolBody,
  brokerVersions : ApiVersionMap,
) -> Unit {
  let key = pb.key()
  // Since message constructors take a Kafka version and select the maximum supported protocol version already, we can
  // rely on pb.version() being the max version supported for the user-selected Kafka API version.
  let clientMax = pb.version()
  guard brokerVersions.get(key) is Some(brokerVersionRange) else { // no version ranges available, no restriction
    return
  }
  // Select the maximum version that both client and server support
  // Clamp to the client max to respect user preference above broker advertised version range
  pb.set_version(
    @cmp.minimum(
      clientMax,
      @cmp.maximum(
        @cmp.minimum(clientMax, brokerVersionRange.maxVersion),
        brokerVersionRange.minVersion,
      ),
    ),
  )
}

///|
const ApiKeyProduce : Int16 = 0

///|
const ApiKeyFetch : Int16 = 1

///|
const ApiKeyListOffsets : Int16 = 2

///|
const ApiKeyMetadata : Int16 = 3

///|
const ApiKeyLeaderAndIsr : Int16 = 4

///|
const ApiKeyStopReplica : Int16 = 5

///|
const ApiKeyUpdateMetadata : Int16 = 6

///|
const ApiKeyControlledShutdown : Int16 = 7

///|
const ApiKeyOffsetCommit : Int16 = 8

///|
const ApiKeyOffsetFetch : Int16 = 9

///|
const ApiKeyFindCoordinator : Int16 = 10

///|
const ApiKeyJoinGroup : Int16 = 11

///|
const ApiKeyHeartbeat : Int16 = 12

///|
const ApiKeyLeaveGroup : Int16 = 13

///|
const ApiKeySyncGroup : Int16 = 14

///|
const ApiKeyDescribeGroups : Int16 = 15

///|
const ApiKeyListGroups : Int16 = 16

///|
const ApiKeySaslHandshake : Int16 = 17

///|
const ApiKeyApiVersions : Int16 = 18

///|
const ApiKeyCreateTopics : Int16 = 19

///|
const ApiKeyDeleteTopics : Int16 = 20

///|
const ApiKeyDeleteRecords : Int16 = 21

///|
const ApiKeyInitProducerId : Int16 = 22

///|
const ApiKeyOffsetForLeaderEpoch : Int16 = 23

///|
const ApiKeyAddPartitionsToTxn : Int16 = 24

///|
const ApiKeyAddOffsetsToTxn : Int16 = 25

///|
const ApiKeyEndTxn : Int16 = 26

///|
const ApiKeyWriteTxnMarkers : Int16 = 27

///|
const ApiKeyTxnOffsetCommit : Int16 = 28

///|
const ApiKeyDescribeAcls : Int16 = 29

///|
const ApiKeyCreateAcls : Int16 = 30

///|
const ApiKeyDeleteAcls : Int16 = 31

///|
const ApiKeyDescribeConfigs : Int16 = 32

///|
const ApiKeyAlterConfigs : Int16 = 33

///|
const ApiKeyAlterReplicaLogDirs : Int16 = 34

///|
const ApiKeyDescribeLogDirs : Int16 = 35

///|
const ApiKeySASLAuth : Int16 = 36

///|
const ApiKeyCreatePartitions : Int16 = 37

///|
const ApiKeyCreateDelegationToken : Int16 = 38

///|
const ApiKeyRenewDelegationToken : Int16 = 39

///|
const ApiKeyExpireDelegationToken : Int16 = 40

///|
const ApiKeyDescribeDelegationToken : Int16 = 41

///|
const ApiKeyDeleteGroups : Int16 = 42

///|
const ApiKeyElectLeaders : Int16 = 43

///|
const ApiKeyIncrementalAlterConfigs : Int16 = 44

///|
const ApiKeyAlterPartitionReassignments : Int16 = 45

///|
const ApiKeyListPartitionReassignments : Int16 = 46

///|
const ApiKeyOffsetDelete : Int16 = 47

///|
const ApiKeyDescribeClientQuotas : Int16 = 48

///|
const ApiKeyAlterClientQuotas : Int16 = 49

///|
const ApiKeyDescribeUserScramCredentials : Int16 = 50

///|
const ApiKeyAlterUserScramCredentials : Int16 = 51
