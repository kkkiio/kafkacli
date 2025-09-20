# 设计一个纯 MoonBit 的 Kafka 客户端

用 `moonbitlang/async` 从头开始实现一个 Kafka 客户端，移除对 `librdkafka` 的 C 语言依赖，意味着需要用 MoonBit 来实现 Kafka 的网络协议。这是一个相当大的工程，但通过分步实现是完全可行的。

### 工作概览

将这个任务分解，主要包含以下几个关键步骤：

1.  **理解 Kafka 协议**: 这是最核心和最耗时的工作。`librdkafka` 为你封装了所有协议细节，现在你需要自己处理。你需要了解：
    *   **请求/响应格式**: Kafka 的所有通信都基于二进制的请求-响应模式。每个 API（如 `Fetch`, `Metadata`, `Produce`）都有自己精确的请求和响应结构。
    *   **消息格式**: 消息本身（包括 key, value, headers, timestamp 等）是如何序列化和反序列化的。
    *   **Broker 发现 (Bootstrapping)**: 客户端开始时只连接一个或几个 "bootstrap servers"。它需要通过发送 `MetadataRequest` 来发现集群中的所有 broker 以及 topic/partition 的 leader 是谁。
    *   **消费流程**: 对于消费者来说，流程通常是：
        1.  连接到 bootstrap server。
        2.  发送 `MetadataRequest` 获取 topic 的 partition leader 信息。
        3.  (如果使用 consumer group) 发送 `FindCoordinatorRequest` 找到消费者组的协调器 (Coordinator)。
        4.  发送 `JoinGroupRequest` 和 `SyncGroupRequest` 加入组并被分配 partition。
        5.  定期发送 `HeartbeatRequest` 以保持在组内。
        6.  发送 `FetchRequest` 到 partition leader 来拉取消息（这就是你提到的 `poll` 功能的核心）。
        7.  发送 `OffsetCommitRequest` 来提交消费位移。

2.  **实现网络通信**: 使用 `moonbitlang/async/socket` 来建立与 Kafka Broker 的 TCP 连接。
    *   你需要一个函数来连接到指定的 `host:port`。
    *   你需要能够异步地发送二进制数据（序列化后的请求）和接收二进制数据（待反序列化的响应）。

3.  **实现请求/响应的序列化和反序列化**: Kafka 协议对每个字段的类型（如 `INT16`, `INT32`, `STRING`, `BYTES`）和顺序都有严格规定。
    *   你需要为每个要实现的 API（如 `MetadataRequest`, `FetchRequest`）创建对应的数据结构。
    *   你需要编写 `encode` 函数将请求结构体序列化为 `Bytes`。
    *   你需要编写 `decode` 函数将从 socket 收到的 `Bytes` 反序列化为响应结构体。

4.  **实现核心客户端逻辑**:
    *   **Broker 管理**: 维护一个集群元数据缓存，包括所有 broker 的地址和 topic-partition 的 leader 信息。当连接失败或收到特定错误码时，需要刷新这个缓存。
    *   **消费逻辑 (Poll)**: `poll` 函数的内部循环大致是：
        *   向 leader broker 发送 `FetchRequest`。
        *   等待并解析 `FetchResponse`。
        *   将收到的消息批次返回给用户。
        *   处理各种错误，例如 `NOT_LEADER_FOR_PARTITION`（需要刷新元数据）、`OFFSET_OUT_OF_RANGE` 等。
    *   **Consumer Group 管理**: 如果要支持 consumer group，需要实现心跳机制。这通常在后台通过一个独立的异步任务完成，使用 `moonbitlang/async` 的 `with_task_group` 和 `spawn` 会非常适合。

### 如何开始：一个简化的实现路径

从零开始会很复杂，建议从最简化的场景入手：**从一个指定的 Topic Partition 读取消息，不使用 Consumer Group**。

#### 第 1 步: 连接并获取元数据

1.  **目标**: 连接到一个 bootstrap server，并获取指定 topic 的元数据。
2.  **协议**:
    *   实现 `ApiVersionsRequest` 和 `ApiVersionsResponse`：这可以帮助你了解 broker 支持的 API 版本，虽然在初期可以先硬编码版本号。
    *   实现 `MetadataRequest` 和 `MetadataResponse`：这是关键。你需要能够构造一个请求来查询某个 topic 的信息，并能解析响应，从中提取出 partitions 列表以及每个 partition 的 `leader_id`。然后根据 broker 列表找到 leader 的地址。
3.  **代码**:
    *   创建一个 `Client` 结构体，包含一个 `TcpStream`。
    *   编写一个 `connect` 函数，使用 `async/socket` 连接到 broker。
    *   编写 `send_request` 和 `receive_response` 的辅助函数。
    *   实现 `get_metadata` 函数，它会发送 `MetadataRequest` 并返回解析后的元数据。

#### 第 2 步: 实现 `Fetch` 功能 (你的 `poll`)

1.  **目标**: 从上一步找到的 leader broker 拉取消息。
2.  **协议**:
    *   实现 `FetchRequest` 和 `FetchResponse`。`FetchRequest` 需要指定要从哪个 topic-partition 的哪个 offset 开始拉取，以及最大等待时间和最小/最大字节数。`FetchResponse` 会返回一批消息。
3.  **代码**:
    *   在你的 `Client` 中添加一个 `fetch_messages` 函数。
    *   这个函数会根据 `get_metadata` 的结果连接到正确的 leader broker。
    *   然后它会进入一个循环，不断发送 `FetchRequest`（每次都更新 offset）并处理 `FetchResponse`。
    *   你需要实现消息集的解析逻辑，这在较新的 Kafka 版本中是 `RecordBatch` 格式，有一定的复杂性（比如有 CRC 校验和可能的压缩）。

### 总结：协议是关键

总的来说，你提到的 `poll` 功能主要对应 Kafka 的 `Fetch` API。但要成功发送一个 `FetchRequest`，你必须先通过 `MetadataRequest` 找到正确的 broker。因此，**`Metadata` 和 `Fetch` 是你首先要攻克的两个协议**。

**推荐资源**:

*   **Kafka 官方协议文档**: 这是最权威的参考。请仔细阅读 [Kafka Protocol Guide](https://kafka.apache.org/protocol)。这里详细描述了每个 API 的请求/响应结构、每个字段的类型和含义。
