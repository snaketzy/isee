import 'package:flutter/material.dart';
import '../../models/video_quality.dart';

abstract class VideoPlayerStrategy {
  Widget get videoView;

  bool get isInitialized;
  bool get isPlaying;
  Duration get position;
  Duration get duration;
  double get volume;
  double get playbackSpeed;
  VideoQuality get currentQuality;
  Map<VideoQuality, String>? get qualityMap;
  String? get currentUrl;

  Stream<Duration> get positionStream;
  Stream<bool> get playingStream;
  Stream<Duration> get durationStream;
  Stream<double> get volumeStream;

  Future<void> initialize(
    String url, {
    Map<VideoQuality, String>? qualityMap,
    VideoQuality initialQuality = VideoQuality.q1080p,
    Duration? resumeFrom,
    bool autoPlay = true,
    double? playbackSpeed,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> togglePlay();
  Future<void> seekTo(Duration position);
  Future<void> seekRelative(Duration delta);
  Future<void> setVolume(double v);
  Future<void> setMuted(bool muted);
  Future<void> toggleMute();
  Future<void> setPlaybackSpeed(double s);
  Future<void> switchQuality(VideoQuality q);
  Future<void> dispose();
}

abstract class FullscreenManager {
  bool get isFullscreen;
  Future<void> enterFullscreen(BuildContext context);
  Future<void> exitFullscreen(BuildContext context);
  Future<void> toggleFullscreen(BuildContext context);
  void dispose();
}
