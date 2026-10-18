# Debug Session: isee-app-crash-on-launch
Status: [OPEN]
Created: 2026-10-10
Symptom: iSEE APK 安装后点击 Launcher 图标进入即闪退（白屏/黑屏 -> 回到桌面）
Env: macOS + Flutter (android/ 生成完成, NDK 28.2.13676358 已装, emulator Pixel_6_Pro_API_36 / Nexus_5X_API_26_x86 之一)
Flags: INCLUDE_ADMIN=false (通常)

## Falsifiable Hypotheses
H1. lib/main.dart 顶层的 `MediaKit.ensureInitialized()` 在当前 ABI 架构下没找到对应 `.so`（arm64-v8a vs x86_64 缺失 media_kit 预编译库） → native SIGSEGV / UnsatisfiedLinkError -> 立刻闪退
H2. FlutterEngine 需要的 `libflutter.so` + Dart AOT `libapp.so` 被 Gradle strip 阶段错误 strip 或者 architecture 过滤错了（Flutter 默认 debug 只打 arm64 部分 ABI，但 emulator x86 会直接找不到）
H3. AndroidManifest / MainActivity 声明不一致 → `ActivityNotFoundException` / ClassNotFoundException：例如 Flutter 默认生成的是 `.MainActivity`，但 manifest 里 metadata 的 flutter app initialization 指向 kotlin 类路径错
H4. `SystemChrome.setEnabledSystemUIMode` 在 onCreate/initState 之前调用在某些 API 级别导致异常（MainShell 或 VideoPlayer 全屏 Manager 在冷启瞬间被某个 Stream 立即 fire 导致 NPE）
H5. `package_info_plus` / `connectivity_plus` 等基础插件在 debug 包缺 manifest 权限或老版本 AGP 兼容问题，Platform channel 在 Flutter first frame 之前抛 MissingPluginException，被未捕获 Dart 异常处理直接 kill 进程

## Evidence Plan
① 在闪退发生后立刻 `adb logcat` 取 5000 行 buffer，过滤：AndroidRuntime:E AndroidRuntime:FATAL flutter:F libc:fatal DEBUG:* art:crash
② 打开 APK 查 lib/*.so 覆盖了哪些 ABI → `unzip -l app-debug.apk | grep "\.so"` 验证是否含当前模拟器 ABI（x86_64 vs arm64-v8a）
③ `adb shell getprop ro.product.cpu.abilist` 拿模拟器 ABI 列表，与 APK 里 ABI 取交集
④ 如未找到，单独建一个最小纯 Flutter demo 跑起来，排除 iSEE lib/ 里具体代码触发（决定是 dart 侧还是 android shell 侧）

## Evidence Collected
- [ ] logcat tail 5000 行（闪退前后 20 秒）
- [ ] APK lib so 清单
- [ ] ro.product.cpu.abilist
- [ ] flutter analyze（先跑）

## Fixes Applied
- [ ] TBD
