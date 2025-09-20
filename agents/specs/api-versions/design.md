# `api-versions` 子命令设计方案

本文档描述了 `kafkacli` 中 `api-versions` 子命令的设计与实现步骤。该命令用于查询并显示 Kafka broker 支持的 API 版本信息，类似于 `kafka-broker-api-versions.sh` 脚本。

## 1. 目标

实现 `kafkacli api-versions --bootstrap-server <host:port>` 命令，使其能够连接到指定的 Kafka broker，获取其软件版本，并将其打印到控制台。

预期输出示例：
```bash
$ kafkacli api-versions --bootstrap-server localhost:9092
3.3.1 (Commit:e23c59d00e687ff5)
```

## 2. 高层设计

1.  **命令行参数解析**:
    *   在 `src/main/main.mbt` 中添加对 `api-versions` 子命令的识别。
    *   为 `api-versions` 命令创建一个新的入口文件 `src/api-versions/main.mbt`。
    *   在新文件中，使用 `@ArgParser` 解析 `--bootstrap-server` 参数，获取 broker 的地址。

2.  **网络通信**:
    *   使用 `moonbitlang/async/socket` 库与指定的 broker 建立 TCP 连接。

3.  **协议实现**:
    *   **请求构建**: 根据 Kafka 协议规范，手动构建一个 `ApiVersionsRequest` 的二进制消息。为了获取 `BrokerSoftwareVersion`，我们需要发送版本为 3 的请求。
    *   **请求发送与响应接收**: 将构建好的二进制请求通过 TCP socket 发送给 broker，并异步等待接收响应。
    *   **响应解析**: 解析 broker 返回的 `ApiVersionsResponse` 二进制数据。特别地，我们需要提取 `BrokerSoftwareVersion` 字段。

4.  **输出**:
    *   将解析出的 `BrokerSoftwareVersion` 字符串打印到标准输出。

## 3. Kafka 协议细节

我们将使用 `ApiVersions` API，其 `ApiKey` 为 18。

### ApiVersionsRequest (版本 3)

为了获取 broker 的软件版本，我们需要发送至少版本为 3 的 `ApiVersionsRequest`。该版本的请求体包含客户端软件信息，可以为空字符串。

请求结构:
```
Request Header
  Request ApiKey = 18 (ApiVersions)
  Request ApiVersion = 3
  Correlation Id = ...
  Client Id = ...
Request Body (v3)
  ClientSoftwareName (STRING)
  ClientSoftwareVersion (STRING)
```

我们将发送一个空的 `ClientSoftwareName` 和 `ClientSoftwareVersion`。

### ApiVersionsResponse (版本 3)

响应体包含 broker 支持的所有 API 的版本范围，以及 broker 的软件版本。

响应结构:
```
Response Header
  Correlation Id = ...
Response Body (v3)
  ErrorCode (INT16)
  ApiKeys
    ApiKey (INT16)
    MinVersion (INT16)
    MaxVersion (INT16)
  ThrottleTimeMs (INT32)
  BrokerSoftwareVersion (STRING)
```

我们的目标是解析出 `BrokerSoftwareVersion` 字段。

## 4. 实现步骤

1.  **创建 `src/api-versions/main.mbt`**:
    *   添加 `main` 函数作为 `api-versions` 子命令的入口。
    *   实现参数解析逻辑。

2.  **创建 `src/lib/protocol.mbt` (或类似模块)**:
    *   定义 `ApiVersionsRequest` 和 `ApiVersionsResponse` 的数据结构。
    *   实现 `encode_api_versions_request` 函数，将请求结构体序列化为 `Bytes`。
    *   实现 `decode_api_versions_response` 函数，将 `Bytes` 反序列化为响应结构体。
    *   这些函数需要处理 Kafka 协议中的基本数据类型（如 `INT16`, `INT32`, `STRING`）的编码和解码。

3.  **创建 `src/lib/client.mbt`**:
    *   实现一个 `get_api_versions` 函数，该函数接收 `bootstrap_server` 地址作为参数。
    *   内部逻辑：
        1.  连接到 broker。
        2.  调用 `encode_api_versions_request` 构建请求。
        3.  发送请求并接收响应。
        4.  调用 `decode_api_versions_response` 解析响应。
        5.  返回 `BrokerSoftwareVersion`。

4.  **整合与测试**:
    *   在 `src/api-versions/main.mbt` 中调用 `get_api_versions` 函数。
    *   将 `api-versions` 作为一个新的构建目标添加到 `moon.pkg.json` 中。
    *   在 `src/main/main.mbt` 中添加 `api-versions` 子命令的分支，当匹配到该命令时，调用 `api-versions` 包的 `main` 函数。
    *   编译并运行 `kafkacli api-versions` 命令进行测试。
