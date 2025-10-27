## ADDED Requirements

### Requirement: list-consumer-groups 输出基础 group 列表

`kafkacli list-consumer-groups` MUST 调用 admin 层拉取全部 consumer group，并以 JSON 数组形式输出每个 group 的 ID、协议类型与状态。

#### Scenario: 成功列出所有 consumer group
- **GIVEN** 集群包含 consumer group `analytics`（协议类型 `consumer`，状态 `Stable`）与 `sync-job`（协议类型 `connect`，状态 `Empty`）
- **WHEN** 用户运行 `kafkacli list-consumer-groups --bootstrap-server localhost:9092`
- **THEN** 命令 stdout 输出的 JSON 数组包含对象 `{ "group_id": "analytics", "protocol_type": "consumer", "state": "Stable" }`
- **AND** 同一数组包含对象 `{ "group_id": "sync-job", "protocol_type": "connect", "state": "Empty" }`
- **AND** 命令退出码为 `0`

### Requirement: list-consumer-groups 支持 --describe 输出 offset 明细

当传入 `--describe` 时，命令 MUST 额外查询并展示 consumer group 已提交的 topic/partition offset 与元数据。

#### Scenario: 展示 committed offset 列表
- **GIVEN** consumer group `analytics` 对 topic `users` 的 partition `0` 提交的 offset 为 `42`
- **AND** `OffsetFetch` 返回 `metadata = ""` 且无错误
- **WHEN** 用户运行 `kafkacli list-consumer-groups --bootstrap-server localhost:9092 --describe`
- **THEN** 输出 JSON 中 `analytics` 对象包含 `offsets` 字段
- **AND** 该字段的数组包含 `{ "topic": "users", "partition": 0, "committed_offset": 42, "metadata": "" }`

### Requirement: list-consumer-groups 错误反馈

当 admin 操作失败时，命令 MUST 将错误信息输出到 stderr，并返回非零退出码。

#### Scenario: Broker 不可用
- **GIVEN** admin 层 `list_consumer_groups` 调用返回 `Err("BrokerNotAvailable")`
- **WHEN** 用户运行 `kafkacli list-consumer-groups --bootstrap-server localhost:9092`
- **THEN** stderr 输出包含 `BrokerNotAvailable`
- **AND** 命令退出码非零
