## Why
- KafkaCLI 目前缺少 ListGroups 协议的编码与解码，导致无法实现 “列出消费者组” 功能
- 现有协议实现（ApiVersions、Metadata、Fetch）均参考 Go Sarama，保持一致性方便后续维护
- Kafka 集群管理流程依赖该协议了解组状态、类型等信息，需要尽快补齐

## What Changes
- 新增 `ListGroupsRequest` 结构体与版本感知的编码/解码逻辑，支持 states/types 过滤器
- 新增 `ListGroupsResponse` 结构体，解析并序列化 group map 与扩展元数据
- 在 `ProtocolBodyAdapter` 注册请求/响应，并补充 mock builder 以便测试与后续 CLI 集成
- 编写对齐 Go Sarama 的协议快照测试，覆盖 v0/v4/v5 等关键版本

## Impact
- 协议层新增类型，client/admin 模块可以直接发起 ListGroups 请求
- 新测试用例增加运行时间极小，未引入额外依赖
- 为后续 CLI 子命令和消费组管理特性铺路，无破坏性改动
