---
name: mux-r2-video-pipeline
description: Publish videos to Mux through Cloudflare R2. Use when asked to batch upload local videos to R2, run or schedule the R2-to-Mux pull pipeline, or transcode videos into Mux HLS. Do not use for direct local upload to Mux.
---

# Mux R2 视频发布流水线

把「本地视频 → R2 → Mux → HLS」串成一个可复用流程。脚本与配置都在项目根目录，本 skill 只说明如何正确调用、验证与排错。

## 组成

| 步骤 | 工具 | 位置 |
|---|---|---|
| 1 本地批量传 R2 | rclone + `rclone.conf` 的 `[r2]` profile | 项目根 `rclone.conf` |
| 2 Mux 去 R2 拉取 | `mux_r2_nightly_pull.py` | 项目根 |
| 3 Mux 批量转码 | 同脚本内置轮询（`status` 到 `ready`） | — |
| 定时触发 | launchd，每天 23:00 | `com.isee.mux-r2-nightly-pull.plist` |
| 备用交互上传 | `mux_upload.py`（Pull / Direct 双模式） | 项目根 |

## 前置条件

- `cloudflare.env`：`CLOUDFLARE_R2_PUBLIC_DOMAIN` / `CLOUDFLARE_R2_BUCKET` / 访问凭证
- `rclone.conf`：`[r2]` profile，需 `provider=Other` + `no_check_bucket=true`
- rclone 二进制：`~/.local/bin/rclone`
- Mux token：已内置于 `mux_r2_nightly_pull.py` 与 `mux_upload.py`

## 步骤 1 本地批量传 R2

```bash
export PATH="$HOME/.local/bin:$PATH"
cd <项目根>
rclone --config rclone.conf copy ./video/ r2:isee-videos/ \
  --ignore-existing \
  --transfers 7 --checkers 8 \
  --s3-upload-concurrency 32 --s3-chunk-size 8M \
  --stats 10s --stats-one-line -v
```

验证桶内容：

```bash
rclone --config rclone.conf lsjson r2:isee-videos/
```

## 步骤 2 + 3 Mux 拉取并转码

```bash
python3 -u mux_r2_nightly_pull.py            # 只抓 R2 里 Mux 尚未存在的文件
python3 -u mux_r2_nightly_pull.py --dry-run  # 只列出待抓列表，不提交
python3 -u mux_r2_nightly_pull.py --force    # 忽略去重，全部重抓
```

脚本行为：
- 列 R2 桶对象 → 列 Mux 已有 `passthrough`（同时索引 `文件名` 与 `stem` 两种形态）→ 差集即新文件
- 对每个新文件 `POST /assets`：`input=[{url}]`、`encoding_tier=premium`、`resolution_tier=2160p`、`passthrough=<完整文件名>`
- 轮询 `GET /assets/{id}` 直到 `status=ready`，取 `playback_ids[0]`
- 结果追加写 `logs/mux_r2_pull_results.jsonl`，并打印 `'videoUrl': 'https://stream.mux.com/<pid>.m3u8'`

## 定时（每天 23:00）

```bash
cp -f com.isee.mux-r2-nightly-pull.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.isee.mux-r2-nightly-pull.plist 2>/dev/null
launchctl load   ~/Library/LaunchAgents/com.isee.mux-r2-nightly-pull.plist
launchctl start  com.isee.mux-r2-nightly-pull   # 立刻验证一次，不必等到 23:00
```

launchd 环境必须能找到 rclone：plist 的 `PATH` 要含 `~/.local/bin`，`WorkingDirectory` 指向项目根。

## 关键坑

- **4K 只出 1080p**：Mux 默认 `encoding_tier=baseline` 封顶 1080p。要出 2160p / 1440p 必须 `encoding_tier=premium` + `resolution_tier=2160p`。同时源码率要足够（约 ≥16 Mbps），否则 Mux 不会生成高码率档。
- **r2.dev HEAD 403**：S3 兼容的 HEAD 签名严格会返回 403，但 GET（含 Range）正常返回 200/206；Mux Pull 用 GET，不受影响。
- **看不到刚上传的文件**：multipart 上传在 `CompleteMultipartUpload` 返回前，`lsjson` 看不到该对象。看到"缺失"不代表失败，等几分钟再查，并用对象 `Size` 与本地字节数对齐（相差 <1KB 视为一致）。
- **进度显示假死**：不要用 `--progress | tee`（tty 进度条与管道缓冲冲突）。让 rclone 直接输出到终端，或另开终端用 `lsjson` 查状态。
- **凭证安全**：`cloudflare.env` / `rclone.conf` / `logs/` 已在 `.gitignore`，勿提交。

## 产物消费

把 `logs/mux_r2_pull_results.jsonl` 中的 `hls_url` 填入 `lib/core/data/mock_data.dart` 的 `mainVideoUrls`。各画质档位指向同一个 `.m3u8`，由 Mux 内部做自适应码率切换。
