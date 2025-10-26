## Why
- KafkaCLI 当前缺少 `list-topics` 子命令，无法直接查看集群主题与配置，影响基础运维流程
- Admin 层 `list_topics` 仅有占位实现，尚未串联 Metadata 与 DescribeConfigs 协议
- 现有协议库缺少 DescribeConfigs 支持，阻碍后续配置相关特性的实现

## What Changes
- 实现 DescribeConfigs 请求/响应的协议类型及编码解码逻辑，并完成快照测试
- 完成 ClusterAdmin `list_topics` 的两阶段请求流程，合并 topic 元数据与配置详情
- 在 `kafkacli` CLI 中新增 `list-topics` 子命令，支持 `--topics` 过滤与标准化输出
- 为 CLI 命令与 admin 层逻辑补充黑盒测试，覆盖成功与错误路径

## Impact
- CLI 获得主题列表能力，便于排查副本、分区与自定义配置
- 协议层补齐 DescribeConfigs，为后续配置查询/修改功能打基础
- 新增测试保持编码稳定性，整体改动局限在 admin 与 CLI 范围内，无破坏性接口变更
