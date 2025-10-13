# Kafka Consumer 实现任务清单

## 概述

基于 Go Sarama 实现分析，本文档列出了在 MoonBit Kafka CLI 项目中实现 FetchRequest/FetchResponse 协议的详细任务清单。

## 分析总结

### Go Sarama FetchRequest 关键特性
- **版本支持**: v0-v11 (支持 Kafka 0.8.2 到 2.3.0+)
- **核心字段**:
  - `ReplicaID`: 消费者固定为 -1
  - `MaxWaitTime`: 最大等待时间
  - `MinBytes/MaxBytes`: 响应大小控制
  - `IsolationLevel`: 事务隔离级别 (v4+)
  - `SessionID/SessionEpoch`: Fetch 会话管理 (v7+)
- **数据结构**: `map[string]map[int32]*fetchRequestBlock` 嵌套映射

### Go Sarama FetchResponse 关键特性
- **响应结构**: `Blocks map[string]map[int32]*FetchResponseBlock`
- **核心字段**:
  - `ThrottleTime`: 限流时间 (v1+)
  - `HighWaterMarkOffset`: 高水位标记
  - `LastStableOffset`: 最后稳定偏移量 (v4+)
  - `AbortedTransactions`: 中止事务列表 (v4+)
  - `RecordsSet`: 消息记录集合

### 当前 MoonBit Protocol 包结构
- ✅ **基础架构**: `Encoder`/`VersionedDecoder` trait
- ✅ **协议体**: `ProtocolBody` trait
- ✅ **请求封装**: `Request[T]` 泛型结构
- ✅ **示例实现**: `ApiVersionsRequest`/`ApiVersionsResponse`
- ❌ **Fetch 协议**: 缺少 FetchRequest/Response 实现
- ❌ **类型定义**: `types.mbt` 中只有基础类型定义

## 实现任务清单

### 阶段 1: 基础类型定义

#### 1.1 创建 IsolationLevel 枚举
**文件**: `src/lib/sarama/core/types.mbt`
**任务**:
```moonbit
pub enum IsolationLevel {
  ReadUncommitted = 0
  ReadCommitted   = 1
} derive(Eq, Show, ToJson)
```

#### 1.2 扩展 AbortedTransaction 类型
**文件**: `src/lib/sarama/core/types.mbt`
**任务**:
```moonbit
pub struct AbortedTransaction {
  producer_id  : Int64
  first_offset : Int64
} derive(Show, ToJson)
```

### 阶段 2: FetchRequest 实现

#### 2.1 创建 FetchRequestBlock 结构
**文件**: `src/lib/sarama/protocol/fetch_request.mbt`
**任务**:
```moonbit
pub struct FetchRequestBlock {
  current_leader_epoch : Int32  // v9+
  fetch_offset          : Int64
  log_start_offset      : Int64  // v5+
  max_bytes             : Int32
  version               : Int16
}
```

**实现的 trait**:
- `Encoder` - 编码到 PacketEncoder
- `VersionedDecoder` - 从 PacketDecoder 解码
- 版本兼容性处理 (v0-v11)

#### 2.2 创建 FetchRequest 主结构
**文件**: `src/lib/sarama/protocol/fetch_request.mbt`
**任务**:
```moonbit
pub struct FetchRequest {
  replica_id            : Int32
  max_wait_time         : Int32
  min_bytes             : Int32
  max_bytes             : Int32  // v3+
  isolation_level       : IsolationLevel  // v4+
  session_id            : Int32  // v7+
  session_epoch         : Int32  // v7+
  blocks                : Map[String, Map[Int32, FetchRequestBlock>>
  forgotten             : Map[String, Array[Int32]]  // v7+
  rack_id               : String  // v11+
  mut version           : Int16
}
```

**实现的 trait**:
- `ProtocolBody` - 协议体接口
- `Encoder` - 编码实现
- `VersionedDecoder` - 解码实现

**关键方法**:
- `new(version: Int16) -> FetchRequest`
- `add_block(topic: String, partition: Int32, offset: Int64, max_bytes: Int32, leader_epoch: Int32) -> Unit`
- 版本兼容性检查 `is_valid_version()`
- 必需版本映射 `required_version()`

### 阶段 3: FetchResponse 实现

#### 3.1 创建 FetchResponseBlock 结构
**文件**: `src/lib/sarama/protocol/fetch_response.mbt`
**任务**:
```moonbit
pub struct FetchResponseBlock {
  err                    : Int16  // KError
  high_water_mark_offset : Int64
  last_stable_offset     : Int64  // v4+
  log_start_offset       : Int64  // v5+
  aborted_transactions   : Array[AbortedTransaction]  // v4+
  preferred_read_replica : Int32  // v11+
  records_set            : Array[Bytes]  // 简化的消息记录
  partial                : Bool
}
```

**实现的 trait**:
- `Encoder` - 编码实现
- `VersionedDecoder` - 解码实现，处理消息记录解析

#### 3.2 创建 FetchResponse 主结构
**文件**: `src/lib/sarama/protocol/fetch_response.mbt`
**任务**:
```moonbit
pub struct FetchResponse {
  throttle_time : Int32  // v1+
  error_code    : Int16  // v7+
  session_id    : Int32  // v7+
  blocks        : Map[String, Map[Int32, FetchResponseBlock]]
  mut version   : Int16
}
```

**实现的 trait**:
- `ProtocolBody` - 协议体接口
- `Encoder` - 编码实现
- `VersionedDecoder` - 解码实现

**关键方法**:
- `new(version: Int16) -> FetchResponse`
- `get_block(topic: String, partition: Int32) -> FetchResponseBlock?`
- `add_error(topic: String, partition: Int32, error: Int16) -> Unit`

### 阶段 4: 协议注册

#### 4.1 更新 request.mbt
**文件**: `src/lib/sarama/protocol/request.mbt`
**任务**:
- 在 `allocate_body` 函数中添加 FetchRequest 支持
- 更新 `ProtocolBodyAdapter` 枚举
- 添加对应的 Encoder/VersionedDecoder 实现

**具体修改**:
```moonbit
// 在 allocate_body 中添加
ApiKeyFetch => Fetch(FetchRequest::new(version))

// 在 ProtocolBodyAdapter 中添加
Fetch(FetchRequest)
```

#### 4.2 更新 types.mbt
**文件**: `src/lib/sarama/protocol/types.mbt`
**任务**:
- 移除现有的简化 FetchRequest/Response 类型定义
- 确保类型引用正确

### 阶段 5: 测试实现

#### 5.1 创建单元测试
**文件**:
- `src/lib/sarama/protocol/fetch_request_test.mbt`
- `src/lib/sarama/protocol/fetch_response_test.mbt`

**测试任务**:
- 编码解码正确性测试
- 版本兼容性测试 (v0-v11)
- 边界条件测试
- 错误处理测试

#### 5.2 集成测试
**文件**: `src/lib/sarama/protocol/fetch_integration_test.mbt`
**测试任务**:
- 完整请求/响应流程测试
- 与真实 Kafka broker 的集成测试

### 阶段 6: Consumer 集成

#### 6.1 更新 Consumer 实现
**文件**: `src/lib/sarama/consumer/consumer.mbt`
**任务**:
- 集成新的 FetchRequest/Response
- 实现真实的消息消费逻辑
- 添加 offset 管理功能

#### 6.2 更新 Client 实现
**文件**: `src/lib/sarama/client/`
**任务**:
- 添加 `fetch()` 方法
- 处理网络请求和响应
- 错误处理和重试机制

### 阶段 7: CLI 命令实现

#### 7.1 完善 consume.mbt
**文件**: `src/cmd/kafkacli/consume.mbt`
**任务**:
- 实现真实的消费逻辑
- 添加参数验证
- 实现优雅关闭

## 实现优先级

### 高优先级 (P0)
1. **FetchRequest 基础实现** - 核心消费功能
2. **FetchResponse 基础实现** - 响应解析
3. **协议注册** - 集成到现有框架
4. **基础测试** - 确保功能正确

### 中优先级 (P1)
1. **版本兼容性** - 支持多个 Kafka 版本
2. **Consumer 集成** - 实现完整消费流程
3. **错误处理** - 完善异常处理
4. **性能优化** - 批量处理等

### 低优先级 (P2)
1. **高级特性** - Fetch 会话、事务支持等
2. **完整测试覆盖** - 边界条件测试
3. **CLI 完善** - 参数扩展和用户体验

## 关键技术点

### 版本兼容性策略
- 使用 `version` 字段控制编码/解码逻辑
- 通过 `required_version()` 方法指定最低 Kafka 版本
- 渐进式支持新特性

### 消息记录处理
- 简化实现：直接使用 `Bytes` 类型存储记录
- 后续扩展：添加完整的 MessageSet/RecordBatch 解析

### 错误处理
- 统一使用 Kafka 错误码
- 提供友好的错误消息
- 实现重试机制

## 验收标准

### 功能验收
- [ ] 成功发送 FetchRequest 到 Kafka broker
- [ ] 正确解析 FetchResponse 并提取消息
- [ ] 支持基本的 offset 管理
- [ ] 实现 consume 命令的基础功能

### 质量验收
- [ ] 所有单元测试通过
- [ ] 代码覆盖率 > 80%
- [ ] 支持 Kafka 1.0+ 版本
- [ ] 性能满足基本要求

### 兼容性验收
- [ ] 与现有 protocol 框架兼容
- [ ] 不破坏现有 API
- [ ] 支持未来版本扩展