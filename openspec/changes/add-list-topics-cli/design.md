# 设计概要

## 背景

- 当前代码库已具备 Metadata 协议与 ClusterAdmin 框架，仅缺 DescribeConfigs 及 CLI 集成

## 协议扩展

- `DescribeConfigsRequest`/`DescribeConfigsResponse` 采用 Kafka v0.11+ 编码，低版本不支持 tagged fields
- 资源列表使用 compact array 表示 topic 名称，兼容 empty tagged fields
- ConfigEntry 仅保留 `Default=false` 且 `Sensitive=false` 的键值，符合 Sarama 过滤策略

## Admin 流程

1. 基于现有客户端选取活跃 broker，发送 MetadataRequest（topic 列表可选指定子集）
2. 将 MetadataResponse 转换为 TopicDetail：统计 `num_partitions`、`replication_factor` 与 `replica_assignment`
3. 构造 DescribeConfigsRequest，收集所有 topic 资源并一次性请求配置
4. 合并 DescribeConfigsResponse，将过滤后的配置写入 TopicDetail `config_entries`

## CLI 命令

- `kafkacli list-topics` 接受 `--bootstrap-server <host:port>`，可选 `--topics topic1,topic2`
- 命令输出结构化 JSON 文本：包含 topic 名称、分区数、复制因子、配置项

## 错误处理

- 当 Metadata 或 DescribeConfigs 抛出错误时，将错误原文输出到 stderr 并返回非零退出码
