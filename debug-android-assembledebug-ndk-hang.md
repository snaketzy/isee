# Debug Session: android-assembledebug-ndk-hang
Status: [OPEN]
Created: 2026-10-10
Symptom: 已完成 NDK 28.2.13676358 安装，但 Running Gradle task 'assembleDebug' 仍然长时间无输出卡住
Env: macOS + Flutter (android/ 已生成, gradle-wrapper 9.3.1 + AGP 9.1.0 + Kotlin 2.4.0 + JDK 17.0.20.1 Temurin)
Flags: INCLUDE_ADMIN=false

## Falsifiable Hypotheses
H1. Gradle Daemon 上次失败后处于坏状态 / Kotlin daemon 僵尸进程，锁死工作目录
H2. Maven Central repo TLS 1.2/1.3 握手重试，在 download kotlin-scripting-jvm 等 jar 时长时间超时重试但无输出（上次已出现过 Remote host terminated the handshake）
H3. NDK 已安装完成但未正确写 local.properties / .installer 元数据，AGP 仍在反复调用 sdkmanager 检测
H4. media_kit / 其他插件的 download 任务（如 prebuilt mpv/android .aar 下载）长时间挂起国内出口
H5. gradle.properties 里 org.gradle.java.home 与 flutter jdk-dir 不一致导致新 fork 的 worker JVM 版本错误、卡在启动循环

## Evidence Plan
1. 先 ps 查 Gradle / Kotlin daemon 是否存在 + 端口占用，kill 所有再启
2. 用 flutter build apk -v（verbose）重跑，抓取 Gradle 阶段细分日志
3. 若仍卡住，在卡住的时间点读 `android/.gradle/daemon/*/daemon-*.out.log` 与 `~/Library/Android/sdk/.repositories.cfg`
4. 对照 local.properties 里是否有 ndk.dir 行 + flutter.ndkVersion 是否与实际解压目录匹配

## Fixes Applied
- [ ] Kill existing daemons + run with --no-daemon + --stacktrace --info
- [ ] Add mirrors.tencent (maven) + aliyun (google) repo mirror in settings.gradle.kts pluginManagement/buildscript block
- [ ] Force explicit NDK path in local.properties (and android { ndkVersion } explicit to avoid probe)
- [ ] As last resort: run assembleDebug via `./gradlew :app:assembleDebug` inside android/ with JAVA_HOME set, bypassing Flutter's Gradle re-launcher
