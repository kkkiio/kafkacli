## ADDED Requirements
### Requirement: ListGroupsRequest 版本化编码
ListGroupsRequest MUST 根据请求版本写入 compact filters 与 tagged fields，确保 v0–v5 均可被 broker 接受。

#### Scenario: EncodeStatesFilterV4
- **GIVEN** 创建版本为 4 的请求并填充 `states_filter = ["Empty"]`
- **WHEN** 调用 `encode(pe)`
- **THEN** 输出字节包含 compact array 长度 `2`、compact string `"Empty"`，并以空 tagged field 结束

#### Scenario: EncodeTypesFilterV5
- **GIVEN** 创建版本为 5 的请求，`states_filter = ["Stable"]`，`types_filter = ["Classic"]`
- **WHEN** 调用 `encode(pe)`
- **THEN** `states_filter` 与 `types_filter` 均写为 compact array，末尾追加空 tagged field，解码后能恢复原始数组

### Requirement: ListGroupsResponse 解析与序列化
ListGroupsResponse MUST 正确解析 v0–v5 的 group 列表、错误码与扩展字段，并能按照相同语义重新编码。

#### Scenario: DecodeEmptyV0
- **GIVEN** 一段 v0 响应字节表示无错误、无组
- **WHEN** 使用 `decode(pd, 0)`
- **THEN** `err` 等于 `ErrNoError`，`groups` 为空 map，编码后与输入字节一致

#### Scenario: DecodeStateTypeV5
- **GIVEN** 一段 v5 响应字节包含单个 group，携带 `GroupState="Empty"` 与 `GroupType="Classic"`
- **WHEN** 使用 `decode(pd, 5)`
- **THEN** `groups["foo"] == "consumer"`，`groups_data["foo"]` 同时包含 state/type，随后 `encode(pe)` 产出的字节逐字节等于原始输入
