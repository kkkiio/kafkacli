## Why
- 消费功能需要 FetchRequest/FetchResponse 协议支持，当前缺失导致无法从 broker 拉取消息
- 与现有 ApiVersions/Metadata 协议保持一致的接口设计，便于后续客户端集成

## What Changes
- 移除 `protocol/types.mbt` 中的 Fetch 相关占位类型，改为独立文件贴近 Go Sarama 结构
- 新增 FetchRequest 结构与编码/解码逻辑，覆盖第一版消费必要字段
- 新增 FetchResponse 解码与编码能力，暂以字节形式暴露 records 原始数据
- 在 `_test.mbt` 中改用 `@json.inspect` 快照测试配合 `moon test --update`，并与 Go Sarama 测试数据核对
- 在协议调度器中注册新的请求/响应类型

## Impact
- 协议层新增类型，后续 consumer/client 模块可以直接构建 FetchRequest
- tests/ 构建新用例，`moon test` 时间略有增加但仍在可接受范围
- 不涉及 breaking change，现有功能保持不变
