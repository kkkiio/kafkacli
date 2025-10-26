///|
pub typealias Int64 as Milliseconds

///|
const DefaultRetryBackoffMs : Milliseconds = 100

///|
const DefaultRetryMaxBackoffMs : Milliseconds = 1000

// Encoder is a simple interface for any type that can be encoded as an array of bytes
// in order to be sent as the key or value of a Kafka message. Length() is provided as an
// optimization, and must return the same as len() on the result of Encode().

///|
pub trait MessageEncoder {
  encode(Self) -> Bytes raise
  length(Self) -> Int
}
// make strings and byte slices encodable for convenience so they can be used as keys
// and/or values in kafka messages

///|
pub impl MessageEncoder for String with encode(self) {
  return @encoding/utf8.encode(self)
}

///|
pub impl MessageEncoder for String with length(self) {
  return self.length()
}

///|
pub impl MessageEncoder for Bytes with encode(self) {
  return self
}

///|
pub impl MessageEncoder for Bytes with length(self) {
  return self.length()
}

// KafkaVersion instances represent versions of the upstream Kafka broker.
// it's a struct rather than just typing the array directly to make it opaque and stop people
// generating their own arbitrary versions

///|
pub struct KafkaVersion(FixedArray[UInt])

///|
pub fn KafkaVersion::new(
  major : UInt,
  minor : UInt,
  veryMinor : UInt,
  patch : UInt,
) -> KafkaVersion {
  KafkaVersion([major, minor, veryMinor, patch])
}

// IsAtLeast return true if and only if the version it is called on is
// greater than or equal to the version passed in:
//
//	V1.IsAtLeast(V2) // false
//	V2.IsAtLeast(V1) // true

///|
pub fn KafkaVersion::is_at_least(
  self : KafkaVersion,
  other : KafkaVersion,
) -> Bool {
  for i, _ in self.0 {
    if self.0[i] > other.0[i] {
      return true
    } else if self.0[i] < other.0[i] {
      return false
    }
  }
  return true
}

// Effective constants defining the supported kafka versions.

///|
let v0_8_2_0 : KafkaVersion = KafkaVersion::new(0, 8, 2, 0)

///|
let v0_8_2_1 : KafkaVersion = KafkaVersion::new(0, 8, 2, 1)

///|
let v0_8_2_2 : KafkaVersion = KafkaVersion::new(0, 8, 2, 2)

///|
let v0_9_0_0 : KafkaVersion = KafkaVersion::new(0, 9, 0, 0)

///|
let v0_9_0_1 : KafkaVersion = KafkaVersion::new(0, 9, 0, 1)

///|
let v0_10_0_0 : KafkaVersion = KafkaVersion::new(0, 10, 0, 0)

///|
let v0_10_0_1 : KafkaVersion = KafkaVersion::new(0, 10, 0, 1)

///|
let v0_10_1_0 : KafkaVersion = KafkaVersion::new(0, 10, 1, 0)

///|
let v0_10_1_1 : KafkaVersion = KafkaVersion::new(0, 10, 1, 1)

///|
let v0_10_2_0 : KafkaVersion = KafkaVersion::new(0, 10, 2, 0)

///|
let v0_10_2_1 : KafkaVersion = KafkaVersion::new(0, 10, 2, 1)

///|
let v0_10_2_2 : KafkaVersion = KafkaVersion::new(0, 10, 2, 2)

///|
let v0_11_0_0 : KafkaVersion = KafkaVersion::new(0, 11, 0, 0)

///|
let v0_11_0_1 : KafkaVersion = KafkaVersion::new(0, 11, 0, 1)

///|
let v0_11_0_2 : KafkaVersion = KafkaVersion::new(0, 11, 0, 2)

///|
let v1_0_0_0 : KafkaVersion = KafkaVersion::new(1, 0, 0, 0)

///|
let v1_0_1_0 : KafkaVersion = KafkaVersion::new(1, 0, 1, 0)

///|
let v1_0_2_0 : KafkaVersion = KafkaVersion::new(1, 0, 2, 0)

///|
let v1_1_0_0 : KafkaVersion = KafkaVersion::new(1, 1, 0, 0)

///|
let v1_1_1_0 : KafkaVersion = KafkaVersion::new(1, 1, 1, 0)

///|
let v2_0_0_0 : KafkaVersion = KafkaVersion::new(2, 0, 0, 0)

///|
let v2_0_1_0 : KafkaVersion = KafkaVersion::new(2, 0, 1, 0)

///|
let v2_1_0_0 : KafkaVersion = KafkaVersion::new(2, 1, 0, 0)

///|
let v2_1_1_0 : KafkaVersion = KafkaVersion::new(2, 1, 1, 0)

///|
let v2_2_0_0 : KafkaVersion = KafkaVersion::new(2, 2, 0, 0)

///|
let v2_2_1_0 : KafkaVersion = KafkaVersion::new(2, 2, 1, 0)

///|
let v2_2_2_0 : KafkaVersion = KafkaVersion::new(2, 2, 2, 0)

///|
let v2_3_0_0 : KafkaVersion = KafkaVersion::new(2, 3, 0, 0)

///|
let v2_3_1_0 : KafkaVersion = KafkaVersion::new(2, 3, 1, 0)

///|
let v2_4_0_0 : KafkaVersion = KafkaVersion::new(2, 4, 0, 0)

///|
let v2_4_1_0 : KafkaVersion = KafkaVersion::new(2, 4, 1, 0)

///|
let v2_5_0_0 : KafkaVersion = KafkaVersion::new(2, 5, 0, 0)

///|
let v2_5_1_0 : KafkaVersion = KafkaVersion::new(2, 5, 1, 0)

///|
let v2_6_0_0 : KafkaVersion = KafkaVersion::new(2, 6, 0, 0)

///|
let v2_6_1_0 : KafkaVersion = KafkaVersion::new(2, 6, 1, 0)

///|
let v2_6_2_0 : KafkaVersion = KafkaVersion::new(2, 6, 2, 0)

///|
let v2_6_3_0 : KafkaVersion = KafkaVersion::new(2, 6, 3, 0)

///|
let v2_7_0_0 : KafkaVersion = KafkaVersion::new(2, 7, 0, 0)

///|
let v2_7_1_0 : KafkaVersion = KafkaVersion::new(2, 7, 1, 0)

///|
let v2_7_2_0 : KafkaVersion = KafkaVersion::new(2, 7, 2, 0)

///|
let v2_8_0_0 : KafkaVersion = KafkaVersion::new(2, 8, 0, 0)

///|
let v2_8_1_0 : KafkaVersion = KafkaVersion::new(2, 8, 1, 0)

///|
let v2_8_2_0 : KafkaVersion = KafkaVersion::new(2, 8, 2, 0)

///|
let v3_0_0_0 : KafkaVersion = KafkaVersion::new(3, 0, 0, 0)

///|
let v3_0_1_0 : KafkaVersion = KafkaVersion::new(3, 0, 1, 0)

///|
let v3_0_2_0 : KafkaVersion = KafkaVersion::new(3, 0, 2, 0)

///|
let v3_1_0_0 : KafkaVersion = KafkaVersion::new(3, 1, 0, 0)

///|
let v3_1_1_0 : KafkaVersion = KafkaVersion::new(3, 1, 1, 0)

///|
let v3_1_2_0 : KafkaVersion = KafkaVersion::new(3, 1, 2, 0)

///|
let v3_2_0_0 : KafkaVersion = KafkaVersion::new(3, 2, 0, 0)

///|
let v3_2_1_0 : KafkaVersion = KafkaVersion::new(3, 2, 1, 0)

///|
let v3_2_2_0 : KafkaVersion = KafkaVersion::new(3, 2, 2, 0)

///|
let v3_2_3_0 : KafkaVersion = KafkaVersion::new(3, 2, 3, 0)

///|
let v3_3_0_0 : KafkaVersion = KafkaVersion::new(3, 3, 0, 0)

///|
let v3_3_1_0 : KafkaVersion = KafkaVersion::new(3, 3, 1, 0)

///|
let v3_3_2_0 : KafkaVersion = KafkaVersion::new(3, 3, 2, 0)

///|
let v3_4_0_0 : KafkaVersion = KafkaVersion::new(3, 4, 0, 0)

///|
let v3_4_1_0 : KafkaVersion = KafkaVersion::new(3, 4, 1, 0)

///|
let v3_5_0_0 : KafkaVersion = KafkaVersion::new(3, 5, 0, 0)

///|
let v3_5_1_0 : KafkaVersion = KafkaVersion::new(3, 5, 1, 0)

///|
let v3_5_2_0 : KafkaVersion = KafkaVersion::new(3, 5, 2, 0)

///|
let v3_6_0_0 : KafkaVersion = KafkaVersion::new(3, 6, 0, 0)

///|
let v3_6_1_0 : KafkaVersion = KafkaVersion::new(3, 6, 1, 0)

///|
let v3_6_2_0 : KafkaVersion = KafkaVersion::new(3, 6, 2, 0)

///|
let v3_7_0_0 : KafkaVersion = KafkaVersion::new(3, 7, 0, 0)

///|
let v3_7_1_0 : KafkaVersion = KafkaVersion::new(3, 7, 1, 0)

///|
let v3_7_2_0 : KafkaVersion = KafkaVersion::new(3, 7, 2, 0)

///|
let v3_8_0_0 : KafkaVersion = KafkaVersion::new(3, 8, 0, 0)

///|
let v3_8_1_0 : KafkaVersion = KafkaVersion::new(3, 8, 1, 0)

///|
let v3_9_0_0 : KafkaVersion = KafkaVersion::new(3, 9, 0, 0)

///|
let v4_0_0_0 : KafkaVersion = KafkaVersion::new(4, 0, 0, 0)

///|
let supported_versions : Array[KafkaVersion] = [
  v0_8_2_0, v0_8_2_1, v0_8_2_2, v0_9_0_0, v0_9_0_1, v0_10_0_0, v0_10_0_1, v0_10_1_0,
  v0_10_1_1, v0_10_2_0, v0_10_2_1, v0_10_2_2, v0_11_0_0, v0_11_0_1, v0_11_0_2, v1_0_0_0,
  v1_0_1_0, v1_0_2_0, v1_1_0_0, v1_1_1_0, v2_0_0_0, v2_0_1_0, v2_1_0_0, v2_1_1_0,
  v2_2_0_0, v2_2_1_0, v2_2_2_0, v2_3_0_0, v2_3_1_0, v2_4_0_0, v2_4_1_0, v2_5_0_0,
  v2_5_1_0, v2_6_0_0, v2_6_1_0, v2_6_2_0, v2_6_3_0, v2_7_0_0, v2_7_1_0, v2_7_2_0,
  v2_8_0_0, v2_8_1_0, v2_8_2_0, v3_0_0_0, v3_0_1_0, v3_0_2_0, v3_1_0_0, v3_1_1_0,
  v3_1_2_0, v3_2_0_0, v3_2_1_0, v3_2_2_0, v3_2_3_0, v3_3_0_0, v3_3_1_0, v3_3_2_0,
  v3_4_0_0, v3_4_1_0, v3_5_0_0, v3_5_1_0, v3_5_2_0, v3_6_0_0, v3_6_1_0, v3_6_2_0,
  v3_7_0_0, v3_7_1_0, v3_7_2_0, v3_8_0_0, v3_8_1_0, v3_9_0_0, v4_0_0_0,
]

///|
pub let min_version : KafkaVersion = v0_8_2_0

///|
pub let max_version : KafkaVersion = v4_0_0_0

///|
pub let default_version : KafkaVersion = v2_1_0_0

// reduced set of protocol versions to matrix test

///|
let fvtRangeVersions : Array[KafkaVersion] = [
  v0_8_2_2, v0_10_2_2, v1_0_2_0, v1_1_1_0, v2_0_1_0, v2_2_2_0, v2_4_1_0, v2_6_3_0,
  v2_8_2_0, v3_1_2_0, v3_3_2_0, v3_6_2_0,
]

// This regex validates that a string complies with the pre kafka 1.0.0 format for version strings, for example 0.11.0.3
// let validPreKafka1Version = regexp.MustCompile(`^0\.\d+\.\d+\.\d+$`)

// // This regex validates that a string complies with the post Kafka 1.0.0 format, for example 1.0.0
// let validPostKafka1Version = regexp.MustCompile(`^\d+\.\d+\.\d+$`)

// ParseKafkaVersion parses and returns kafka version or error from a string

///|
fn parse_kafka_version(s : String) -> KafkaVersion raise {
  if s.length() < 5 {
    raise PacketDecodingError("invalid version \{s}")
  }
  match s {
    [.. "0.", .. rest] =>
      match
        rest.split(".").map(fn(x) { try? @strconv.parse_int(x) }).to_array() {
        [Ok(minor), Ok(veryMinor), Ok(patch)] =>
          return KafkaVersion::new(
            0,
            minor.reinterpret_as_uint(),
            veryMinor.reinterpret_as_uint(),
            patch.reinterpret_as_uint(),
          )
        _ => raise PacketDecodingError("invalid version \{s}")
      }
    _ =>
      match s.split(".").map(fn(x) { try? @strconv.parse_int(x) }).to_array() {
        [Ok(major), Ok(minor), Ok(veryMinor)] =>
          return KafkaVersion::new(
            major.reinterpret_as_uint(),
            minor.reinterpret_as_uint(),
            veryMinor.reinterpret_as_uint(),
            0,
          )
        _ => raise PacketDecodingError("invalid version \{s}")
      }
  }
}

///|
pub impl Show for KafkaVersion with output(self, logger) {
  let s = if self.0[0] == 0 {
    "0.\{self.0[1]}.\{self.0[2]}.\{self.0[3]}"
  } else {
    "\{self.0[0]}.\{self.0[1]}.\{self.0[2]}"
  }
  logger.write_string(s)
}

///|
pub impl ToJson for KafkaVersion with to_json(self) {
  self.to_string().to_json()
}

// NewExponentialBackoff returns a function that implements an exponential backoff strategy with jitter.
// It follows KIP-580, implementing the formula:
// MIN(retry.backoff.max.ms, (retry.backoff.ms * 2**(failures - 1)) * random(0.8, 1.2))
// This ensures retries start with `backoff` and exponentially increase until `maxBackoff`, with added jitter.
// The behavior when `failures = 0` is not explicitly defined in KIP-580 and is left to implementation discretion.
//
// Example usage:
//
//	backoffFunc := sarama.NewExponentialBackoff(config.Producer.Retry.Backoff, 2*time.Second)
//	config.Producer.Retry.BackoffFunc = backoffFunc

///|
pub fn new_exponential_backoff(
  backoff : Milliseconds,
  maxBackoff : Milliseconds,
) -> ((Int, Int) -> Milliseconds) raise {
  if backoff < 0 {
    raise fail("backoff is negative")
  }
  let backoff = if backoff == 0 { DefaultRetryBackoffMs } else { backoff }
  if maxBackoff < 0 {
    raise fail("maxBackoff is negative")
  }
  let maxBackoff = if maxBackoff == 0 {
    DefaultRetryMaxBackoffMs
  } else {
    maxBackoff
  }
  if backoff > maxBackoff {
    raise fail("backoff(\{backoff}) is greater than maxBackoff(\{maxBackoff})")
  }
  let rand = @random.Rand::new()
  return fn(retries, _) -> Milliseconds {
    if retries <= 0 {
      return backoff
    }
    let jitter = 0.8 + 0.4 * rand.double()
    let exp = 1L << (retries - 1)
    let c = ((backoff * exp).to_double() * jitter).to_int64()
    return @cmp.minimum(c, maxBackoff)
  }
}

///|
/// Join host and port into address string
pub fn join_host_port(host : String, port : Int) -> String {
  "\{host}:\{port}"
}

///|
pub fn split_host_port(hostport : String) -> (String, Int) raise {
  let parts = hostport.split(":").to_array()
  if parts.length() != 2 {
    raise fail("invalid hostport \{hostport}")
  }
  let port = @strconv.parse_int(parts[1]) catch {
    _ => fail("invalid port \{parts[1]}")
  }
  (parts[0].to_string(), port)
}
