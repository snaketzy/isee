import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as vp;
import '../../models/video_quality.dart';
import 'video_player_strategy.dart';

@JS('__i_hls_findLatestVideo')
external JSObject? iHlsFindLatestVideo();
@JS('__i_hls_attach')
external JSString iHlsAttach(JSObject videoEl, JSString srcUrl);
@JS('__i_hls_hasReal')
external JSBoolean iHlsHasRealInstance(JSObject? videoEl);
@JS('__i_hls_destroy')
external void iHlsDestroyByKey(JSString key);
@JS('__i_hls_destroyAll')
external void iHlsDestroyAll();
@JS('__i_hls_lockLevel')
external JSBoolean iHlsLockLevel(JSObject videoEl, JSNumber targetHeight);
@JS('__i_hls_unlockAuto')
external JSBoolean iHlsUnlockAuto(JSObject videoEl);
@JS('__i_hls_currentHeight')
external JSNumber iHlsCurrentHeight(JSObject videoEl);
@JS('__i_hls_registerQualitySwitchCb')
external void iHlsRegisterQualitySwitchCb(JSObject videoEl, JSFunction cb);

class WebVideoPlayerStrategy implements VideoPlayerStrategy {
  vp.VideoPlayerController? _controller;
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
  double _volume = 1.0;
  bool _muted = false;
  double _playbackSpeed = 1.0;
  VideoQuality _quality = VideoQuality.q1080p;
  Map<VideoQuality, String>? _qualityMap;
  String? _currentUrl;
  final Set<String> _ownedHlsKeys = {};
  Timer? _tickTimer;

  @override
  Widget get videoView => _initialized && _controller != null
      ? vp.VideoPlayer(_controller!)
      : Container(color: Colors.black);

  @override
  bool get isInitialized => _initialized;
  @override
  bool get isPlaying => _isPlaying;
  @override
  Duration get position => _position;
  @override
  Duration get duration => _duration;
  @override
  double get volume => _muted ? 0.0 : _volume;
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

  int _qualityHeight(VideoQuality q) {
    switch (q) {
      case VideoQuality.q360p:
        return 360;
      case VideoQuality.q480p:
        return 480;
      case VideoQuality.q720p:
        return 720;
      case VideoQuality.q1080p:
        return 1080;
      case VideoQuality.q4k:
        return 2160;
    }
  }

  VideoQuality _qualityFromHeight(int h) {
    if (h >= 1080) return VideoQuality.q1080p;
    if (h >= 720) return VideoQuality.q720p;
    if (h >= 480) return VideoQuality.q480p;
    return VideoQuality.q360p;
  }

  JSObject? _pickLatestVideoElementJs() => iHlsFindLatestVideo();
  bool _hasRealHlsInstance(JSObject? jsVideoEl) =>
      jsVideoEl != null && iHlsHasRealInstance(jsVideoEl).toDart;
  html.VideoElement? _pickLatestVideoElement() {
    final jsVid = _pickLatestVideoElementJs();
    if (jsVid == null) return null;
    final all = html.querySelectorAll('video');
    return all.isEmpty ? null : all.last as html.VideoElement;
  }

  String _attachHlsToJs(JSObject jsVideoEl, String srcUrl) {
    final s = iHlsAttach(jsVideoEl, srcUrl.toJS);
    return s.toDart;
  }

  bool _lockHlsLevel(JSObject jsVideoEl, VideoQuality target) {
    final h = _qualityHeight(target).toDouble();
    final ok = iHlsLockLevel(jsVideoEl, h.toJS);
    return ok.toDart;
  }

  bool _unlockHlsAuto(JSObject jsVideoEl) {
    return iHlsUnlockAuto(jsVideoEl).toDart;
  }

  int? _currentHlsHeight(JSObject jsVideoEl) {
    final n = iHlsCurrentHeight(jsVideoEl);
    final v = n.toDartDouble;
    if (!v.isFinite || v < 100) return null;
    return v.toInt();
  }

  JSFunction _qualitySwitchCb(void Function(int) onHeight) {
    void cb(JSNumber h) {
      final v = h.toDartInt;
      if (v >= 180 && v <= 16384) onHeight(v);
    }
    return cb.toJS as JSFunction;
  }

  void _destroyOwnedHls() {
    for (final k in List<String>.unmodifiable(_ownedHlsKeys)) {
      try {
        iHlsDestroyByKey(k.toJS);
      } catch (_) {}
    }
    _ownedHlsKeys.clear();
  }

  Future<void> _postInitializeHlsIfNeeded(String url) async {
    if (!_isHlsUrl(url)) return;
    for (int i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final jsEl = _pickLatestVideoElementJs();
      if (jsEl == null) continue;
      final existing = _attachHlsToJs(jsEl, '');
      if (existing.isNotEmpty) {
        if (!_ownedHlsKeys.contains(existing)) {
          _ownedHlsKeys.add(existing);
          try {
            iHlsRegisterQualitySwitchCb(jsEl, _qualitySwitchCb((h) {
              final q = _qualityFromHeight(h);
              if (q != _quality) _quality = q;
            }));
          } catch (_) {}
        }
        return;
      }
      final htmlEl = _pickLatestVideoElement();
      bool matches = false;
      if (htmlEl != null) {
        final s = htmlEl.src;
        final cs = htmlEl.currentSrc;
        final hasSrc = s.isNotEmpty || cs.isNotEmpty;
        final vw = htmlEl.videoWidth;
        final vh = htmlEl.videoHeight;
        final hasDim = vw > 0 && vh > 0;
        if (hasSrc && hasDim) matches = true;
        if (s == url ||
            s.startsWith(url) ||
            s.contains('stream.mux.com/') ||
            s.contains('.m3u8')) matches = true;
        if (cs == url ||
            cs.startsWith(url) ||
            cs.contains('stream.mux.com/') ||
            cs.contains('.m3u8')) matches = true;
        if (s.startsWith('blob:') || cs.startsWith('blob:')) {
          if (hasDim) matches = true;
        }
      }
      if (!matches) continue;
      final k = _attachHlsToJs(jsEl, url);
      if (k.isNotEmpty) {
        _ownedHlsKeys.add(k);
        try {
          iHlsRegisterQualitySwitchCb(jsEl, _qualitySwitchCb((h) {
            final q = _qualityFromHeight(h);
            if (q != _quality) _quality = q;
          }));
        } catch (_) {}
      }
      return;
    }
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_controller != null) {
        final v = _controller!.value;
        if (v.isPlaying != _isPlaying) {
          _isPlaying = v.isPlaying;
          _playingCtrl.add(_isPlaying);
        }
        if (_position != v.position) {
          _position = v.position;
          _positionCtrl.add(_position);
        }
        if (_duration != v.duration) {
          _duration = v.duration;
          _durationCtrl.add(_duration);
        }
        if ((_volume - v.volume).abs() > 0.001 && !_muted) {
          _volume = v.volume;
          _volumeCtrl.add(_volume);
        }
      }
    });
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
    _position = resumeFrom ?? Duration.zero;
    try {
      final old = _controller;
      final speed = playbackSpeed ?? _playbackSpeed;
      if (old != null) {
        try {
          old.removeListener(_onControllerTick);
        } catch (_) {}
      }
      _destroyOwnedHls();
      if (old != null) {
        try {
          await old.dispose();
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      final newCtl = vp.VideoPlayerController.networkUrl(
        Uri.parse(picked),
        httpHeaders: const {},
        videoPlayerOptions: vp.VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = newCtl;
      newCtl.addListener(_onControllerTick);
      await newCtl.initialize();
      try {
        await newCtl.setVolume(_muted ? 0.0 : _volume);
      } catch (_) {}
      try {
        if ((speed - 1.0).abs() > 0.001) {
          await newCtl.setPlaybackSpeed(speed);
        }
      } catch (_) {}
      _playbackSpeed = speed;
      bool qualityLocked = false;
      JSObject? jsVideo;
      if (_isHlsUrl(picked)) {
        jsVideo = _pickLatestVideoElementJs();
        if (jsVideo != null) {
          final existing = _attachHlsToJs(jsVideo, '');
          if (existing.isEmpty) {
            final k = _attachHlsToJs(jsVideo, picked);
            if (k.isNotEmpty) _ownedHlsKeys.add(k);
            try {
              iHlsRegisterQualitySwitchCb(jsVideo, _qualitySwitchCb((h) {
                final q = _qualityFromHeight(h);
                if (q != _quality) _quality = q;
              }));
            } catch (_) {}
          } else if (!_ownedHlsKeys.contains(existing)) {
            _ownedHlsKeys.add(existing);
            try {
              iHlsRegisterQualitySwitchCb(jsVideo, _qualitySwitchCb((h) {
                final q = _qualityFromHeight(h);
                if (q != _quality) _quality = q;
              }));
            } catch (_) {}
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
          final hasReal = _hasRealHlsInstance(jsVideo);
          if (!hasReal) {
            final retriedKey = _attachHlsToJs(jsVideo, picked);
            if (retriedKey.isNotEmpty &&
                !_ownedHlsKeys.contains(retriedKey)) {
              _ownedHlsKeys.add(retriedKey);
              iHlsRegisterQualitySwitchCb(jsVideo, _qualitySwitchCb((h) {
                final q = _qualityFromHeight(h);
                if (q != _quality) _quality = q;
              }));
              await Future<void>.delayed(const Duration(milliseconds: 250));
            }
          }
          if (_quality != VideoQuality.q1080p) {
            qualityLocked = _lockHlsLevel(jsVideo, _quality);
          } else {
            _unlockHlsAuto(jsVideo);
          }
        }
      }
      _initialized = true;
      _duration = newCtl.value.duration;
      _durationCtrl.add(_duration);
      if (resumeFrom != null && resumeFrom > Duration.zero) {
        final target = _position > Duration.zero && _duration > Duration.zero
            ? (_position > _duration ? _duration : _position)
            : resumeFrom;
        try {
          await newCtl.seekTo(target);
          _position = target;
          _positionCtrl.add(_position);
        } catch (_) {}
      }
      if (autoPlay) {
        try {
          await newCtl.play();
        } catch (e) {
          debugPrint('Autoplay blocked: $e');
          _isPlaying = false;
          _playingCtrl.add(false);
        }
      }
      if (_isHlsUrl(picked)) {
        _postInitializeHlsIfNeeded(picked).ignore();
      }
      if (!qualityLocked &&
          _isHlsUrl(picked) &&
          _quality != VideoQuality.q1080p) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        final js2 = _pickLatestVideoElementJs();
        if (js2 != null) _lockHlsLevel(js2, _quality);
      }
      _startTicker();
    } catch (e, s) {
      debugPrint('WebVideoPlayer init error: $e\n$s');
    }
  }

  void _onControllerTick() {
    if (_controller == null) return;
    final v = _controller!.value;
    bool need = false;
    if (v.isPlaying != _isPlaying) {
      _isPlaying = v.isPlaying;
      need = true;
    }
    if (_position != v.position) {
      _position = v.position;
      need = true;
    }
    if (_duration != v.duration) {
      _duration = v.duration;
      need = true;
    }
    if ((_volume - v.volume).abs() > 0.001 && !_muted) {
      _volume = v.volume;
      need = true;
    }
    if (need) {
      _playingCtrl.add(_isPlaying);
      _positionCtrl.add(_position);
      _durationCtrl.add(_duration);
      _volumeCtrl.add(_volume);
    }
  }

  @override
  Future<void> play() async {
    await _controller?.play();
  }

  @override
  Future<void> pause() async {
    await _controller?.pause();
  }

  @override
  Future<void> togglePlay() async {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      await _controller!.play();
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
    _position = position;
    _positionCtrl.add(position);
  }

  Duration _clamp(Duration d, Duration min, Duration max) {
    if (d < min) return min;
    if (d > max) return max;
    return d;
  }

  @override
  Future<void> seekRelative(Duration delta) async {
    final t = _clamp(_position + delta, Duration.zero,
        _duration > Duration.zero ? _duration : _position + delta);
    await seekTo(t);
  }

  @override
  Future<void> setVolume(double v) async {
    final normalized = v.clamp(0.0, 1.0);
    _volume = normalized;
    _muted = normalized <= 0.001;
    await _controller?.setVolume(normalized);
    _volumeCtrl.add(normalized);
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    if (muted) {
      await _controller?.setVolume(0.0);
      _volumeCtrl.add(0.0);
    } else {
      if (_volume <= 0.01) _volume = 0.8;
      await _controller?.setVolume(_volume);
      _volumeCtrl.add(_volume);
    }
  }

  @override
  Future<void> toggleMute() => setMuted(!_muted);

  @override
  Future<void> setPlaybackSpeed(double s) async {
    _playbackSpeed = s;
    await _controller?.setPlaybackSpeed(s);
  }

  @override
  Future<void> switchQuality(VideoQuality q) async {
    final oldUrl = _currentUrl;
    final resumePos = _position;
    final oldQuality = _quality;
    final newUrl = _pickUrlForQuality(q);
    final sameUrl = oldUrl != null &&
        newUrl == oldUrl &&
        _isHlsUrl(oldUrl) &&
        _isHlsUrl(newUrl);
    _quality = q;
    if (sameUrl) {
      final jsEl = _pickLatestVideoElementJs();
      if (jsEl != null) {
        if (!_hasRealHlsInstance(jsEl)) {
          final retryK = _attachHlsToJs(jsEl, newUrl);
          if (retryK.isNotEmpty) {
            _ownedHlsKeys.add(retryK);
            iHlsRegisterQualitySwitchCb(jsEl, _qualitySwitchCb((h) {
              final q = _qualityFromHeight(h);
              if (q != _quality) _quality = q;
            }));
            await Future<void>.delayed(const Duration(milliseconds: 400));
          }
        }
        if (q == VideoQuality.q1080p) {
          _unlockHlsAuto(jsEl);
        } else {
          _lockHlsLevel(jsEl, q);
        }
        return;
      }
    }
    try {
      await initialize(
        newUrl,
        qualityMap: _qualityMap,
        initialQuality: q,
        resumeFrom: resumePos,
        autoPlay: _isPlaying,
        playbackSpeed: _playbackSpeed,
      );
    } catch (e) {
      debugPrint('Switch quality error: $e');
      _quality = oldQuality;
    }
  }

  @override
  Future<void> dispose() async {
    _tickTimer?.cancel();
    _destroyOwnedHls();
    try {
      _controller?.removeListener(_onControllerTick);
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    await _positionCtrl.close();
    await _playingCtrl.close();
    await _durationCtrl.close();
    await _volumeCtrl.close();
  }
}
