## ADDED Requirements

### Requirement: ListTopics 命令展示主题概要

`kafkacli list-topics` MUST 调用 ClusterAdmin，输出包含主题名称、分区数与复制因子的概要信息。

#### Scenario: 列出全部主题概要

- **GIVEN** Kafka 集群包含 topic `users`，其分区数为 `3`，复制因子为 `2`
- **WHEN** 用户运行 `kafkacli list-topics --bootstrap-server localhost:9092`
- **THEN** 命令输出中存在一行描述 `users`
- **AND** 该行显示分区数 `3` 与复制因子 `2`
- **AND** 命令退出码为 `0`

### Requirement: ListTopics 支持主题过滤

命令 MUST 接受 `--topics` 参数，并仅请求与展示指定主题。

#### Scenario: 筛选特定主题

- **GIVEN** 集群存在 `users` 与 `orders` 两个 topic
- **WHEN** 用户运行 `kafkacli list-topics --bootstrap-server localhost:9092 --topics users`
- **THEN** 命令仅请求并输出 `users` 的元数据与配置
- **AND** 输出中不包含 `orders`

### Requirement: ListTopics 错误反馈

当 Admin 层返回错误时，命令 MUST 输出错误信息到 stderr 并返回非零退出码。

#### Scenario: Broker 不可用

- **GIVEN** Admin `list_topics` 返回 `LeaderNotAvailable`
- **WHEN** 用户运行命令
- **THEN** stderr 输出包含 `LeaderNotAvailable`
- **AND** 命令退出码非零
