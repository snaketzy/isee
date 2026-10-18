import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../video_player/video_player_strategy.dart';

class MobileFullscreenManager implements FullscreenManager {
  bool _isFullscreen = false;

  @override
  bool get isFullscreen => _isFullscreen;

  @override
  Future<void> enterFullscreen(BuildContext context) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _isFullscreen = true;
  }

  @override
  Future<void> exitFullscreen(BuildContext context) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _isFullscreen = false;
  }

  @override
  Future<void> toggleFullscreen(BuildContext context) async {
    if (_isFullscreen) {
      await exitFullscreen(context);
    } else {
      await enterFullscreen(context);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}
