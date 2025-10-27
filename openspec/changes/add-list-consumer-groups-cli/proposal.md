## Why
- CLI 目前缺少一键查看 consumer groups 的能力，常规运维需要借助外部工具完成
- 已有 `ListGroups` 协议支持尚未暴露到命令行，用户无法获知现有 consumer group 列表
- 缺少 `--describe` 选项展示 topic partition 偏移，排查 lag 与消费进度困难

## What Changes
- 在 KafkaCLI 中新增 `list-consumer-groups` 子命令，输出每个 consumer group 的基础信息
- 当指定 `--describe` 开关时，补充展示各 group 成员的订阅 topic、partition 与 committed offset
- 为新增命令编写黑盒测试，覆盖普通列出与 describe 详情场景，并验证错误处理路径

## Impact
- 运维可直接用 KafkaCLI 查看 consumer groups 现状与 offset，减少对外部脚本依赖
- 拓展 CLI 功能范围，为后续扩展 consumer group lag 统计等特性提供数据基础
- 改动局限在 CLI 及相关 admin 逻辑，无破坏性接口变更
