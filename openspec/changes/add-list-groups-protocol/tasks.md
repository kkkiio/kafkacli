## 1. 规格与设计
- [ ] 1.1 撰写 protocol-list-groups 需求，明确请求/响应行为与版本差异
- [ ] 1.2 完成设计方案并评审编码/解码流程及集成点

## 2. ListGroupsRequest 实现
- [ ] 2.1 新建 `protocol/list_groups_request.mbt`，定义结构体、构造函数与状态/类型过滤器字段
- [ ] 2.2 实现编码逻辑：按版本写入 compact array 与 tagged fields
- [ ] 2.3 实现解码逻辑：正确恢复 filters 并跳过 tagged fields
- [ ] 2.4 编写请求方向测试，覆盖空过滤器、单条过滤器、v3+ tagged field

## 3. ListGroupsResponse 实现
- [ ] 3.1 新建 `protocol/list_groups_response.mbt`，定义 group map 与扩展数据结构
- [ ] 3.2 实现编码逻辑：兼容 v0-5、支持 groups_data 与 tagged fields
- [ ] 3.3 实现解码逻辑：填充 `groups`/`groups_data` map，并处理 throttle time
- [ ] 3.4 编写响应解码/编码测试，对齐 Go Sarama v0/v4/v5 样例

## 4. 集成与验证
- [ ] 4.1 在 `ProtocolBodyAdapter` 中注册 ListGroups 请求/响应
- [ ] 4.2 完善 `MockListGroupsResponse`，使用新结构生成响应
- [ ] 4.3 运行 `moon test` 与必要的 `moon test --update`，确保全部通过
