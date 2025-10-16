## 1. 规格与接口
- [x] 1.1 撰写 protocol-fetch 需求，确保覆盖请求与响应要点

## 2. FetchRequest 实现
- [x] 2.1 清理 `protocol/types.mbt` 中已有的 FetchRequest 相关占位类型
- [x] 2.2 新增 `protocol/fetch_request.mbt`，定义结构体与编码逻辑，结构贴近 Go Sarama
- [x] 2.3 实现解码与 `add_block` 方法，处理版本差异
- [x] 2.4 编写与 Go Sarama 行为一致的测试用例（覆盖无 block、单 block、不同版本）

## 3. FetchResponse 实现
- [x] 3.1 清理 `protocol/types.mbt` 中已有的 FetchResponse 相关占位类型
- [x] 3.2 新增 `protocol/fetch_response.mbt`，定义响应结构与最小化记录表示，结构贴近 Go Sarama
- [x] 3.3 实现解码/编码逻辑，保留 records 原始字节
- [x] 3.4 编写与 Go Sarama 行为保持一致的测试验证字段解析、偏移计算与错误处理

## 4. 框架集成与验证
- [x] 4.1 更新协议 Body 分发逻辑以支持 FetchRequest/FetchResponse
- [x] 4.2 运行 `moon test` 并确保所有测试通过
- [x] 4.3 在 `_test.mbt` 中使用 `@json.inspect` 快照取代硬编码字节串，执行 `moon test --update` 生成快照，再对照 Go 版测试确认内容一致
