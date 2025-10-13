# Project Context

## Purpose
KafkaCLI 是一个基于 MoonBit 语言开发的 Apache Kafka 客户端库和命令行工具。项目旨在提供：

1. **纯 MoonBit 实现的 Kafka 协议支持** - 完整实现 Kafka 协议，无需依赖外部 C 库
2. **轻量级 CLI 工具** - 提供 consume、list-topics、api-versions 等常用 Kafka 操作
3. **可复用的客户端库** - 为其他 MoonBit 项目提供 Kafka 集成能力

## Tech Stack

### 核心技术
- **MoonBit** - 新兴的静态类型编程语言，支持多后端编译（wasm、js、native）
- **Kafka Protocol** - 完整实现 Apache Kafka 二进制协议
- **Async Programming** - 使用 moonbitlang/async 进行异步网络操作

### 主要依赖
- **Yoorkin/ArgParser** (v0.1.11) - 命令行参数解析
- **moonbitlang/x** (v0.4.34) - 核心标准库扩展
- **moonbitlang/async** (v0.8.1) - 异步编程支持

### 编译目标
- **Native** - 首选目标，用于生产环境 CLI 工具

## Project Conventions

### Code Style

#### 命名规范
- **函数和变量**: `lower_snake_case`
- **类型和枚举**: `UpperCamelCase`
- **常量**: `UPPER_SNAKE_CASE`
- **文件名**: `lower_snake_case.mbt`

#### 代码组织
- 使用 `///|` 分隔顶级代码块

#### 文档和注释
- 使用 `///` 编写文档字符串
- 包含使用示例和类型说明
- 支持在文档中嵌入可运行的 MoonBit 代码

### Architecture Patterns

#### 包结构
```
src/
├── cmd/kafkacli/          # CLI 入口点
├── lib/
│   ├── sarama/           # Kafka 协议实现
│   │   ├── protocol/     # 协议编解码
│   │   ├── client/       # 客户端连接
│   │   ├── consumer/     # 消费者实现
│   │   ├── producer/     # 生产者实现
│   │   ├── admin/        # 管理操作
│   │   └── core/         # 核心类型和配置
│   └── encoding/         # 编码工具
└── openspec/             # 规格文档
```

#### 模块化设计
- 每个目录都是一个独立的 package
- 通过 `moon.pkg.json` 管理依赖关系
- 使用 `@package.function` 调用跨包函数

#### 错误处理
- 使用 MoonBit 的检查异常机制
- 函数声明 `raise` 标注可能抛出的错误类型
- 使用 `try?` 将异常转换为 `Result` 类型

### Testing Strategy

#### 测试类型
- **黑盒测试** (`*_test.mbt`) - 测试公共 API
- **白盒测试** (`*_wbtest.mbt`) - 测试内部实现
- **快照测试** - 使用 `inspect()` 进行结果验证

#### 测试命令
```bash
moon test              # 运行所有测试
moon test --update     # 更新快照
moon test -p package   # 测试特定包
```

#### 测试约定
- 优先使用黑盒测试
- 快照测试不填写 `content` 参数，运行 `moon test --update` 自动生成
- 使用 `@json.inspect()` 处理复杂结构

### Git Workflow

#### 分支策略
- **main** - 主分支，稳定版本
- **feat-* -** 功能分支，新特性开发

#### 提交规范
使用语义化提交信息：
- `feat:` - 新功能
- `fix:` - 修复 bug
- `refactor:` - 重构
- `test:` - 测试相关
- `docs:` - 文档更新

示例：
```
feat(list-topics): add list-topics cmd
feat(protocol): support metadata response
feat(functional-test): init functional-test
```

## Domain Context

### Kafka 协议知识
AI 助手需要理解以下 Kafka 概念：

#### 核心概念
- **Broker** - Kafka 服务器节点
- **Topic** - 消息分类
- **Partition** - Topic 的分区，支持并行处理
- **Consumer Group** - 消费者组，实现负载均衡
- **Offset** - 消息在分区中的位置

#### 协议消息类型
- **ApiVersionsRequest/Response** - 协商 API 版本
- **MetadataRequest/Response** - 获取集群元数据
- **FetchRequest/Response** - 消费者拉取消息
- **ProduceRequest/Response** - 生产者发送消息

#### 错误处理
- Kafka 协议中的错误码和错误处理
- 网络超时和重连机制
- 序列化/反序列化错误

### MoonBit 语言特性
- 表达式导向的语言设计
- 模式匹配和函数式控制流
- 检查异常系统
- 引用语义和可变性管理

## Important Constraints

### 技术约束
- **纯 MoonBit 实现** - 不依赖外部 C 库或 JNI

### 协议约束
- **版本协商** - 支持多版本 API 协商
- **错误处理** - 正确处理网络错误和协议错误

### 开发约束
- **MoonBit 生态** - 使用 MoonBit 生态系统内的包
- **测试覆盖** - 新功能必须包含相应的测试

## External Dependencies

### Kafka 集群
- **Bootstrap Servers** - Kafka 集群入口点
- **Zookeeper** - (可选) 旧版本 Kafka 的协调服务

### 网络依赖
- **TCP 连接** - 与 Kafka broker 的网络通信
- **DNS 解析** - broker 地址解析

### 开发工具
- **MoonBit CLI** - 编译、测试、构建工具
- **ArgParser** - 命令行参数解析库
- **Async Runtime** - 异步 I/O 支持

### 运行时环境
- **Native Backend**
