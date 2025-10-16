## ADDED Requirements
### Requirement: FetchRequest 编码解码
FetchRequest MUST 支持版本 0-11 的关键字段编码与解码（含 MaxBytes、IsolationLevel、Session、RackID 等扩展），并允许通过方法增量添加分区 block。

#### Scenario: EncodeSingleBlockV0
- **GIVEN** 使用版本 0 创建 FetchRequest 并添加 1 个分区 block
- **WHEN** 调用 `encode(pe)`
- **THEN** 输出字节包含 MaxWaitTime、MinBytes 以及分区内的 `fetch_offset` 和 `max_bytes`

#### Scenario: DecodeSessionRackIdV11
- **GIVEN** 一段符合协议 v11 的二进制数据，包含 session、leader epoch、rack id
- **WHEN** 使用 `decode(pd, 11)`
- **THEN** FetchRequest 实例恢复 SessionID、SessionEpoch、RackID，并在 block 中填充 leader epoch

### Requirement: FetchResponse 解析与序列化
FetchResponse MUST 支持版本 0-11 的字段解析与写回，包含高水位、LSO、LogStartOffset、PreferredReadReplica，并以 `Bytes` 原样暴露 records 数据。

#### Scenario: DecodeBlockWithRecordsV4
- **GIVEN** 一段包含高水位、LSO、records payload 的 v4 响应数据
- **WHEN** 调用 `decode(pd, 4)`
- **THEN** 返回结构含 topic->partition block，block 中 error、HighWaterMarkOffset、LastStableOffset 与 `records` 字节保持一致

#### Scenario: EncodeResponseWithError
- **GIVEN** 构造含顶层 ErrorCode、SessionID、单个 block 的 FetchResponse
- **WHEN** 调用 `encode(pe)`
- **THEN** 生成的二进制依次写入 ThrottleTime、ErrorCode、SessionID 以及分区 block 字段，records 使用原样字节长度前缀
