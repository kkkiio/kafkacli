## 1. 协议层 DescribeConfigs

- [x] 1.1 新建 `protocol/describe_configs_request.mbt`/`describe_configs_response.mbt`，定义核心结构
- [x] 1.2 实现多版本编码/解码逻辑，覆盖资源数组与 tagged fields
- [x] 1.3 编写协议快照测试，对齐 Sarama 样例数据

## 2. Admin 层 list_topics

- [x] 2.1 使用 MetadataResponse 构建 TopicDetail，补齐分区、副本、复制因子
- [x] 2.2 发送 DescribeConfigsRequest 并合并返回的配置条目
- [x] 2.3 完成 `cluster_admin_list_topics` 实现并处理协议/网络错误

## 3. CLI 集成

- [x] 3.1 在 `main.mbt` 注册 `list-topics` 子命令并解析 `--bootstrap-server` 与 `--topics`
- [x] 3.2 调用 admin 接口获取主题详情，输出包含名称、分区数、复制因子与配置摘要
- [x] 3.3 为 CLI 行为增加黑盒测试或 e2e 脚本（使用 mock/admin stub）

## 4. 验证

- [x] 4.1 运行 `moon test`（必要时 `moon test --update`）保证全部通过
- [x] 4.2 自查文档与代码，准备提交审批
