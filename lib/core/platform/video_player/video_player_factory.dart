import 'package:flutter/foundation.dart';
import '../platform.dart';
import 'video_player_strategy.dart';

abstract class VideoPlayerStrategyFactory {
  static VideoPlayerStrategy create() {
    if (kIsWeb) {
      // 在 Web 平台，WebVideoPlayerStrategy 是真实实现（通过 platform.dart 条件 export 保证）
      // ignore: unnecessary_type_check
      final s = WebVideoPlayerStrategy();
      return s;
    }
    // Mobile / Desktop：MobileVideoPlayerStrategy 真实实现
    // ignore: unnecessary_type_check
    final s = MobileVideoPlayerStrategy();
    return s;
  }
}
