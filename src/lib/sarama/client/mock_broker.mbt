///|
/// MockBroker is a mock Kafka broker that is used in unit tests. It is exposed
/// to facilitate testing of higher level or specialized consumers and producers
/// built on top of Sarama. Note that it does not 'mimic' the Kafka API protocol,
/// but rather provides a facility to do that. It takes care of the TCP
/// transport, request unmarshalling, response marshaling, and makes it the test
/// writer responsibility to program correct according to the Kafka API protocol
/// MockBroker behavior.
///
/// MockBroker is implemented as a TCP server listening on a kernel-selected
/// localhost port that can accept many connections. It reads Kafka requests
/// from that connection and returns responses programmed by the SetHandlerByMap
/// function. If a MockBroker receives a request that it has no programmed
/// response for, then it returns nothing and the request times out.
///
/// A set of MockRequest builders to define mappings used by MockBroker is
/// provided by Sarama. But users can develop MockRequests of their own and use
/// them along with or instead of the standard ones.
///
/// When running tests with MockBroker it is strongly recommended to specify
/// a timeout to `go test` so that if the broker hangs waiting for a response,
/// the test panics.
///
/// It is not necessary to prefix message length or correlation ID to your
/// response bytes, the server does that automatically as a convenience.struct MockBroker{}
struct MockBroker {
  broker_id : Int
}

///|
/// NewMockBroker launches a fake Kafka broker. It takes a TestReporter as provided by the
/// test framework and a channel of responses to use.  If an error occurs it is
/// simply logged and the broker exits.
pub fn MockBroker::new(broker_id : Int) -> MockBroker {
  // return NewMockBrokerAddr(t, brokerID, "localhost:0")
  { broker_id, }
}

///|
/// Close terminates the broker blocking until it stops internal goroutines and
/// releases all resources.
pub fn MockBroker::close(self : MockBroker) -> Unit {
  ...
}

///|
/// Addr returns the broker connection string in the form "<address>:<port>".
pub fn MockBroker::addr(self : MockBroker) -> String {
  // return b.listener.Addr().String()
  ...
}

///|
/// SetHandlerByMap defines mapping of Request types to MockResponses. When a
/// request is received by the broker, it looks up the request type in the map
/// and uses the found MockResponse instance to generate an appropriate reply.
/// If the request type is not found in the map then nothing is sent.
pub fn MockBroker::set_handler_by_map(
  self : MockBroker,
  handlerMap : Map[String, MockResponse],
) -> Unit {
  // fnMap := make(map[string]MockResponse)
  // maps.Copy(fnMap, handlerMap)
  // b.setHandler(func(req *request) (res encoderWithHeader) {
  // 	reqTypeName := reflect.TypeOf(req.body).Elem().Name()
  // 	mockResponse := fnMap[reqTypeName]
  // 	if mockResponse == nil {
  // 		return nil
  // 	}
  // 	return mockResponse.For(req.body)
  // })
  ...
}

///|
/// BrokerID returns broker ID assigned to the broker.
pub fn MockBroker::broker_id(self : MockBroker) -> Int {
  self.broker_id
}
