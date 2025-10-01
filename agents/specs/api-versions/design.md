# `api-versions` 子命令设计方案

本文档描述 `kafkacli` 中 `api-versions` 子命令的目标与实现步骤。该命令需要仿照 Kafka 官方 `kafka-broker-api-versions.sh` / `BrokerApiVersionsCommand` 的行为，通过网络查询 broker 并打印其支持的 API 版本信息。

## 1. 目标

实现命令：

```bash
kafkacli api-versions --bootstrap-server <host:port>
```

要求与官方工具保持相同的输出格式：

```
<broker-address> (id: <id> rack: <rack|null> isFenced: <true|false>) -> (
	<ApiName>(<ApiKey>): <min> to <max> [usable: <latest>],
	...
)
```

## 2. 高层设计

1. **命令行解析与集成**

   - 在 `src/cmd/kafkacli/main.mbt`（或现有主命令入口）中添加 `api-versions` 分支。
   - 新建 `src/cmd/kafkacli/api_versions.mbt`，使用 `@ArgParser` 解析 `--bootstrap-server` 参数，调用执行逻辑。

2. **网络通信与未支持项**

   - 使用 `moonbitlang/async/socket` 等库与 `--bootstrap-server` 指定的 broker 建立 TCP 连接。
   - 暂不提供 `--version` 参数，也不尝试输出 broker 的软件版本/commit。

3. **协议实现**

   - 构造 `ApiVersionsRequest` v3（或更高版本）请求。
   - 通过 Socket 发送请求并读取响应。
   - 解析 `ApiVersionsResponse`：
     - `ErrorCode`
     - `ApiKeys` 列表 (`ApiKey` / `MinVersion` / `MaxVersion`)
     - `ThrottleTimeMs`
     - Tagged fields：`SupportedFeatures`、`FinalizedFeatures`、`ZkMigrationReady`
   - 根据解析结果组装 `NodeApiVersions` 风格的数据结构（需模拟官方 `NodeApiVersions` 的 `toString(true)` 行为）。

4. **输出格式化**
   - 第一行打印 `<host>:<port> (id: <id> rack: <rack|null> isFenced: <true|false>) -> (`。
   - 中间逐行打印 API 信息：
     - 支持的 API：`\t<ApiName>(<ApiKey>): <MinVersion> to <MaxVersion> [usable: <LatestUsableVersion>]`。
     - 若某 API 不适用于 broker 的监听类型或未报告，则输出 `UNSUPPORTED`。
     - 逗号位置与官方实现保持一致（最后一项无逗号）。
   - 末行打印 `)`。

## 3. Kafka 协议细节

- `ApiKey`: 18 (`ApiVersions`).
- 请求至少使用 v3，以便使用 flexible 结构；请求体字段：
  - `ClientSoftwareName` (STRING, 可为空串)
  - `ClientSoftwareVersion` (STRING, 可为空串)
  - tagged fields（空）
- 响应结构（v3+）：
  - `ErrorCode`
  - `ApiKeys` 数组（可能为 compact 编码）
  - `ThrottleTimeMs`
  - tagged fields：`SupportedFeatures`、`FinalizedFeaturesEpoch`、`FinalizedFeatures`、`ZkMigrationReady`

## 4. 实现步骤

1. **命令入口**

   - 创建 `src/cmd/kafkacli/api_versions.mbt`，实现 `run(bootstrap_server)` 等函数，负责：
     - 解析 host/port 列表
     - 依次与 broker 建立连接并查询
     - 汇总输出

2. **协议封装**

   - 复用或扩展 `src/lib/sarama/protocol` 下的请求/响应编码器：
     - 确保 `ApiVersionsResponse` 支持 tag 字段解析，并提供访问 API 列表的方法。
     - 实现帮助方法（如 `format_node_api_versions`）来复现官方输出。

3. **网络与逻辑**

   - 连接到指定 broker，发送 `ApiVersionsRequest`。
   - 有必要时，通过 `MetadataRequest` 获取全部 broker 列表（保持与官方一致；若仅返回一个 broker，也可先实现单节点查询，后续扩展）。
   - 对每个 broker 调用 `ApiVersions`，聚合结果。

4. **输出格式化**

   - 实现格式化函数，模拟 `NodeApiVersions::toString(true)` 的换行/逗号规则。
   - 将每个 broker 的信息按上述格式打印。

5. **测试与验证**
   - 补充 MoonBit 测试覆盖 `ApiVersionsResponse` 解码、格式化输出等。
   - 手动对比官方工具输出，确保格式一致。
