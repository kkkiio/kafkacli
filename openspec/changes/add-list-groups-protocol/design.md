## 背景
- 目前协议层缺少 ListGroups 请求/响应实现，CLI 无法列出消费者组
- Go Sarama (`list_groups_request.go` / `list_groups_response.go`) 已提供成熟逻辑，可作为 MoonBit 端的参考基线
- 协议模块已经存在 Fetch/Metadata 的独立文件与测试，沿用该模式最小化认知成本

## 目标行为
1. `ListGroupsRequest` 支持 Kafka 协议 v0–v5 的编码与解码，含状态/类型过滤器与 Tagged Fields
2. `ListGroupsResponse` 能还原 broker 返回的 groups map、可选状态与类型信息，并能序列化回字节流
3. 协议分发器 (`ProtocolBodyAdapter`) 能创建/识别 ListGroups 请求与响应，便于上层 client 复用
4. 单元测试覆盖空过滤器、单条过滤器、含扩展字段的多版本响应，结果与 Go Sarama 测试保持一致

## 结构设计
### ListGroupsRequest
- 字段：
  - `version : Int16`（实现 `ProtocolBody` 所需）
  - `states_filter : Array[String]`
  - `types_filter : Array[String]`
- 提供 `new()` 默认版本 0，以及 `with_version(version : Int16)` 便于测试指定版本
- 暴露 `set_states_filter` / `set_types_filter` helper? 暂不额外提供，直接操作字段即可（与现有 `FetchRequest` 一致）

### ListGroupsResponse
- 字段：
  - `version : Int16`
  - `throttle_time_ms : Int`
  - `error : KError`
  - `groups : Map[String, String]`（groupId → protocolType）
  - `groups_data : Map[String, ListGroupsGroupData]`（v4+ 可选）
- 辅助结构 `ListGroupsGroupData`：
  - `group_state : String`
  - `group_type : String`
- 提供 `new()` 与 `with_version(version)` 构造，仿照 FetchResponse

## 编解码要点
### Request
- v0–3：无过滤器字段；v3 引入 tagged fields（空数组）
- v4：写入 `states_filter` 为 compact string array；无元素时写长度 `1`（协议定义的 “0 元素” 表示为长度=1 的可变长整数）
- v5：同上，再写 `types_filter`
- 解码时遇到长度 0/1 需创建空数组（与 Sarama 行为一致，不保留 `nil`），以免后续 `for` 遍历触发 panic
- `header_version()`：v3+ 返回 2，否则 1
- `required_version()`：复用 Sarama 映射（v5→3.8.0, v4→2.6.0, …）

### Response
- v0–2：`groups` 使用常规 array + string
- v3+：`groups` / `protocolType` / `groupsData` 使用 compact 编码，末尾写入 empty tagged fields
- v4：附加 group state；v5：再附加 group type
- 顶层：v1 起写 `throttle_time_ms`，v3 起写 empty tagged field array
- 单个 group 的 tagged field 仅在 v3+ 出现，解码时调用 `get_empty_tagged_field_array()` 丢弃内容
- `header_version()`：v3+ 为 1，否则 0
- `is_valid_version()` 限定 0–5

## 集成调整
- `ProtocolBodyAdapter` 新增 `ListGroups(ListGroupsRequest)` / `ListGroupsResponse(ListGroupsResponse)` 变体，更新 match 分支的 encode/decode/isValid/requiredVersion
- `allocate_body` 在 `ApiKeyListGroups` case 下实例化 `ProtocolBodyAdapter::ListGroups`，默认 `with_version(version)`
- `MockListGroupsResponse` 使用新响应结构填充数据并返回 `ProtocolBodyAdapter::ListGroupsResponse`，便于后续 CLI 复用
- 若后续需要通过网络解码响应，将重用相同适配器（当前 decode 流程已支持）

## 测试策略
- 参考 Go Sarama 测试字节流，构造以下快照：
  1. 请求：v0 空体、v3 带 tagged field、v4/v5 含过滤器
  2. 响应：v0 空组、v0 错误码、v0 单组、v4/v5 含 state/type
- 使用 `inspect`/`@json.inspect` 生成快照，遵循项目约定：先留空 `content` 再通过 `moon test --update` 生成
- 额外测试编码路径：构造响应结构后重新编码，与输入样例逐字节比对

## 未决事项
- CLI 侧尚未定义 ListGroups 命令；待协议落地后在新的 change 中实现
- 如果未来支持 `GroupState`/`GroupType` 以外的新 tagged 字段，需在响应结构中扩展（设计保持向后兼容）
