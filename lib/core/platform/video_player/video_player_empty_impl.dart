import 'package:flutter/material.dart';
import '../../models/video_quality.dart';
import 'video_player_strategy.dart';

class VideoPlayerEmptyImpl implements VideoPlayerStrategy {
  @override
  Widget get videoView => const SizedBox.shrink();

  @override
  bool get isInitialized => false;
  @override
  bool get isPlaying => false;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => Duration.zero;
  @override
  double get volume => 1.0;
  @override
  double get playbackSpeed => 1.0;
  @override
  VideoQuality get currentQuality => VideoQuality.q1080p;
  @override
  Map<VideoQuality, String>? get qualityMap => null;
  @override
  String? get currentUrl => null;

  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<Duration> get durationStream => const Stream.empty();
  @override
  Stream<double> get volumeStream => const Stream.empty();

  @override
  Future<void> initialize(String url,
      {Map<VideoQuality, String>? qualityMap,
      VideoQuality initialQuality = VideoQuality.q1080p,
      Duration? resumeFrom,
      bool autoPlay = true,
      double? playbackSpeed}) async {}

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> togglePlay() async {}
  @override
  Future<void> seekTo(Duration position) async {}
  @override
  Future<void> seekRelative(Duration delta) async {}
  @override
  Future<void> setVolume(double v) async {}
  @override
  Future<void> setMuted(bool muted) async {}
  @override
  Future<void> toggleMute() async {}
  @override
  Future<void> setPlaybackSpeed(double s) async {}
  @override
  Future<void> switchQuality(VideoQuality q) async {}
  @override
  Future<void> dispose() async {}
}
