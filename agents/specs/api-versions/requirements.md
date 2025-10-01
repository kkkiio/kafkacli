# Requirements

api-versions 子命令需要仿照 Kafka 官方 `kafka-broker-api-versions.sh` 工具的行为，通过网络查询 broker 并打印其支持的 API 版本信息。

## 命令形式

```bash
kafkacli api-versions --bootstrap-server host1:9092
```

## 行为要求

- 不提供 `--version` 参数，也不尝试输出 broker 的软件版本或 commit hash。
- 运行后，按照官方实现 `BrokerApiVersionsCommand` 的格式打印每个可达 broker 的 `NodeApiVersions` 信息：
  - 第一行：`<host>:<port> (id: <brokerId> rack: <rack|null> isFenced: <true|false>) -> (`
  - 中间多行：每行代表一个 API，形如 `\t<ApiName>(<ApiKey>): <MinVersion> to <MaxVersion> [usable: <LatestUsableVersion>]`；若不可用则为 `UNSUPPORTED`，末尾与官方保持相同的逗号规则。
  - 最后一行：`)`
- 输出的顺序、缩进、逗号位置等细节需要与官方命令保持一致，方便对比验证。
