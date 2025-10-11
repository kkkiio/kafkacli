# Kafka CLI 功能测试设计文档

## 概述

本文档描述了 Kafka CLI 项目的功能测试设计方案，基于 Go Sarama 的测试架构，使用 Docker 容器化环境和 Toxiproxy 网络模拟来验证 list-topics 命令在各种网络条件下的表现。

## 1. 测试架构

### 1.1 整体架构

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   宿主机测试     │───→│  Toxiproxy   │───→│   Kafka 集群     │
│   进程          │    │  Container   │    │   Containers    │
│ (MoonBit 程序)  │    │ :8474        │    │ kafka-1:9091    │
│ 127.0.0.1:29091 │    │              │    │ kafka-2:9091    │
│                 │    │              │    │ kafka-3:9091    │
└─────────────────┘    └──────────────┘    │ kafka-4:9091    │
                                          │ kafka-5:9091    │
                                          └─────────────────┘
```

### 1.2 组件说明

- **测试进程**：在宿主机运行的 MoonBit list-topics 程序
- **Toxiproxy**：网络代理，用于模拟各种网络故障条件
- **Kafka 集群**：5 节点 Kafka 集群，提供真实的 Kafka 服务
- **Zookeeper 集群**：3 节点 Zookeeper，支持 Kafka 集群协调

## 2. 测试环境配置

### 2.1 Docker Compose 环境

使用 `test/docker-compose.yml` 定义完整测试环境：

```yaml
# Kafka 节点配置
kafka-1 到 kafka-5:
  - 端口映射: 29091-29095 → 宿主机
  - 内部通信: 9091 → Docker 网络
  - 复制因子: 3 (支持故障恢复)

# Toxiproxy 配置
toxiproxy:
  - API端口: 8474
  - 代理端口: 29091-29095 → kafka-1:9091 到 kafka-5:9091
```

### 2.2 网络配置

每个 Kafka 节点配置双重监听器：
- **内部监听器**：`LISTENER_INTERNAL://:9091` - Docker 网络内部通信
- **外部监听器**：`LISTENER_LOCAL://:29091` - 对外提供服务

### 2.3 测试主题

预定义测试主题：
```go
testTopics = {
  "test.1": { partitions: 1, replication_factor: 3 },
  "test.4": { partitions: 4, replication_factor: 3 },
  "test.64": { partitions: 64, replication_factor: 3 }
}
```

## 3. Toxiproxy 集成

### 3.1 核心 API 使用

```http
# 代理管理
POST /proxies           # 创建代理
GET /proxies/{name}     # 获取代理信息
POST /proxies/{name}    # 更新代理状态
POST /reset             # 重置所有状态

# 网络故障模拟
POST /proxies/{name}/toxics  # 添加网络故障
```

### 3.2 MoonBit 客户端接口

```moonbit
pub type ToxiproxyClient

pub fn ToxiproxyClient::new(endpoint : String) -> ToxiproxyClient

// 代理管理
pub fn ToxiproxyClient::create_proxy(self : ToxiproxyClient, name : String, listen : String, upstream : String) -> Result[Unit, String]
pub fn ToxiproxyClient::disable_proxy(self : ToxiproxyClient, name : String) -> Result[Unit, String]
pub fn ToxiproxyClient::enable_proxy(self : ToxiproxyClient, name : String) -> Result[Unit, String]

// 网络故障模拟
pub fn ToxiproxyClient::add_latency(self : ToxiproxyClient, proxy_name : String, latency_ms : Int) -> Result[Unit, String]
pub fn ToxiproxyClient::disconnect_proxy(self : ToxiproxyClient, proxy_name : String) -> Result[Unit, String]
pub fn ToxiproxyClient::limit_bandwidth(self : ToxiproxyClient, proxy_name : String, rate_bps : Int) -> Result[Unit, String]

// 状态重置
pub fn ToxiproxyClient::reset_all(self : ToxiproxyClient) -> Result[Unit, String]
```

## 5. 测试实施流程

### 5.1 环境初始化

```bash
# 1. 启动测试环境
cd test/
docker compose up -d
```

### 9.2 调试技巧

```bash
# 查看 Toxiproxy 状态
curl http://localhost:8474/proxies

# 查看集群元数据
docker exec kafka-1 kafka-topics.sh --bootstrap-server localhost:9091 --describe

# 监控网络流量
docker exec toxiproxy netstat -i
```

## 11. 迁移至 Apache Kafka 官方镜像设计（可选优化）

### 11.1 迁移动机

当前自定义 Kafka 镜像存在以下问题：
- 构建时间长，依赖复杂
- 网络环境可能导致构建失败
- 维护成本高
- 非标准化配置

迁移至 Apache Kafka 官方镜像可以获得：
- 标准化的镜像构建
- 更好的社区支持
- 支持最新的 Kafka 版本
- 内置 KRaft 模式支持

### 11.2 KRaft Combined 模式架构

采用 KRaft Combined 模式替代当前的 Zookeeper + Kafka 架构：

```
当前架构：
┌─────────────┐    ┌─────────────┐
│ Zookeeper   │    │    Kafka    │
│   Cluster   │←──→│   Cluster   │
│ (3 nodes)   │    │  (5 nodes)  │
└─────────────┘    └─────────────┘

目标架构（KRaft Combined）：
┌─────────────────────────────────────┐
│        Kafka KRaft Cluster         │
│  ┌─────────┐  ┌─────────┐  ┌─────┐│
│  │ Node 1  │  │ Node 2  │  │ ... ││
│  │Broker+  │  │Broker+  │  │     ││
│  │Controller│ │Controller│ │     ││
│  └─────────┘  └─────────┘  └─────┘│
└─────────────────────────────────────┘
```

### 11.3 迁移配置设计

#### 11.3.1 新的 docker-compose.yml 配置

```yaml
services:
  kafka-1:
    image: apache/kafka:latest
    hostname: kafka-1
    container_name: kafka-1
    ports:
      - "29091:9092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: "broker,controller"
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT"
      KAFKA_CONTROLLER_QUORUM_VOTERS: "1@kafka-1:9093,2@kafka-2:9093,3@kafka-3:9093,4@kafka-4:9093,5@kafka-5:9093"
      KAFKA_LISTENERS: "PLAINTEXT://:19092,CONTROLLER://:9093,PLAINTEXT_HOST://:9092"
      KAFKA_INTER_BROKER_LISTENER_NAME: "PLAINTEXT"
      KAFKA_ADVERTISED_LISTENERS: "PLAINTEXT://kafka-1:19092,PLAINTEXT_HOST://localhost:29091"
      KAFKA_CONTROLLER_LISTENER_NAMES: "CONTROLLER"
      CLUSTER_ID: "MkU3OEVBNTcwNTJENDM2Qk"  # 生成新的集群ID
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 3

  kafka-2 到 kafka-5:
    # 类似配置，调整 node_id 和端口映射
    # kafka-2: 29092:9092, node_id: 2
    # kafka-3: 29093:9092, node_id: 3
    # kafka-4: 29094:9092, node_id: 4
    # kafka-5: 29095:9092, node_id: 5

  toxiproxy:
    # 保持不变
```

#### 11.3.2 环境变量映射对照表

| 当前自定义配置 | 官方镜像配置 | 说明 |
|----------------|--------------|------|
| `KAFKA_CFG_BROKER_ID` | `KAFKA_NODE_ID` | KRaft 模式使用 NODE_ID |
| `KAFKA_CFG_ZOOKEEPER_CONNECT` | 移除 | KRaft 模式不需要 Zookeeper |
| `KAFKA_CFG_LISTENERS` | `KAFKA_LISTENERS` | 配置格式不变 |
| `KAFKA_CFG_ADVERTISED_LISTENERS` | `KAFKA_ADVERTISED_LISTENERS` | 配置格式不变 |
| `KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP` | `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP` | 配置格式不变 |
| 新增 | `KAFKA_PROCESS_ROLES: "broker,controller"` | KRaft Combined 模式核心配置 |
| 新增 | `KAFKA_CONTROLLER_QUORUM_VOTERS` | Controller 选举配置 |
| 新增 | `CLUSTER_ID` | KRaft 集群唯一标识 |

### 11.4 迁移步骤

#### 阶段一：环境准备
1. 生成新的 CLUSTER_ID：
   ```bash
   # 使用官方工具生成
   docker run --rm apache/kafka:latest kafka-storage random-uuid
   ```

2. 备份当前测试数据：
   ```bash
   # 保存当前主题配置和测试脚本
   tar -czf kafka-test-backup.tar.gz test/
   ```

#### 阶段二：配置迁移
1. 更新 `test/docker-compose.yml`
2. 移除 Zookeeper 相关配置
3. 更新 Toxiproxy 代理配置
4. 调整测试脚本中的端口映射

#### 阶段三：验证测试
1. 启动新环境：
   ```bash
   cd test/
   docker compose up -d
   ```

2. 验证集群状态：
   ```bash
   # 检查 KRaft 集群元数据
   docker exec kafka-1 kafka-metadata-quorum.sh --bootstrap-server localhost:9092 describe --status
   ```

3. 运行功能测试：
   ```bash
   moon test -p functional_test
   ```

### 11.5 迁移风险评估

#### 高风险项
- **测试兼容性**：KRaft 模式与 Zookeeper 模式行为可能存在细微差异
- **网络配置**：监听器配置复杂度高，需要仔细测试

#### 中风险项
- **性能差异**：KRaft 模式性能特征可能与 Zookeeper 模式不同
- **工具脚本**：现有的管理和调试脚本需要适配

#### 低风险项
- **端口映射**：保持现有端口映射策略
- **Toxiproxy 集成**：网络故障模拟逻辑不变


### 11.7 长期收益

迁移完成后，预期获得以下收益：
- **构建时间**：从 5-10 分钟缩短至 1-2 分钟
- **维护成本**：降低 80% 的自定义镜像维护工作
- **版本更新**：可以快速跟进 Kafka 官方版本
- **社区支持**：获得 Apache Kafka 社区的最佳实践支持

建议在当前测试环境稳定运行的基础上，选择合适的时机进行迁移验证。
