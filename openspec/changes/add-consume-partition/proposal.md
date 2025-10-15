## Why
当前的 Kafka 消费者实现虽然包含了 `ConsumePartition` 方法的接口定义，但实际的实现还不完整。用户需要一个简单的 MVP 版本，支持不依赖 consumer group 机制直接消费指定 topic 的 partition，实现基本的分区消费功能。通过 `consume-partition` 命令，用户可以直接从指定分区消费消息。

## What Changes
- 完善 `ConsumePartition` 方法的实现，支持不使用 consumer group 机制消费指定 topic 的 partition
- 实现 `consume-partition` CLI 命令，支持命令行直接消费指定分区
- 实现 MVP 版本的分区消费者核心功能：
  - 从指定 offset 开始消费（支持 OffsetNewest/OffsetOldest/具体值）
  - 通过 FetchRequest 从 Kafka broker 拉取消息并返回所有消息
  - 简单的错误处理机制（遇到错误直接 raise）
  - 基础的 close 方法用于资源清理
- **不包含**：自动重试、自动 leader 切换、自动 broker 重连
- **不包含**：async_close 方法、消息缓冲、pause/resume 功能
- **不包含**：high_water_mark_offset 方法、重复消费检查

## Impact
- Affected specs: consumer 功能规格
- Affected code:
  - `src/lib/sarama/consumer/consumer.mbt` - 主要实现文件
  - `src/cmd/kafkacli/consume.mbt` - CLI 命令实现
  - `src/lib/sarama/core/types.mbt` - 可能需要添加相关类型
  - 相关的测试文件

**BREAKING CHANGES**: 无，这是新功能的完整实现

## Dependencies
- 需要网络连接和 Kafka 协议的底层支持
- 需要异步编程支持（moonbitlang/async）
- 需要现有的 KafkaClient 基础设施
- 需要现有的 ArgParser 用于命令行参数解析