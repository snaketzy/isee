import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../models/video_quality.dart';
import 'video_player_strategy.dart';

void _breadcrumb(String msg, {Map<String, dynamic>? data}) {
  Sentry.addBreadcrumb(Breadcrumb(
    message: msg,
    category: 'video_player',
    data: data?.map((k, v) => MapEntry(k, v.toString())),
    level: SentryLevel.info,
  ));
  debugPrint('[VP] $msg${data != null ? ' $data' : ''}');
}

void _captureInfo(String msg, {Map<String, dynamic>? extras}) {
  Sentry.captureMessage(
    msg,
    level: SentryLevel.info,
    withScope: (scope) {
      extras?.forEach((k, v) => scope.setExtra(k, v.toString()));
    },
  );
}

class MobileVideoPlayerStrategy implements VideoPlayerStrategy {
  late final Player _player;
  late final VideoController _videoController;
  late final Widget _videoView;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<double>? _volumeSub;
  StreamSubscription<Playlist>? _playlistSub;
  StreamSubscription<VideoParams>? _videoParamsSub;
  StreamSubscription<Tracks>? _tracksSub;
  StreamSubscription<Duration>? _bufferSub;
  StreamSubscription<bool>? _bufferingSub;

  final StreamController<Duration> _positionCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playingCtrl =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _durationCtrl =
      StreamController<Duration>.broadcast();
  final StreamController<double> _volumeCtrl =
      StreamController<double>.broadcast();

  bool _initialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 100.0;
  bool _muted = false;
  double _playbackSpeed = 1.0;
  VideoQuality _quality = VideoQuality.q1080p;
  Map<VideoQuality, String>? _qualityMap;
  String? _currentUrl;

  MobileVideoPlayerStrategy() {
    _breadcrumb('player.create.start', data: {'vo': 'mediacodec_embed', 'hwdec': 'auto-safe'});
    _player = Player(
      configuration: const PlayerConfiguration(
        logLevel: MPVLogLevel.debug,
      ),
    );
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        vo: 'mediacodec_embed',
        hwdec: 'auto-safe',
        enableHardwareAcceleration: true,
      ),
    );
    _breadcrumb('player.create.done');
    // 监听 Surface 创建
    _videoController.rect.addListener(() {
      final r = _videoController.rect.value;
      _breadcrumb('controller.rect', data: {
        'left': r?.left.toString() ?? 'null',
        'top': r?.top.toString() ?? 'null',
        'width': r?.width.toString() ?? 'null',
        'height': r?.height.toString() ?? 'null',
      });
    });
    _videoController.id.addListener(() {
      _breadcrumb('controller.id', data: {'textureId': _videoController.id.value?.toString() ?? 'null'});
      if (_videoController.id.value != null) {
        _captureInfo('video.texture.ready', extras: {
          'textureId': _videoController.id.value.toString(),
        });
      }
    });
    _videoController.waitUntilFirstFrameRendered.then((_) {
      _breadcrumb('controller.firstFrameRendered');
      _captureInfo('video.first_frame_rendered');
    }).catchError((e) {
      _breadcrumb('controller.firstFrameRendered.error', data: {'error': e.toString()});
    });
    _videoView = Video(
      controller: _videoController,
      controls: NoVideoControls,
      fit: BoxFit.contain,
      fill: Colors.black,
      alignment: Alignment.center,
    );

    _playingSub = _player.stream.playing.listen((e) {
      _breadcrumb('stream.playing', data: {'playing': e.toString()});
      _isPlaying = e;
      _playingCtrl.add(e);
    });
    _positionSub = _player.stream.position.listen((e) {
      _position = e;
      _positionCtrl.add(e);
    });
    _durationSub = _player.stream.duration.listen((e) {
      _breadcrumb('stream.duration', data: {'duration': e.toString()});
      _duration = e;
      _durationCtrl.add(e);
      _initialized = true;
      if (e > Duration.zero) {
        _captureInfo('video.duration.received', extras: {'duration': e.toString()});
      }
    });
    _volumeSub = _player.stream.volume.listen((e) {
      if (!_muted) {
        _volume = e;
        _volumeCtrl.add(e);
      }
    });
    _playlistSub = _player.stream.playlist.listen((e) {
      _breadcrumb('stream.playlist', data: {
        'index': e.index.toString(),
        'count': e.medias.length.toString(),
      });
      _initialized = e.index >= 0 && e.medias.isNotEmpty;
    });
    _videoParamsSub = _player.stream.videoParams.listen((e) {
      _breadcrumb('stream.videoParams', data: {
        'dw': e.dw?.toString() ?? 'null',
        'dh': e.dh?.toString() ?? 'null',
        'rotate': e.rotate.toString(),
      });
      _captureInfo('video.params.received', extras: {
        'width': e.dw?.toString() ?? 'null',
        'height': e.dh?.toString() ?? 'null',
        'rotate': e.rotate.toString(),
      });
    });
    _tracksSub = _player.stream.tracks.listen((e) {
      _breadcrumb('stream.tracks', data: {
        'videoCount': e.video.length.toString(),
        'audioCount': e.audio.length.toString(),
      });
    });
    _bufferSub = _player.stream.buffer.listen((e) {
      _breadcrumb('stream.buffer', data: {'buffer': e.toString()});
    });
    _bufferingSub = _player.stream.buffering.listen((e) {
      _breadcrumb('stream.buffering', data: {'buffering': e.toString()});
    });
    // mpv 错误流
    _player.stream.error.listen((msg) {
      _breadcrumb('stream.error', data: {'error': msg});
      Sentry.captureMessage(
        'mpv.error: $msg',
        level: SentryLevel.error,
      );
    });
    // mpv 日志流
    _player.stream.log.listen((msg) {
      final level = msg.level.toLowerCase();
      if (level.contains('warn') || level.contains('error') || level.contains('fatal')) {
        _breadcrumb('mpv.log', data: {
          'level': msg.level,
          'prefix': msg.prefix,
          'text': msg.text,
        });
        if (level.contains('error') || level.contains('fatal')) {
          Sentry.captureMessage(
            'mpv.log.${msg.level}: [${msg.prefix}] ${msg.text}',
            level: SentryLevel.warning,
          );
        }
      }
    });
  }

  @override
  Widget get videoView => _videoView;

  @override
  bool get isInitialized => _initialized;
  @override
  bool get isPlaying => _isPlaying;
  @override
  Duration get position => _position;
  @override
  Duration get duration => _duration;
  @override
  double get volume => _muted ? 0.0 : _volume / 100.0;
  @override
  double get playbackSpeed => _playbackSpeed;
  @override
  VideoQuality get currentQuality => _quality;
  @override
  Map<VideoQuality, String>? get qualityMap => _qualityMap;
  @override
  String? get currentUrl => _currentUrl;

  @override
  Stream<Duration> get positionStream => _positionCtrl.stream;
  @override
  Stream<bool> get playingStream => _playingCtrl.stream;
  @override
  Stream<Duration> get durationStream => _durationCtrl.stream;
  @override
  Stream<double> get volumeStream => _volumeCtrl.stream;

  bool _isHlsUrl(String? url) =>
      url != null && url.toLowerCase().endsWith('.m3u8');

  String _pickUrlForQuality(VideoQuality q) {
    final m = _qualityMap;
    if (m != null && m.containsKey(q) && m[q] != null && m[q]!.isNotEmpty) {
      return m[q]!;
    }
    if (_currentUrl != null) return _currentUrl!;
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  }

  Duration _clamp(Duration d, Duration min, Duration max) {
    if (d < min) return min;
    if (d > max) return max;
    return d;
  }

  @override
  Future<void> initialize(
    String url, {
    Map<VideoQuality, String>? qualityMap,
    VideoQuality initialQuality = VideoQuality.q1080p,
    Duration? resumeFrom,
    bool autoPlay = true,
    double? playbackSpeed,
  }) async {
    _qualityMap = qualityMap;
    _quality = initialQuality;
    final picked = _pickUrlForQuality(initialQuality);
    _currentUrl = picked;
    _initialized = false;
    _breadcrumb('initialize.start', data: {
      'url': picked,
      'isHls': _isHlsUrl(picked).toString(),
      'qualityMapKeys': qualityMap?.keys.map((k) => k.name).toList().toString() ?? 'null',
    });
    _captureInfo('video.initialize.start', extras: {'url': picked, 'isHls': _isHlsUrl(picked).toString()});
    try {
      // 覆盖 media_kit 硬编码的 opengl-es=yes，避免模拟器 EGL_BAD_ATTRIBUTE
      try {
        // ignore: avoid_dynamic_calls
        await (_player.platform as dynamic).setProperty('opengl-es', 'no');
        _breadcrumb('setProperty.opengl-es.no');
      } catch (e) {
        _breadcrumb('setProperty.opengl-es.error', data: {'error': e.toString()});
      }
      await _player.open(
        Media(picked, httpHeaders: const {}),
        play: autoPlay,
      );
      _breadcrumb('initialize.open.done', data: {
        'playing': _isPlaying.toString(),
        'duration': _duration.toString(),
        'position': _position.toString(),
      });
      _captureInfo('video.open.done', extras: {
        'playing': _isPlaying.toString(),
        'duration': _duration.toString(),
      });
      // 检测是否加载成功
      if (_duration == Duration.zero) {
        // 等待一下看是否能收到 duration
        await Future.delayed(const Duration(seconds: 3));
        _captureInfo('video.open.duration_check', extras: {
          'duration_after_3s': _duration.toString(),
          'playing': _isPlaying.toString(),
        });
      }
      final speed = playbackSpeed ?? _playbackSpeed;
      if ((speed - 1.0).abs() > 0.001) {
        try {
          await _player.setRate(speed);
          _playbackSpeed = speed;
        } catch (_) {}
      }
      if (resumeFrom != null && resumeFrom > Duration.zero) {
        await Future.delayed(const Duration(milliseconds: 250));
        final target = _clamp(
          resumeFrom,
          Duration.zero,
          _duration > Duration.zero ? _duration : resumeFrom,
        );
        try {
          await _player.seek(target);
          _position = target;
        } catch (_) {}
      }
    } catch (e, stack) {
      _breadcrumb('initialize.error', data: {'error': e.toString()});
      Sentry.captureException(e, stackTrace: stack);
    }
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> togglePlay() => _player.playOrPause();

  @override
  Future<void> seekTo(Duration position) async {
    _position = _clamp(position, Duration.zero, _duration);
    await _player.seek(_position);
  }

  @override
  Future<void> seekRelative(Duration delta) async {
    final target = _clamp(_position + delta, Duration.zero, _duration);
    _position = target;
    await _player.seek(target);
  }

  @override
  Future<void> setVolume(double v) async {
    final normalized = v.clamp(0.0, 1.0);
    final mpvVol = normalized * 100.0;
    _volume = mpvVol;
    _muted = mpvVol <= 0.01;
    await _player.setVolume(mpvVol);
    _volumeCtrl.add(normalized);
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) {
      await _player.setVolume(0.0);
      _volumeCtrl.add(0.0);
    } else {
      if (_volume <= 0.01) _volume = 80.0;
      await _player.setVolume(_volume);
      _volumeCtrl.add(_volume / 100.0);
    }
  }

  @override
  Future<void> toggleMute() => setMuted(!_muted);

  @override
  Future<void> setPlaybackSpeed(double s) async {
    _playbackSpeed = s;
    await _player.setRate(s);
  }

  @override
  Future<void> switchQuality(VideoQuality q) async {
    final oldUrl = _currentUrl;
    final resumePos = _position;
    final newUrl = _pickUrlForQuality(q);
    final sameUrl = oldUrl != null &&
        newUrl == oldUrl &&
        _isHlsUrl(oldUrl) &&
        _isHlsUrl(newUrl);
    _quality = q;
    if (sameUrl) {
      return;
    }
    _currentUrl = newUrl;
    await initialize(
      newUrl,
      qualityMap: _qualityMap,
      initialQuality: q,
      resumeFrom: resumePos,
      autoPlay: _isPlaying,
      playbackSpeed: _playbackSpeed,
    );
  }

  @override
  Future<void> dispose() async {
    await _playingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _volumeSub?.cancel();
    await _playlistSub?.cancel();
    await _videoParamsSub?.cancel();
    await _tracksSub?.cancel();
    await _bufferSub?.cancel();
    await _bufferingSub?.cancel();
    await _positionCtrl.close();
    await _playingCtrl.close();
    await _durationCtrl.close();
    await _volumeCtrl.close();
    _breadcrumb('player.dispose');
    await _player.dispose();
  }
}
