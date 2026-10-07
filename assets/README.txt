iSEE 平台资源说明

本目录用于存放平台静态资源：

images/ 目录：
  - 可放 logo、默认海报占位图等
  - Mock 数据当前使用 picsum.photos 动态生成图片，无需本地图片

icons/ 目录：
  - 应用图标，建议尺寸：
    - Icon-192.png  (192x192, PWA 桌面图标)
    - Icon-512.png  (512x512, PWA 应用商店图标)
    - Icon-maskable-192.png (192x192, 安全区 80%)
    - Icon-maskable-512.png (512x512, 安全区 80%)
    - favicon.png  (64x64, 浏览器标签图标)

当前所有资源均使用公共占位 CDN，替换为真实资源时：
  1. 把文件放进对应目录
  2. 把 mock_data.dart 中的 URL 改为 AssetImage('assets/xxx.png')
