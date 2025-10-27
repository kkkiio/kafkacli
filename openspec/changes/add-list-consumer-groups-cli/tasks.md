## 1. Admin 层 consumer groups

- [x] 1.1 在 admin 包新增 `cluster_admin_list_consumer_groups`，封装 ListGroups 请求与错误处理
- [x] 1.2 实现 `cluster_admin_describe_consumer_group_offsets`，调用 OffsetFetch 获取全部 partition offset
- [x] 1.3 为新增函数补充黑盒测试（mock client/decoder），覆盖成功与错误场景

## 2. CLI 集成

- [x] 2.1 在 `main.mbt` 注册 `list-consumer-groups` 子命令，解析 `--bootstrap-server` 与 `--describe`
- [x] 2.2 编写 CLI 逻辑调用 admin 接口并输出 JSON，基础模式仅展示 group 信息
- [x] 2.3 `--describe` 模式下合并 offset 明细并按规范字段输出

## 3. 测试与验证

- [x] 3.1 添加 CLI 层函数的单元测试或快照测试，覆盖 describe/on 情况
- [x] 3.2 运行 `moon test`（必要时 `moon test --update`）确保全部通过
