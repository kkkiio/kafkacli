## 1. 基础分区消费者实现
- [x] 1.1 完善 `KafkaPartitionConsumer` 结构体，只保留必要字段
- [x] 1.2 实现简单的分区消费者创建逻辑
- [x] 1.3 允许 `KafkaPartitionConsumer` 更新内部状态（`offset`、`is_closed` 标记为 `mut`）
- [x] 1.4 在 `close` 中设置关闭状态并在二次 `fetch_messages` 时阻止访问
- [x] 1.5 移除异步通道和复杂状态管理

## 2. FetchRequest 集成（基础框架）
- [x] 2.1 实现从 `FetchRequest` 到 Kafka broker 的网络请求框架
- [x] 2.2 实现 `FetchResponse` 的解析和消息提取
- [x] 2.3 直接返回解析结果，不做缓冲
- [x] 2.4 简单的错误处理：遇到错误直接 raise

## 3. Offset 管理与校验
- [x] 3.1 支持 OffsetNewest/OffsetOldest 分支逻辑
- [x] 3.2 查询并返回最新/最早 offset
- [x] 3.3 校验自定义 offset 范围，越界时返回明确错误
- [x] 3.4 移除高水位标记跟踪

## 4. 简化的消息处理
- [x] 4.1 实现 `fetch_messages` 方法，返回 `ConsumerMessage` 数组
- [x] 4.2 添加 FetchResponse 到 `ConsumerMessage` 的转换逻辑
- [x] 4.3 在成功拉取后更新下次拉取使用的 offset
- [x] 4.4 不实现 pause/resume 功能

## 5. CLI 与文档
- [x] 5.1 实现 `consume-partition` CLI 命令
- [x] 5.2 调整 CLI 输出以展示最新 offset 并提示下一步使用方式
- [x] 5.3 更新消费者相关方法的文档字符串
- [x] 5.4 添加 `consume-partition` 命令示例与当前限制说明

## 6. 自动 leader 选择
- [x] 6.1 在 `KafkaPartitionConsumer.dispatch` 中刷新元数据并解析最新 leader
- [x] 6.2 在 `broker_consumer` 处理 Fetch 响应时，针对 leader 相关错误触发重新调度
- [x] 6.3 新增或扩展测试，验证 leader 漂移后仍能继续消费
- [x] 6.4 更新 CLI/文档，说明自动切换 leader 的行为与限制
