# Debug Session: hls-quality-lock

## 症状
- 实际：v002《暗影猎手》（Mux 多码率 HLS）在 Web 端切换分辨率后，视频画质无变化。
- 期望：切换 360p/480p/720p/1080p 后，实际播放的 HLS 变体分辨率随之改变。

## 复现步骤
1. `flutter run -d web-server --web-port 8080`
2. 浏览器打开 http://localhost:8080
3. 进入 v002《暗影猎手》播放页（`/player/v002`，默认 official 引擎）
4. 点击画质按钮，依次选择 360p / 720p / 1080p
5. 观察画面清晰度与 UI 画质标签

## 环境
- OS: macOS 14.6 (darwin-arm64)
- 浏览器: 用户本机默认浏览器（待证据确认 UA）
- 播放链路: 官方 `video_player` + `video_player_web_hls`（内部 hls.js），
  外层由 `web/index.html` 注入的自定义 hls.js 控制层（`__i_hls_*`）负责层级锁定
- 关键文件:
  - `web/index.html`（hls.js patch / attach / lockLevel）
  - `lib/core/platform/video_player/video_player_web_impl.dart`（WebVideoPlayerStrategy）
  - `lib/features/video_player/presentation/pages/video_player_official_page.dart`

## 证据位置
- DEBUG_EVIDENCE_DIR: `/tmp/trae-debug-isee/hls-quality-lock`
- 日志文件: `/tmp/trae-debug-isee/hls-quality-lock/trae-debug-log-hls-quality-lock.ndjson`
- env 文件: `/tmp/trae-debug-isee/hls-quality-lock/hls-quality-lock.env`
- Debug Server: `http://127.0.0.1:7777`（GET /logs、GET /health、DELETE /logs）

## 假设（可证伪）
| Id | 假设 | 观察点 | 结论 |
|----|------|--------|------|
| A | hls.js ctor patch 未生效（CDN/时序），`__i_hls_weak` 从未捕获真实 Hls 实例 → 层级锁定无效 | `Hls.__iPatched__`、`HAS_REAL`、`ATTACH_RESULT` | 部分 REJECTED（解析时 patch 确实生效，见证据 1） |
| F | media_kit Web 自带 hls.js（运行时异步加载并**覆盖 `window.Hls`**），覆盖后的构造器未被 patch → WeakMap 从未捕获真正播放用的实例 → `__i_hls_lockLevel` 永久失效 | `media-probe` 中 `hasHls/patched` 随时间变化；`HAS_REAL` 为 false | INCONCLUSIVE |
| B | patch 生效但 `OrigHls.apply` 对 ES6 class 抛错 → 播放器 `new Hls()` 抛错回退 `video.src` → 播放失败 | `media-probe` 的 `err/readyState`、`VIDEO_ERROR` | INCONCLUSIVE |
| C | `findLatestVideo()` 取不到正确的 `<video>`（mk 页视频在 platform view 内） | `media-probe.videos`、`FIND_LATEST` | INCONCLUSIVE |
| D | 锁定执行成功但 hls.js 未真正切层 | `LOCK_LEVEL` 的 heights/bestIdx、`LEVEL_SWITCHED` | INCONCLUSIVE |
| E | 底层已切层，但 Dart 侧 `_qualityFromHeight` 静默覆盖且不 setState，UI 看起来"没变" | LEVEL_SWITCHED 高度 vs UI 标签 | INCONCLUSIVE |

## 关键事实（静态分析已确认）
- Web 上「首页 hero 播放」→ `/player-mk/:id` → `VideoPlayerPage`（media_kit），**不是** official 页。
- media_kit 1.2.6 自带 Web 播放：`media_kit/lib/src/player/web/player/real.dart`，
  HLS 由其自身加载的 `assets/packages/media_kit/assets/web/hls1.4.10.js` 提供（**运行时异步加载**）。
- `Player.setVideoTrack` 在 Web 上**不支持**（real.dart:1236-1247）→ `[VP] 无可解析分辨率的视频轨道` 的直接来源。
- `Player.setProperty`（hls-bitrate）在 Web 上不生效 → mk 页 `_load` 里的 720p 码率上限在 Web 无效。
- `web/index.html` 的 `patchHlsCtor()` 在解析时对 **CDN 的 Hls** 生效；但 media_kit 的 hls.js 之后会把
  `window.Hls` 替换为**未 patch**的构造器 → 现有 `__i_hls_*` 机制对 mk 页失效（待 F 的运行时证据确认）。

## 进度
- progress_status: in_progress
- runId: pre（修复前证据）
- 证据 1（2026-10-11）：`PATCH_DONE {patched:true, ua: Chrome/154, hasMSE:true}` × 3 次（用户 3 次刷新）；
  但**未出现**任何 `FIND_LATEST / HAS_REAL / ATTACH_RESULT / LOCK_LEVEL` → 说明用户走的是 mk 页，
  official 页的 HLS 锁定链路未被触发。
