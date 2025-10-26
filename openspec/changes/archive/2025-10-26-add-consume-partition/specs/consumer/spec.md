## ADDED Requirements

### Requirement: MVP Partition Consumer Implementation
系统 SHALL 提供简单的分区消费者 MVP 实现，支持不使用 consumer group 机制直接消费指定 topic 的 partition。

#### Scenario: Create partition consumer with specific offset
- **WHEN** 用户调用 `consumer.consume_partition(topic, partition, offset)` 方法
- **THEN** 系统 SHALL 创建一个新的分区消费者实例，从指定的 offset 开始消费
- **AND** 支持 `OffsetNewest` 和 `OffsetOldest` 常量作为特殊 offset 值
- **AND** 支持 Int64 类型的具体 offset 值

#### Scenario: Simple message fetching
- **WHEN** 分区消费者启动并调用消息获取方法
- **THEN** 系统 SHALL 通过 FetchRequest 从 Kafka broker 拉取消息
- **AND** 将拉取到的所有消息转换为 `ConsumerMessage` 结构数组返回
- **AND** 不做消息缓冲，直接返回本次 fetch 的所有消息

#### Scenario: Simple error handling
- **WHEN** 消费过程中发生网络错误或协议错误
- **THEN** 系统 SHALL 直接 raise 错误，不进行自动重试
- **AND** 包括网络连接错误、offset 越界、broker 永久不可达等错误（leader 相关错误除外）

#### Scenario: Automatic leader resolution
- **WHEN** Fetch 请求返回 `NotLeaderForPartition`、`LeaderNotAvailable` 或 `ReplicaNotAvailable`
- **THEN** 系统 SHALL 刷新指定 topic 的元数据
- **AND** SHALL 重新解析该分区的最新 leader broker 并重建连接
- **AND** SHALL 在新的 leader 上重试当前 Fetch 请求

#### Scenario: Basic resource cleanup
- **WHEN** 用户调用 `close()` 方法
- **THEN** 系统 SHALL 释放分区消费者占用的资源
- **AND** 不支持 `async_close()` 方法

### Requirement: Basic Offset Management
系统 SHALL 提供基础的 offset 管理功能。

#### Scenario: Starting offset selection
- **WHEN** 用户指定 offset 为 `OffsetNewest`
- **THEN** 系统 SHALL 查询当前最新 offset 并从该位置开始消费
- **WHEN** 用户指定 offset 为 `OffsetOldest`
- **THEN** 系统 SHALL 查询最早可用 offset 并从该位置开始消费
- **WHEN** 用户指定具体 offset 值
- **THEN** 系统 SHALL 验证 offset 范围并在有效时从该位置开始消费

#### Scenario: Offset range validation
- **WHEN** 用户指定的 offset 超出有效范围
- **THEN** 系统 SHALL raise `OffsetOutOfRange` 错误
- **AND** 不创建分区消费者实例

### Requirement: Simplified Consumer Interface Implementation
当前消费者接口定义了 `ConsumePartition` 方法，系统 SHALL 提供简化的 MVP 实现。

#### Scenario: Implement simplified consume_partition method
- **WHEN** 调用 `consumer_consume_partition(consumer, topic, partition, offset)`
- **THEN** 系统 SHALL 返回一个简化的分区消费者实例
- **AND** 该实例支持基本的分区消费操作
- **AND** 不检查重复消费同一 topic/partition
- **AND** 不支持暂停/恢复、高水位跟踪等高级功能
