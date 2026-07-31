# MioAni 下一位 Agent 交接说明

生成时间：2026-07-31
工作区：`E:/CodeLearning/Flutter/mio_ani`
用途：让新的 agent 在不重复 C1/C2、不误动用户文件、直接复用已完成的 C3–C9 规划并只实施用户指定任务的前提下接手 MioAni。

## 1. 交接边界

- 用户已在剩余任务规划完成后恢复 C3 源码实施，并要求每次执行窗口不超过 10 分钟；超过前必须停止并询问是否继续。
- C3–C9 的 `prd.md`、`design.md`、`implement.md` 已全部补齐；下一位 agent 不应从头重写规划，也不应自行选择或启动任务，必须先让用户明确指定下一项实现任务。
- C3 已运行 `task.py start` 并处于 `in_progress`；C4–C9 仍为 `planning`，不得自动启动。
- 播放系统继续延期。
- 用户数据备份、恢复、备份密码继续不实现。
- 不实现登录、注册、云同步。
- 正式目标平台仍为 Android、Windows、Web；当前开发和人工反馈优先 Android，但每个子任务是否要求 Windows/Web 门禁应以其 PRD 为准。

## 2. Git 与 Trellis 当前事实

- 当前分支：`main`。
- `main` 已与 `origin/main` 对齐。
- 最新工作提交：`f750c30bd61fc6eb7842fdee5286dd60a10a3461`。
- 提交标题：`feat(catalog): add Bangumi catalog-to-detail vertical slice`。
- C1 提交：`4566700 feat: add Flutter foundation shell`。
- C2 已在本地 Trellis 中归档；父任务 `07-30-vue-to-flutter-rewrite` 当前为 `2/9 done`。
- 当前活动功能任务为 C3 `07-31-persistence-cache-web-migration`。
- C3 已完成第一段 Schema v2 基础：新增正式用户/来源/追番/公开账号/设置/迁移账本/图片元数据表定义，`structured_cache_entries` 增加类别、字节数和最后访问时间；真实 v1 内存 SQLite Fixture 验证旧缓存行可前向升级并保留。
- C3 第二个 ≤10 分钟窗口已补齐缓存时间/大小、来源、追番状态/进度、公开账号、迁移账本和图片元数据约束；v1 升级在回填后事务化重建结构化缓存表，使升级库与全新 v2 约束一致。
- 数据库事务故障会完整回滚，`clearPublicCache()` 在同一事务清空结构化缓存和图片元数据但保留用户身份表；定向持久化测试 5 项通过，`flutter analyze --fatal-infos` 零问题。
- C3 第三个 ≤10 分钟窗口已完成结构化缓存元数据与预算：Catalog/Detail 写入记录类别、真实 UTF-8 Payload 字节数和初始访问时间，读取更新 `last_accessed_at`；默认预算独立为 64 MiB，达到 90% 自动事务回收至不超过 75%，排序为过期优先、其后新鲜条目按 LRU，Cache Key 用作稳定最终顺序。
- C3 第四个 ≤10 分钟窗口已完成图片持久缓存的可注入基础边界：新增 `ImageByteStore`，内存降级实现对写入和读取均做防御性复制、支持单条删除和命名空间清空；两个 `DioImagePipeline` 实例可共享同一 Store，Provider 已集中注入 Store，未创建第二 HTTP Client 或第二图片策略。
- 用户已批准把锁定的间接依赖提升为直接依赖；`path_provider 2.1.6` 和 `web 1.1.1` 已写入 `pubspec.yaml`，`drift_dev 2.34.0` 与 `build_runner 2.15.1` 保持锁定且没有升级。
- C3 第五个 ≤10 分钟窗口已实现 `NativeFileImageByteStore`：默认使用 `path_provider.getTemporaryDirectory()`，只在固定 `mio_ani/image_cache_v1` 命名空间写入；使用临时同级文件后 rename 发布；稳定的 128 位十六进制文件键不会明文暴露 URL/Query；单条删除和 `clear()` 都不会触及缓存根目录中的兄弟文件。文件系统不可用时按可重建缓存语义安全降级。
- Native 定向测试第一次发现 Dart VM 有符号 64 位十六进制会产生负号，现已改为分别编码无符号高低 32 位并通过回归测试。当前图片定向测试 6 项通过，`flutter analyze --fatal-infos` 零问题。
- C3 第六个 ≤10 分钟窗口已新增条件平台工厂并接入 `imageByteStoreProvider`：Android/Windows 等 Dart VM 平台运行时选择 `NativeFileImageByteStore`；Web 和不支持的平台明确使用 `MemoryImageByteStore` 降级，条件导入不会把 `dart:io` 泄漏进 Web。缓存目录提供器抛出普通 `Exception` 时，Native 读、写、删除和清理均按缓存未命中/最佳努力处理；安全不变量使用的 `Error` 仍会暴露。
- C3 第七个 ≤10 分钟窗口已实现 `WebCacheStorageImageByteStore` 并接入 Web 条件分支：使用独占且版本化的 `mio_ani-image-bytes-v1` Cache 名称；Cache Request 使用同源合成 URL 和 32 位十六进制组合键，不明文保存来源 Host/Query；读写、单条删除和整个自有命名空间清理失败时均安全降级。Web 不再默认选择内存 Store，但浏览器拒绝 Cache API 时行为仍等价于内存/网络降级。
- Native/Web 现共用一个稳定 32 字符存储键函数。首次复用 Native 64 位算法时 Chrome 编译明确失败，因为大整数不能在 JavaScript 中精确表示；已改为四个独立种子的 32 位 Jenkins 哈希并通过 Web Debug/Wasm 编译与 Native 回归测试。
- C3 第八个 ≤10 分钟窗口已定位 Chrome 测试超时边界：Flutter Shelf 测试页返回 200，Chrome 150 Remote Debugging 正常，目标 `Flutter Test Browser Host` 页面已加载，但 test manager WebSocket 没有产生 suite/test 事件；因此 `--timeout 15s` 从未进入测试体。完全不导入图片、Web 或 Cache API 的既有 `app_failure_test.dart` 在 `--platform chrome` 下同样超时，证明当前故障属于 Flutter 3.44.6/Chrome 150 Web Test Runner 握手/套件加载，而不是 `WebCacheStorageImageByteStore`。
- 外部工具超时会遗留对应的 Flutter/frontend-server/headless-Chrome 子进程树；已通过精确命令行和临时 Profile/端口确认归属后，只终止三次本任务测试树，未终止 IDE 常驻 Dart 或用户 Chrome。第八窗口没有修改生产或测试源码。
- C3 第九个 ≤10 分钟窗口已绕过异常的 Flutter Test Manager，用隔离 Playwright 会话访问真实 `build/web`。真实 Bangumi 图片因没有 CORS Header 被正确拒绝，Cache 命名空间存在但条目为 0；随后只在浏览器会话内用带 `Access-Control-Allow-Origin` 的非空图片响应建立成功路径，真实 Dart 管线向 `mio_ani-image-bytes-v1` 写入 9 条记录。
- 第九窗口发现真实 Bangumi 图片无 CORS 时，当时的 `MioImage` 会进入失败占位；该缺口已在第十窗口按 ADR 边界补齐。
- 9 条记录全部使用 `http://127.0.0.1:18083/__mio_ani_cache__/images/v1/<32位十六进制>`，不含来源 Host、路径或 Query；首条响应字节读取为 `[120]`。移除网络 Mock 后刷新，9 条记录仍存在，刷新后的新增 Console 统计为 0 Error/0 Warning，证明刷新从 Cache Storage 复用字节而未重试真实 CORS 图片。
- Playwright npm/浏览器缓存显式放到 `E:/PSoftware`；独立浏览器会话已关闭，精确 Python Server PID 38092 和端口 18083 已停止，自动生成的 `.playwright-cli` 快照已删除。第九窗口没有修改生产或测试源码。
- C3 第十个 ≤10 分钟窗口已在 `MioImage` 内补齐 Web 专用直显降级：正常路径仍为 Dio → `RequestCoordinator` → Cache Storage → `Image.memory`；仅当平台为 Web、错误是 `OfflineFailure` 且 URI 重新通过 HTTPS Bangumi 图片 Host 白名单时，使用 Flutter 3.44.6 的 `WebHtmlElementStrategy.prefer` 渲染浏览器 HTML 图片元素。HTTP 4xx/5xx、超时、取消、无效 Payload、未知错误、非白名单 Host 和非 Web 平台均不得进入该路径。
- 该降级响应不会写入 MioAni Cache Storage，也不能承诺离线、应用可控淘汰、统一 Header、截图、滤镜或完整清理。真实 Playwright 页面观察到当前视口 6 个 Bangumi `<img>`、6 个 `flt-platform-view`，6 张图片均加载完成且自然尺寸非零；与此同时 `mio_ani-image-bytes-v1` 条目仍为 0。9 个可见/预取 URI 各只发生既有的初次请求加 2 次重试，之后进入直显，没有无界请求循环。
- C3 第十一个 ≤10 分钟窗口已实现图片容量选择契约：Android 固定 256 MiB、Windows 固定 512 MiB；Web 使用 `(quota - usage) ~/ 5`，上限 256 MiB，估算缺失或无效时使用 128 MiB，已明确耗尽的有效配额返回 0。条件平台工厂公开 `loadPlatformImageCacheCapacityBytes()`，Native 只在 `dart:io` 分支判断系统，Web 只在 Web 分支调用 `navigator.storage.estimate()`，公共接口不泄漏浏览器对象。
- 真实 Playwright Origin 返回 `usage=51096`、`quota=3221276568`、可用 `3221225472` 字节，最终应用容量公式结果受上限约束为 `268435456` 字节。该证据只确认浏览器 API 与公式输入可用；由于 Flutter 3.44.6/Chrome 150 Test Manager 仍在套件加载前超时，不能把它描述为 Dart Web 单测通过。
- C3 第十二个 ≤10 分钟窗口完成成功 `200` 响应的第一段字节/元数据协调。`ImageByteStore.write()` 只有在 Native 原子发布或 Web Cache Storage `put` 成功后才返回 `ImageByteWriteResult(storageKey, backend)`；内存 Store 和持久化失败返回 `null`，Pipeline 因而不会为未落盘字节制造孤立 Drift 行。
- `DioImagePipeline` 新增平台无关 `ImageCacheMetadataStore` 注入；成功写入后记录 URL、32 位脱敏存储键、`native_file`/`web_cache` backend、精确字节数、ETag、Last-Modified、获取/访问时间和默认 30 天新鲜边界。`CatalogDatabase` 直接实现该领域接口并使用现有 `ImageCacheEntriesCompanion.insertOnConflictUpdate`；Provider 将同一数据库注入既有唯一图片 Pipeline，Widget/Feature 不接触 Drift Row。
- 本最小 slice 将 `staleAt` 与 `expiresAt` 都设置为获取后 30 天，没有擅自发明更长的过期保留期。
- C3 第十三个 ≤10 分钟窗口已实现新鲜元数据读取和单条不一致修复。Pipeline 在任何缓存访问前先执行 HTTPS/Host 白名单校验；注入 Metadata Store 时先读领域元数据，仅 `now < staleAt` 才视为新鲜，再要求字节非空且 `cached.length == metadata.byteSize`。命中时最佳努力更新 `lastAccessedAt` 并避免 Dio；未注入 Metadata Store 时仍保留既有内存 Store 直接命中语义。
- 元数据存在但字节缺失、为空或长度不一致时，只调用目标 URI 的 `ImageByteStore.delete` 和 `removeImageMetadata`，随后走正常网络路径；其他图片的元数据和字节不受影响。过期元数据不会在本窗口被删除，以便下一窗口读取其 ETag/Last-Modified 和旧字节执行条件重验证。
- `CatalogDatabase` 已实现领域接口的 `readImageMetadata`、`touchImageMetadata`、`removeImageMetadata`，并通过真实内存 Drift 往返验证。图片与持久化定向测试合计 23/23，持久化测试补充往返后单独 9/9，`flutter analyze --fatal-infos` 零问题，`flutter build web --debug` 和 Wasm dry run 成功。尚未完成条件请求/304、新鲜度推进、图片 90%→75% LRU、Android 真机证据和 Vue Web 迁移。
- C4–C9 仍为 `planning`；C3 完成归档后也不得自动开始下一任务。
- `00-bootstrap-guidelines` 仍为 `in_progress`，它拥有 `.trellis/spec/**` 的初始化工作；其他 agent 不应并行覆盖这些规范文件。

### 本次仅本地保存的规划文档

- `.trellis` 和 `docs` 当前都被根 `.gitignore` 忽略。
- C3–C9 的规划文件与本交接文档已在工作区更新，但不会出现在普通 `git status`，也不会被默认业务提交带上。
- 不要用 `git add -f` 擅自提交这些本地规划；若用户以后要求纳入版本控制，先确认是否调整 `.gitignore` 及提交边界。

### 当前工作树必须先确认归属

执行交接时，工作树不是完全干净的：

- `.gitignore` 在 C2 推送后又新增了 `.opencode` 忽略项；这不是本交接阶段的修改。不要擅自恢复、暂存或提交，先确认它属于用户还是另一窗口。
- `.vscode/**` 为未跟踪本地编辑器配置，C2 明确未提交。
- `git-commit-convention.md` 为未跟踪提交规范文件；C2 使用了它的规则，但没有擅自把文件加入提交。
- `web/drift_worker.js.deps` 与 `web/drift_worker.js.map` 是 Worker 编译辅助产物，C2 未提交；真正运行所需的 `web/drift_worker.js` 和 `web/sqlite3.wasm` 已提交。

开始任何工作前必须先运行：

```text
git status --short
git diff -- .gitignore
git log --oneline -5
python ./.trellis/scripts/get_context.py
```

不要使用 `git reset --hard`、`git checkout --`、force push，亦不要覆盖无法确认归属的脏文件。

## 3. 已存在的事实来源（优先阅读，不要复制重写）

- 项目级执行规则：`AGENTS.md`。
- 提交规则：`git-commit-convention.md`。
- 领域词汇：`CONTEXT.md`。
- Trellis 工作流：`.trellis/workflow.md`。
- C2 PRD：`.trellis/tasks/archive/2026-07/07-31-catalog-detail-tracer/prd.md`。
- C2 技术设计：`.trellis/tasks/archive/2026-07/07-31-catalog-detail-tracer/design.md`。
- C2 实施与验证计划：`.trellis/tasks/archive/2026-07/07-31-catalog-detail-tracer/implement.md`。
- C2 最终实现和详细动机：`git show --format=fuller f750c30`。
- C2 会话证据：`.trellis/workspace/takina/journal-1.md`。
- C3 规划：`.trellis/tasks/07-31-persistence-cache-web-migration/{prd,design,implement}.md`。
- C4 规划：`.trellis/tasks/07-31-home-schedule/{prd,design,implement}.md`。
- C5 规划：`.trellis/tasks/07-31-discover-search-filters/{prd,design,implement}.md`。
- C6 规划：`.trellis/tasks/07-31-anime-people-details/{prd,design,implement}.md`。
- C7 规划：`.trellis/tasks/07-31-library-anime-identity/{prd,design,implement}.md`。
- C8 规划：`.trellis/tasks/07-31-public-collection-imports/{prd,design,implement}.md`。
- C9 规划：`.trellis/tasks/07-31-cross-platform-release-hardening/{prd,design,implement}.md`。

以上文件已经记录需求、架构、执行顺序、回滚点和验收标准。新的 agent 应先复核选中任务与当时代码是否仍一致，只修订真实发生变化的部分，不要再创建一套互相漂移的规格。

## 4. 剩余任务规划与执行顺序

默认依赖顺序为：

```text
C3 持久化、缓存与 Web 迁移
 ├─ C4 首页与放送日程
 ├─ C5 发现、搜索与筛选
 ├─ C6 动画、角色与人物详情
 └─ C7 离线追番与作品身份
      └─ C8 公开收藏导入

C3–C8 完成后
 └─ C9 三平台发布加固
```

### C3：持久化、缓存与 Web 迁移

- Drift Schema v2、用户/系统/缓存表边界、v1→v2 前向迁移。
- 结构化缓存和图片缓存独立预算、过期优先 LRU、90%→75% 回收。
- Android/Windows 文件缓存、Web Cache Storage、条件请求/304和安全降级。
- Web 幂等迁移 `mioani-library-v1` / `mioani-profile-v1`，不删除旧键、不迁移播放数据。
- 依赖决定已经用户批准并落地：`path_provider 2.1.6` 与 `web 1.1.1` 已从间接依赖提升为直接依赖；不得顺带升级锁定的生成器或使用 dependency override。

### C4： 首页与放送日程

- 品牌 Hero、本季推荐、趋势/热门、最近更新、七日日程与独立 `/schedule?date=`。
- Bangumi 周模板 + AniList 播出时间展示增强；不把日程匹配写入作品身份。
- 首页/日程独立缓存和局部失败、跨日期刷新、可暂停轮播和有界图片预取。

### C5：发现、搜索与筛选

- Bangumi/AniList 来源差异、关键词、题材、年份、季度、状态、评分、排序、格式、语言/地区和分页。
- 类型安全 URL Query、300 ms 防抖、取消/世代、粘性来源、分页错误保留已有内容和 429 倒计时。
- Web 必测 Query/History/CORS，Windows 检查键盘/焦点/Resize。

### C6：动画、角色与人物详情

- 动画扩展分区、关联作品、角色/声优、制作人员、翻译、人物资料/作品/出演角色和 Bangumi 评论。
- checked DTO、静态 GraphQL、HTML/评论 Parser、非规则翻译 Parser 和分区缓存。
- 详情层级只由 Router Page Stack 管理；不允许恢复 Vue 的第二 Overlay Stack，不实现任何播放入口。

### C7：离线追番与保守作品身份

- 五种追番状态、观看进度、本地修改优先和乐观更新失败回滚。
- 确定证据才自动关联；标题/年份/集数相似只产生候选。
- 手动合并、拆分、忽略、撤销、基线冲突和事务不变量。
- 清公共缓存、清 Flutter 用户数据、删 Vue 旧键三条独立命令；无用户备份恢复能力。

### C8：公开收藏导入

- 官方公开资料解析稳定用户 ID、完整分页暂存、总数核对、变更预览、单事务批次和幂等指纹。
- 换账号确认、空收藏/远端未出现非破坏语义、本地修改优先和安全批次撤销。
- 导入只调用 C7 Planner，不出现“登录/已连接/同步账号”语义。

### C9：三平台发布加固

- 不新增业务；集中完成三平台集成、可访问性、性能/稳定性、体积、安全、依赖/许可证、Web 隔离预览和回滚演练。
- C4–C8 使用精简但真实的切片门禁；C9 恢复最终全量门禁，但每个成功命令无需无意义重复。
- C9 通过只代表“非播放功能可进入正式评审”，不授权生产部署、签名、上架、Vue 下线或旧键删除。

## 5. 已完成范围

### C1：Flutter 基础外壳

- Flutter 项目基础、主题、响应式外壳、四个类型安全分支和单一 GoRouter 栈已经完成。
- 详情页继续通过同一 Router 栈 Push/Pop，不要引入第二导航栈。

### C2：Bangumi 目录到详情纵向切片

- 首页接入无需认证的 Bangumi 公开目录。
- `/anime/bgm-<正整数>` 可加载真实详情，非法 ID 零网络请求。
- 数据流固定为：传输响应 → checked Source DTO → 校验/规范化 → 领域模型 → Repository/缓存 → Riverpod → Widget。
- Dio、checked DTO、RequestCoordinator、Drift 结构化缓存、stale-while-revalidate、MioImage、响应式目录和详情状态均已落地。
- Web Drift 所需的 `sqlite3.wasm` 和 `drift_worker.js` 已提交。
- C2 未进入角色/人物、发现筛选、追番、导入、播放或用户备份。

## 6. 现有实现契约与禁止破坏的边界

### 网络

- `RequestCoordinator` 是唯一请求协调层。
- 相同逻辑请求合并；每来源默认最多 4 并发。
- 绝对 Deadline 默认 20 秒，并发许可排队时间也包含在内。
- 只有显式标记为可重试的幂等 GET 才自动重试。
- 网络错误、408、5xx 最多重试 2 次，退避为 500ms、1500ms。
- 429 支持秒数和 RFC 1123 `Retry-After`；超过 30 秒不自动等待。
- 普通 4xx 不重试。
- 手动刷新创建新世代，旧世代结果会转为 `CancelledFailure`，不能覆盖新结果。
- generation 状态按 Key 统计实际活跃请求，只有全部新旧请求 settle 后才清理；不要改回永久 Map，也不要提前清理造成旧结果复活。
- 请求只允许注册过的 HTTPS Host 和默认 443 端口；自动重定向关闭。
- UI 不得判断或暴露 `DioException`。

### DTO 与领域

- Bangumi DTO 使用 checked `json_serializable`。
- 未知字段允许；缺失、null、类型漂移和非法根 Payload 必须有确定行为。
- 详情响应 ID 必须与 URL 中的 ID 相同。
- 空来源标题保持为空，UI 显示“标题暂缺”；不要伪造 `Bangumi #<id>` 作为业务标题。
- HTTP 图片地址升级为 HTTPS；HTML 简介会清理。

### 缓存与 Repository

- Drift 第一版只保存可重建的结构化缓存，不包含用户数据。
- 新鲜窗口 30 分钟，可降级窗口 7 天。
- 新鲜缓存直接显示；过期缓存先显示再刷新；刷新失败保留内容和具体失败。
- 单条缓存损坏只删除对应 Key，禁止删库。
- 缓存底层/平台异常必须映射为 `AppFailure`，不能从 Repository Stream 泄漏 Drift 或平台异常。
- 手动刷新必须绕过新鲜缓存并贯通到新的 RequestCoordinator generation。
- `drift_dev` 必须固定为 `2.34.0`。`2.34.1+` 需要 `analyzer ^13.0.0`，与当前 Flutter/Riverpod/build_runner 组合冲突。
- 不要升级 `build_runner` 到 `2.15.2+`，不要使用 dependency override，也不要为解决它而降级 Riverpod。

### UI、图片与路由

- `MioImage` 是 Widget 唯一远程图片入口；不要在卡片或详情里直接持有 Dio、重试或缓存逻辑。
- 目录支持紧凑/中等/宽屏和 200% 文本缩放。
- 详情过期刷新失败必须显示具体失败和“重试更新”。
- Android 系统返回、Windows `Alt+Left`/`Escape`、Web 浏览器历史都委托同一 Router 栈。
- `MioBackShortcuts` 不得恢复 `Focus(autofocus: true)`；Web 首帧 View Focus 会在布局前遍历 RenderBox 并触发 `RenderBox was not laid out`。当前实现使用自持有 `FocusNode`、`skipTraversal: true` 和 post-frame `requestFocus()`。

## 7. Windows 开发环境

每个新的 PowerShell 会话在第一次可见输出前运行：

```powershell
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
$env:PYTHONIOENCODING = 'utf-8'
```

Pub 缓存必须优先放 E 盘：

```powershell
$env:PUB_CACHE = 'E:/PSoftware/Pub/Cache'
```

Android/Gradle：

```powershell
$env:GRADLE_USER_HOME = 'E:/PSoftware/Gradle'
$env:JAVA_HOME = 'C:/Program Files/Java/jdk-22'
$env:Path = "$env:JAVA_HOME/bin;$env:Path"
$env:GRADLE_OPTS = '-Dorg.gradle.workers.max=2 -Dorg.gradle.parallel=false'
```

已知环境问题：

- 用户全局 Gradle 配置曾指向失效代理 `127.0.0.1:7897`。不要修改全局 Gradle 配置；使用 `E:/PSoftware/Gradle` 隔离。
- `E:/PSoftware/DevEco Studio/jbr` 虽为 JDK 21，但缺少 `jlink.exe`，不能用于 Android Gradle Transform。
- `C:/Program Files/Java/jdk-22` 是现有完整 JDK，包含 `jlink.exe`。
- Android SDK 位于 `E:/PSoftware/Android/Sdk`，Platform 35 已安装。
- 规范 ADB：`E:/PSoftware/Android/Sdk/platform-tools/adb.exe`。
- 不要让 Flutter、Pub、Gradle 或 Android SDK 大量回写 C 盘；用户此前非常关注 C 盘空间减少。

## 8. 最近一次验证证据

- C3 第十六窗口：公开 Pipeline 测试先证明连接重试耗尽后即使存在完整过期字节也会抛出 `OfflineFailure`；实现后，仅这一具体失败类型可返回已通过非空和精确长度校验的过期字节，不重写字节、不续期元数据，因此仍会优先参与后续淘汰/重验证。反向断言确认 `503` 仍抛出 `UpstreamFailure`；超时、取消、HTTP 拒绝、无效负载、浏览器策略和未知失败也不会被该具体 catch 隐藏。图片与持久化定向测试 27/27、静态分析零问题、Web Debug、Wasm dry run 和 `git diff --check` 通过。本窗口按用户要求创建并推送 C3 进度检查点，但不把任务误标为完成。
- C3 第十五窗口：数据库预算测试先因缺少图片预算领域操作失败，Pipeline 协调测试再因缺少容量加载 seam 失败。实现后，图片元数据不足 90% 不处理，达到水位时按“过期优先、最久未访问、URL 稳定排序”回收到不高于 75%；成功 200 写入和 304 续期都会使用会话内平台预算并删除对应 Byte Store 对象，零容量 Web 预算会清空可控图片缓存，维护异常不影响图片显示。图片与持久化定向测试 26/26、静态分析零问题、Web Debug、Wasm dry run 和 `git diff --check` 通过。
- C3 第十四窗口：304 测试先证明旧实现将响应映射为 `BrowserPolicyFailure`；实现后，过期且完整的持久字节会发送 `If-None-Match`/`If-Modified-Since`，304 复用旧字节、不调用 Byte Store 写入，并将元数据新鲜度推进 30 天。图片与持久化定向测试 24/24、静态分析零问题、Web Debug、Wasm dry run 和 `git diff --check` 通过。本窗口没有实现网络失败时使用过期字节；下一步可独立决策该语义，或实现图片元数据驱动的 90%→75% 淘汰。
- C3 第十三窗口：新鲜命中测试先因未更新访问时间失败；字节长度不一致测试再因返回截断内容失败。实现元数据优先读取、精确字节数校验和单条修复后，图片与持久化定向测试 23/23、Drift read/touch/remove 往返 9/9、静态分析零问题、Web Debug 和 Wasm dry run 通过。
- C3 第十二窗口：Pipeline 元数据写入与 Drift 领域 Store 两个 seam 分别先 Red 后 Green；图片与持久化定向测试合计 21/21、静态分析零问题、Web Debug 和 Wasm dry run 通过。没有修改 Schema，因此没有无依据重跑生成器。
- C3 第十一窗口：容量策略与平台工厂分别经历 Red→Green；图片定向测试 11/11、静态分析零问题、Web Debug 和 Wasm dry run 通过。真实浏览器 `StorageManager.estimate()` 返回约 3 GiB 可用配额，按 20% 及 256 MiB 上限得到 256 MiB 预算；会话、服务器、端口和快照均已清理。
- C3 第十窗口：降级资格判定 TDD 首先因函数不存在按预期失败；实现后图片定向测试 9/9、静态分析零问题、Web Debug 和 Wasm dry run 通过。真实 `build/web` 中 6 个 Bangumi HTML 图片元素均 `complete=true` 且自然尺寸非零，MioAni Cache Storage 仍为 0 条；会话、服务器、端口和快照均已清理。
- C3 第九窗口：真实 `build/web` Playwright Harness 验证 CORS 拒绝不写入、带 CORS 的 9 条成功写入、同源 32 位脱敏键、响应字节 `[120]`、移除 Mock 后刷新仍保留 9 条及新增 Console 0 Error/0 Warning；会话、服务器、端口和快照均已清理。本窗口无源码变更。
- C3 第八窗口：图片 Web 测试与无关的 `app_failure_test.dart` 均在 Chrome 平台产生任何测试事件前超时；Shelf Host、Chrome Remote Debugging 和 Browser Host 页面均正常，故障收敛到 Flutter 3.44.6/Chrome 150 Test Manager 握手。所有本任务遗留测试进程树均已按精确 PID/命令行清理；本窗口没有业务代码变更，也没有伪造 Chrome 通过结果。
- C3 第七窗口：Chrome 首次编译发现共享键的 64 位整数不兼容 JavaScript；改为四段 32 位算法后，Native 图片测试 8/8、静态分析、Web Debug 构建和 Wasm dry run通过。Chrome Cache Storage 契约重试在产生测试事件前超时，当前是明确未通过门禁，而不是功能通过证据。
- C3 第六窗口：平台工厂 TDD 首先因工厂文件缺失失败；实现后 `flutter test test/unit/image/image_pipeline_test.dart` 8/8 通过；`flutter analyze --fatal-infos` 零问题；`flutter build web --debug` 成功且 Wasm dry run 通过，证明条件导入未把 Native API 带入 Web。
- C3 第五窗口：图片定向测试先按 TDD 因缺少 Native 实现失败；实现后第一次运行发现有符号十六进制文件名问题，修复后 `flutter test test/unit/image/image_pipeline_test.dart` 6/6 通过；`flutter analyze --fatal-infos` 零问题。
- C3 第四窗口：`dart format` 检查 3 个图片相关文件且零改动；`flutter test test/unit/image/image_pipeline_test.dart` 4/4 通过；`flutter analyze --fatal-infos` 零问题。
- 上述 C3 证据仅覆盖当前图片字节存储契约与既有工程静态分析，不代表 Native/Web 持久图片缓存、Vue 迁移或 C3 全量门禁已经完成。
- 最终提交精确代码连续三次执行全量 `flutter test`，每次 70 项全部通过。
- 覆盖率：`878/987 = 88.96%`，门槛为 80%。
- `dart format --output=none --set-exit-if-changed`：68 个文件、零变更。
- `flutter analyze --fatal-infos`：零问题。
- Android 真机：M2104K10AC，Android 13 / API 33。
- Android 集成测试通过。
- Android Profile 真实 Bangumi API 成功加载 60 条目录，进入真实详情并通过系统返回恢复目录。
- MioAni 进程日志中 `FATAL EXCEPTION`、ANR、`E/flutter`、`Unhandled Exception`、`RenderBox was not laid out` 均为 0。
- Windows Release 构建通过。
- Web Release 构建和 Wasm dry-run 通过。
- Web 真实 Release 浏览器验证：Bangumi CORS 成功、`/anime/bgm-2` 直达成功、浏览器返回恢复 `/`、SQLite Wasm/Worker 正常、新增 Console Error 为 0。

常用门禁：

```text
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test integration_test tool
flutter analyze --fatal-infos
flutter test
flutter test --coverage
dart run tool/check_coverage.dart
flutter test integration_test/catalog_detail_tracer_test.dart -d <device-id>
flutter build apk --profile
flutter build windows --release
flutter build web --release
```

非阻断提示：Android/Web Release 构建会提示未找到 `packages/cupertino_icons/CupertinoIcons` 字体；当前项目没有实际 Cupertino 图标消费者，静态分析、测试、Material 图标和 Release 均正常。不要仅为消除提示无依据新增依赖；若以后出现真实缺图，再从具体消费者定位。

## 9. 已知工具与平台噪声

- MIUI `uiautomator dump` 会输出 `/data/system/theme_config/theme_compatibility.xml` 不存在的堆栈，但 XML 仍会成功生成和 pull；它不是 MioAni 崩溃。
- 设备上可能同时运行其他 Flutter 应用，读取 Logcat 时必须按 MioAni 包名或 PID 过滤。
- 如果 MIUI 报 `INSTALL_FAILED_USER_RESTRICTED`，需要用户在设备上允许 USB 安装；不要把它误判为 Gradle 或 APK 问题。
- Web 本地验证完成后检查并关闭自己启动的测试端口，不要批量终止所有 Dart/Java/ADB 进程。

## 10. 下一位 Agent 的建议启动流程

1. 使用 `ps-utf8-io` 初始化每个 PowerShell 会话。
2. 运行 `trellis-start` 或至少读取 `.trellis/workflow.md`、`AGENTS.md` 和 `get_context.py` 输出。
3. 检查脏工作树，先确认 `.gitignore` 的 `.opencode` 改动及其他未跟踪文件归属。
4. 让用户明确选择一个剩余子任务；不要根据编号自行启动。
5. 读取该任务已完成的 `prd.md/design.md/implement.md`，只检查它与最新代码是否漂移；如无新产品决策，不重新进行整套访谈。
6. 若任务依赖和权限均满足，向用户展示实施边界并获得启动确认；随后再策展当时有效的 `implement.jsonl/check.jsonl` 和运行 `task.py start`。
7. 开发前使用 `trellis-before-dev`，按规划中的 Red→Green→Refactor 实现。
8. C3–C8 使用精简门禁：生成、格式、静态分析、定向测试、一次全量测试、Android 主流程和受影响平台验证；不做连续三轮无差别全量测试或多轮重复审查。C9 按最终发布加固计划执行完整门禁。
9. 每个任务完成后必须更新本交接文档，Commit 遵循 `git-commit-convention.md` 并用详细正文记录跨层契约与验证证据。
10. 只有用户明确要求时才提交、推送、归档或启动下一个子任务；归档前确认远端状态，归档后停止等待用户选择。

## 11. Suggested skills

- `ps-utf8-io`：Windows 中文、Flutter、Gradle、Git 输出前必用。
- `trellis-start`：新会话初始化和任务状态识别。
- `trellis-continue`：恢复已获批准且正在进行的任务。
- `trellis-brainstorm`：只有已完成规划出现真实需求变化或未决产品选择时再使用，不从头重复访谈。
- `trellis-before-dev`：改代码前加载项目规范。
- `implement`：依据已批准规格实施。
- `tdd`：新增行为或修复缺陷时先写失败测试。
- `diagnosing-bugs`：处理真机、网络、Flutter 或构建异常。
- `trellis-check`：提交前按子任务 `implement.md` 执行精简或最终全量门禁。
- `code-review`：高风险或用户明确要求时做 Standards/Spec 双轴复核，不再默认多轮重复审查。
- `trellis-update-spec`：沉淀新的可执行契约；但要避免与 `00-bootstrap-guidelines` 并行覆盖。
- `browser:control-in-app-browser`：需要真实 Web CORS、路径直达或 Console 验证时使用。
- `trellis-finish-work`：任务提交后归档并记录会话。

## 12. 安全与隐私

- C2 没有 Access Token、OAuth Secret、API Secret 或用户凭据。
- 不要把设备序列号、用户路径、代理配置或日志正文写入公开文档/提交，除非它们是经过脱敏且确有必要的构建信息。
- 不记录完整请求 Query、响应正文、用户输入或未来用户数据。
