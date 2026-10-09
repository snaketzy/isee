# iSEE 后台维护系统 (Netflix 风格) 实现方案

## 一、关于「能否做成跟 Netflix 一样」

### 结论：视觉与交互高度还原 Netflix 后台是可行的，但 Netflix 内部后台并未开源，我们参考的是**行业通用的流媒体运营后台范式** + Netflix 前台的**视觉设计语言**。

Netflix 对外公开的内部后台代号有「COPS」（Content Operations）等，但未开源。我们将基于以下目标进行还原：

| 维度 | Netflix 风格还原度目标 |
|------|----------------------|
| 视觉风格（暗黑主题、红色强调色、圆角卡片） | ✅ 100% 沿用前台 [app_theme.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/theme/app_theme.dart) 体系 |
| 侧边栏 + 顶栏 + 内容区三段式布局 | ✅ 参考 Netflix 内部后台经典 3-pane 布局 |
| 仪表盘数据卡片、趋势折线图 | ✅ 参考 Netflix Content Analytics 面板风格 |
| 视频内容管理（拖拽上传、剧集嵌套编辑） | ✅ 参考 Netflix COPS 表单交互范式 |
| 实时 Mux 转码进度、R2 上传队列可视化 | ✅ 结合现有 [mux_upload.py](file:///Users/jerry/Working/芮智联睿/Repositories/isee/mux_upload.py) / [mux_r2_nightly_pull.py](file:///Users/jerry/Working/芮智联睿/Repositories/isee/mux_r2_nightly_pull.py) 脚本扩展 |
| 多用户角色与权限体系（管理员/编辑/运营） | ✅ 基础 RBAC 实现（Mock 数据先行） |
| Netflix 级别的超大规模数据处理引擎 | ❌ 当前阶段 Mock + 轻量后台，后续接入真实后端再扩展 |

---

## 二、仓库研究结论

### 当前架构概览
- **技术栈**：Flutter 3.x Web + Riverpod 2.x + GoRouter + video_player（hls.js 互操作）
- **主题体系**：已在 [AppTheme](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/theme/app_theme.dart#L4-L175) 中定义 Netflix 级暗黑主题（primaryRed #E50914）
- **路由**：[app_router.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/router/app_router.dart#L14-L90) 使用 ShellRoute，前台路由嵌套在 MainShell 中
- **核心实体**：
  - [VideoContent](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/content/domain/entities/video_content.dart#L43-L97)：视频/剧集/综艺/纪录片
  - [Season](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/content/domain/entities/video_content.dart#L29-L41) / [Episode](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/content/domain/entities/video_content.dart#L5-L27)：季与集
  - [UserProfile](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/user/domain/entities/user_profile.dart#L80-L108) / [MembershipPlan](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/user/domain/entities/user_profile.dart#L29-L53)：用户与订阅
- **Mock 数据源**：[mock_data.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/data/mock_data.dart#L1-L631) 存储 16 条预置视频 + 3 档会员计划
- **运营脚本**：Python 脚本实现 R2 → Mux 的视频入库流水线

### 关键约束（沿用项目惯例）
1. **Mock 先行**：先以本地 Provider + Mock 数据跑通后台全链路，后续接入真实 API
2. **Flutter Web 同一代码库**：不新建独立 Admin 仓库，在同一 `lib/features/` 下新增 `admin/` 模块
3. **渲染器策略**：继续遵循 Chromium = html / Safari/Firefox = canvaskit 的分层策略
4. **路由独立 Shell**：后台使用独立的 `AdminShell`（侧边栏布局），不与前台 `MainShell`（底部导航栏）混用

---

## 三、功能模块总览

```
后台维护系统 (Admin)
├── 1. 仪表盘 Dashboard          — 数据概览卡片 + 趋势图 + 快捷入口
├── 2. 内容管理 Content
│   ├── 2.1 视频库列表            — 表格 / 网格切换，搜索筛选，批量操作
│   ├── 2.2 新建/编辑视频          — 多步骤表单（基本信息/封面/季集/播放源）
│   └── 2.3 分类管理             — 首页推荐分类、Top10、热门榜单维护
├── 3. 媒体资产管理 Media Assets
│   ├── 3.1 上传队列             — 本地 → R2 → Mux 三步进度可视化
│   ├── 3.2 Mux 资产监控          — 转码进度、可用分辨率、播放 URL
│   └── 3.3 R2 存储浏览           — 云存储目录、文件大小、CDN 访问链接
├── 4. 用户与订阅 Users
│   ├── 4.1 用户列表             — 搜索 / 会员等级筛选 / 状态切换
│   ├── 4.2 用户详情             — 观影记录、订阅历史、手动加时长
│   └── 4.3 会员套餐管理          — 价格调整、权益修改
├── 5. 数据分析 Analytics         — 播放量、完播率、热门内容、留存率（Mock）
├── 6. 系统设置 Settings
│   ├── 6.1 管理员账户与权限      — 角色 RBAC
│   └── 6.2 全局配置             — Mux/R2 凭据、站点名称、公告
└── 7. 登录页 Admin Login         — 独立入口 /admin/login
```

---

## 四、文件与模块变更清单

### 新增文件（`lib/features/admin/` 模块）
```
lib/features/admin/
├── domain/
│   └── entities/
│       ├── admin_user.dart              — 管理员账户（角色、权限、最后登录）
│       ├── dashboard_stats.dart         — 仪表盘统计实体
│       ├── media_upload_task.dart       — 上传任务实体（R2+Mux 三步状态）
│       └── system_config.dart           — 全局配置项
├── data/
│   ├── providers/
│   │   ├── admin_auth_provider.dart     — 管理员登录态 Provider
│   │   ├── dashboard_provider.dart      — 仪表盘 Mock 数据
│   │   ├── admin_content_provider.dart  — 视频管理 CRUD Provider
│   │   ├── upload_queue_provider.dart   — 上传队列状态（对接 Python 脚本）
│   │   ├── admin_users_provider.dart    — C 端用户管理
│   │   ├── membership_admin_provider.dart — 会员套餐管理
│   │   └── analytics_provider.dart      — 分析数据 Mock
│   └── repositories/
│       └── admin_mock_repository.dart   — 所有后台 Mock 数据源
├── presentation/
│   ├── pages/
│   │   ├── admin_login_page.dart        — 登录页
│   │   ├── dashboard_page.dart          — 仪表盘
│   │   ├── content_list_page.dart       — 视频列表
│   │   ├── content_edit_page.dart       — 视频新建/编辑（多步表单）
│   │   ├── category_manage_page.dart    — 分类与榜单管理
│   │   ├── upload_queue_page.dart       — 上传队列
│   │   ├── mux_assets_page.dart         — Mux 资产监控
│   │   ├── r2_storage_page.dart         — R2 存储浏览
│   │   ├── users_list_page.dart         — C 端用户列表
│   │   ├── user_detail_page.dart        — 用户详情
│   │   ├── membership_plans_page.dart   — 会员套餐管理
│   │   ├── analytics_page.dart          — 数据分析
│   │   ├── admin_staff_page.dart        — 管理员账户管理
│   │   └── system_settings_page.dart    — 系统设置
│   └── widgets/
│       ├── admin_shell.dart             — 后台三段式布局壳
│       ├── admin_sidebar.dart           — 左侧导航栏（折叠/展开）
│       ├── admin_app_bar.dart           — 顶栏（搜索/管理员头像/退出）
│       ├── stat_card.dart               — 通用数据卡片
│       ├── data_table.dart              — 可排序/筛选/分页的通用表格
│       ├── upload_progress_tile.dart    — 上传进度瓦片
│       ├── mock_line_chart.dart         — 简易趋势折线图（纯 CustomPaint，无需新依赖）
│       └── multistep_form.dart          — 多步骤视频编辑表单向导
```

### 修改文件

| 文件 | 变更内容 |
|------|---------|
| [app_router.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/router/app_router.dart#L14-L90) | 新增独立 ShellRoute：`/admin/*` 所有后台路由嵌套 `AdminShell`；`/admin/login` 独立路由；路由守卫：未登录重定向登录页 |
| [mock_data.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/data/mock_data.dart#L1-L631) | 扩展 `VideoContent` 增加 `status`（草稿/已发布/已下线）、`viewCount`、`playCount` 字段；新增管理员账户、上传任务、仪表盘统计等 Mock |
| [video_content.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/content/domain/entities/video_content.dart#L43-L97) | 实体扩展：新增 `status`、`viewCount`、`playCount`、`createdBy`、`updatedAt` 等后台必需字段 |
| [user_profile.dart](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/features/user/domain/entities/user_profile.dart#L80-L108) | 扩展 `registeredAt`、`lastLoginAt`、`status`（正常/冻结）、`totalWatchMinutes` 字段 |

---

## 五、依赖顺序实现步骤

### Phase 1：基础骨架（路由 + 主题 + 登录 + Shell）
1. **扩展实体类**：为 `VideoContent` / `UserProfile` 增加后台必需字段（向后兼容，保留默认值）
2. **新增后台入口路由**：在 GoRouter 中新增 `/admin/login` 与嵌套 ShellRoute `/admin/*`；路由守卫读取 `adminAuthProvider`
3. **实现 `AdminShell` 三段式布局**：左侧 256px 可折叠导航栏 + 顶栏 + 内容滚动区；完全沿用前台暗黑主题色
4. **实现 `AdminLoginPage`**：邮箱/密码表单（默认 `admin@isee.video` / `admin123` Mock 登录）；登录成功写入 `shared_preferences`
5. **注册 `admin_auth_provider.dart`**：Riverpod AsyncNotifier，管理 token / 当前管理员 / 退出登录

### Phase 2：仪表盘与通用组件
6. **构建通用组件库**：`StatCard`（带趋势箭头）、`AdminDataTable`（排序+分页+复选框批量）、`MockLineChart`（纯 CustomPaint 折线图）、`UploadProgressTile`
7. **实现 `DashboardPage`**：4 张核心卡片（总内容数、总用户数、今日播放量、本月收入）+ 3 个趋势图（7日新增用户、30日播放量、各套餐占比饼图示意）+ 最近上传任务列表 + 快捷入口按钮
8. **实现 `dashboard_provider.dart` + Mock 数据**：`AdminMockRepository` 生成随机但可信的统计数据

### Phase 3：内容管理（核心）
9. **实现 `ContentListPage`**：数据表格 + 网格视图切换；搜索框（标题/类型/年份）；筛选芯片（类型、状态、分级）；顶部批量操作（发布/下线/删除）；每行「编辑/预览/复制 ID」按钮
10. **实现 `ContentEditPage`（4 步向导）**：
    - Step1 基本信息：标题、原名、类型、年份、评分、分级、标签（多 Chips）、简介、导演演员（可添加条目）
    - Step2 封面图：海报 poster（400x600）、背景 backdrop（1600x900）、缩略图 thumb（400x225）上传预览（使用 Mock 图片占位）
    - Step3 季集管理（仅 series/tvShow）：可动态增删季，每季下可动态增删集；每集填写标题、简介、时长、缩略图、Mux Playback ID
    - Step4 播放源与发布：trailer url / main m3u8 url / 多画质 URL Map；状态（草稿/已发布/已下线）；是否 Trending / New / Top10 与排名；预览后提交
11. **实现 `CategoryManagePage`**：左侧已有分类列表，拖拽排序；右侧编辑分类名、分类包含视频（多选 + 搜索框）；首页 Top10 排名手动调整
12. **`admin_content_provider.dart`**：CRUD 全部操作 `state = List.unmodifiable([...state, newItem])` 更新；操作后 SnackBar 提示成功

### Phase 4：媒体资产 & 上传队列（对接现有脚本）
13. **定义 `MediaUploadTask` 实体**：状态机 `local → uploading_to_r2 → r2_done → pulling_to_mux → transcoding → ready / failed`；每个阶段百分比、速度、错误信息
14. **实现 `UploadQueuePage`**：顶部「手动上传」按钮（选择文件 Mock 选择后入队）；列表每行显示任务名、当前阶段、进度条、速度、开始时间、操作（暂停/重试/取消/查看日志）
15. **实现 `MuxAssetsPage`**：表格列 Asset ID / 对应视频标题 / 转码状态 / 最高分辨率 / 创建时间 / 播放 URL（可复制）；支持按状态筛选、搜索 Asset ID
16. **实现 `R2StoragePage`**：模拟 R2 bucket 目录树；文件列表含 Key / Size / LastModified / 公网 URL（复制按钮）；当前存储用量统计卡片
17. **`upload_queue_provider.dart`**：Timer 模拟推进各任务进度（后续可替换为真实 WebSocket / REST 轮询 Python 脚本状态）

### Phase 5：用户、订阅与分析
18. **实现 `UsersListPage`**：头像、邮箱、会员等级 Chip、到期日、剩余天数、注册日期、状态（正常/冻结）；搜索与筛选；批量操作（发邮件通知 Mock）
19. **实现 `UserDetailPage`**：用户信息卡 + 订阅时间线 + 最近观影列表 + 观影时长分布折线 + 手动操作区（续费、升级套餐、临时加 7 天、冻结/解冻）
20. **实现 `MembershipPlansPage`**：三档套餐卡片编辑（价格/权益/最高画质/设备数）；保存后同步前台 `MockData.membershipPlans`
21. **实现 `AnalyticsPage`**：Tab 切换（内容表现 / 用户增长 / 收入 / 观看行为）；每 Tab 2-3 个图表 + Top 表格（如 Top 10 热播）

### Phase 6：系统设置
22. **实现 `AdminStaffPage`**：管理员列表（超级管理员 / 内容编辑 / 运营 analyst 三角色）；增删改、重置密码、最后登录时间
23. **实现 `SystemSettingsPage`**：站点信息（名称、Logo URL、公告）、Mux 配置（Token ID/Secret 脱敏显示）、R2 配置（Account ID / Bucket / Public URL）、播放设置（默认画质、是否开启 4K 转码全局开关）
24. **权限控制**：在 `AdminSidebar` 和各页面内根据 `currentAdmin.role` 动态隐藏菜单项和操作按钮

### Phase 7：质量 & 联调
25. **路由守卫完善**：未登录访问任意 `/admin/*` 跳转 `/admin/login` 并保留 redirect 参数
26. **前台 Mock 数据同步**：后台编辑的 `VideoContent` 通过同一份 `AdminMockRepository` 状态同步到前台 `content_providers.dart` 读取，立即生效
27. **静态构建验证**：`flutter build web --release` 后 Python 静态服务器启动，访问 `/admin/login` 全流程冒烟测试

---

## 六、依赖与注意事项

### 新增依赖（**零**，不引入新 package，保持纯净）
| 功能 | 实现方案 | 原因 |
|------|---------|------|
| 趋势折线图 / 饼图 | `CustomPainter` 手写 `MockLineChart` / `MockPieChart` | 避免引入 `fl_chart` 等重型图表库；后台一期 Mock 数据足够 |
| 拖拽排序（分类、季集） | `ReorderableListView`（Flutter SDK 内置） | Material 内置，无需额外依赖 |
| 文件选择（上传入口） | `FilePicker`？→ **一期使用占位按钮 + 模拟选择** | Flutter Web 文件选择可用 `dart:html` 原生 API，但一期只做 UI 入队，不实际上传 |
| 表格分页 / 排序 | 自实现 `AdminDataTable` 封装 `PaginatedDataTable` | SDK 内置完全够用 |
| 多步表单 | `Stepper` Widget（SDK 内置） | Netflix 风格视觉稍作调整即可 |

### 关键架构决策
1. **单一代码库双 Shell**：前台 `/home` 等走 `MainShell`（底部导航），后台 `/admin/*` 走 `AdminShell`（侧边栏），通过 GoRouter 两个独立 ShellRoute 完全隔离
2. **Mock 数据状态共享**：新增 `AdminMockRepository` 作为单一真相源，前台 `content_providers.dart` 与后台 `admin_content_provider.dart` 均监听同一 Repository，保证后台改数据前台立即刷新
3. **响应式布局**：AdminShell 采用 `LayoutBuilder`，屏幕宽度 < 1024px 时侧边栏自动折叠为图标模式；< 640px 抽屉模式
4. **视觉一致性**：所有按钮、输入框、卡片严格复用 [AppTheme](file:///Users/jerry/Working/芮智联睿/Repositories/isee/lib/core/theme/app_theme.dart#L13-L173) 中已定义的 `elevatedButtonTheme`、`cardTheme`、`inputDecorationTheme`（若缺失则补充，不单独写颜色）
5. **登录 token 持久化**：使用项目已有的 `shared_preferences: ^2.3.3` 存储 `admin_token` + `admin_id`，APP 启动时 `adminAuthProvider` 读取恢复登录态

---

## 七、验证清单

| 阶段 | 验证项 | 方法 |
|------|-------|------|
| Phase 1 | 访问 `/admin/login` 输入正确凭据 → 进入仪表盘；直接访问 `/admin/dashboard` → 自动跳登录后重定向回来 | 手动浏览器 |
| Phase 1 | 侧边栏 8 个菜单项点击路由正确切换；折叠/展开动画流畅；屏幕缩小到 iPad/手机宽度布局自适应 | 手动浏览器 DevTools 设备模拟 |
| Phase 2 | 仪表盘 4 张卡片数据非空且随刷新变化；折线图 X 轴 7 日标签正确；快捷入口跳转正确 | 手动 + 热重载 |
| Phase 3 | 视频列表搜索「星际」能过滤出 v001；切换表格/网格；批量选择 3 条点击批量下线 → 列表状态 Chip 变灰 | 手动 |
| Phase 3 | 新建视频 → 4 步走完 → 提交 → 前台 `/home` 新片与热门区域立即出现新内容 | 前后台两个浏览器标签页联调 |
| Phase 3 | Top10 排名在后台从 1 拖到 5 → 前台首页 Top10 卡片顺序立即更新 | 同上 |
| Phase 4 | 上传队列点「模拟新增 3 个任务」→ 进度条每 500ms 前进；完成后 Mux 资产页可见新条目；失败任务点击重试恢复进度 | 手动 |
| Phase 5 | 用户列表筛选「高级版」只显示 Premium 会员；用户详情点击「临时 +7 天」→ 剩余天数 +7 并 SnackBar 提示 | 手动 |
| Phase 5 | 套餐管理将标准版月费从 49 改 59 → 前台 `/subscription` 页面价格立即更新 | 前后台联调 |
| Phase 6 | 内容编辑角色登录后看不到「管理员账户」和「系统设置」菜单；超级管理员全部可见 | 切换账号 Mock 登录 |
| Phase 7 | `flutter build web --release` 成功无报错；Python 静态服务器启动后前台 + 后台所有路由可访问、无白屏 | 命令行 + 浏览器 |

---

## 八、风险与应对

| 风险 | 影响 | 处理方案 |
|------|------|---------|
| Flutter Web 后台在大屏（>2K）数据表格性能抖动 | 内容列表数百条时滚动卡顿 | `AdminDataTable` 采用 `PaginatedDataTable` 每页 25 条 + 懒加载；Mock 数据限制 200 条内 |
| 前台用户直接输入 `/admin/dashboard` 误入后台 | 非管理员混淆体验 | 路由守卫严格校验；后台和前台主题色一致但布局完全不同，视觉上强区分；登录页 iSee logo 旁标注「管理后台」 |
| 自绘图表在 Safari 下 Canvas 像素对齐异常 | 饼图/折线图模糊 | 遵循项目已有 canvaskit 分层策略，Safari 下后台自动用 canvaskit |
| AdminMockRepository 状态热重载丢失 | 调试时数据改完丢失 | 关键 Mock 初始数据在 `MockData` 中硬编码一份默认值；Provider 启动时初始化；可选：接入 Hive 本地持久化（本期不做，留作后续） |
| 侧边栏折叠后图标语义不清晰 | 新管理员找不到菜单 | Hover 时 Tooltip 显示完整中文名；首次进入弹出 3 步新手引导（本期可简化为仅 Tooltip） |
| 后台编辑视频后前台 `video_player` 播放 URL 无效 | 新视频无法播放 | 默认新编辑视频的播放 URL 回填 `MockData.muxTest4Hls`，保证可立即播放验证 |

---

## 九、关于「做得跟 Netflix 一样」的补充说明

Netflix 真正的后台系统（COPS、Neuron、Loom 等几十个内部系统）包含：
- **机器学习推荐调参台**（Feature Store 可视化、AB 实验分流）
- **专业级视频 QC 质检工具**（逐帧分析、HDR 色域检查、音画同步校验）
- **全球 CDN 流量调度面板**（200+ 国家 PoP 节点热力图）
- **多语言字幕与配音流水线**（AI 翻译 + 人工校对 Timeline）
- **财务结算与分账系统**（与内容方按播放量分成）

**本方案一期不包含以上 Netflix 级重型能力**，我们交付的是「**运营人员每天使用的 CMS + 数据看板**」这部分，视觉与交互高度 Netflix 化，足以支撑 iSEE 冷启动期的内容运营需求。上述重型模块留待真实后端 + 数据团队到位后迭代。
