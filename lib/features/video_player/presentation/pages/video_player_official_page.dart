import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart' as vp;
import 'dart:async';
import 'dart:html' as html;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/video_quality.dart';
import '../../../content/data/providers/content_providers.dart';
import '../../../content/domain/entities/video_content.dart';

class VideoPlayerOfficialPage extends ConsumerStatefulWidget {
  final String videoId;
  final int episodeIndex;

  const VideoPlayerOfficialPage({
    super.key,
    required this.videoId,
    this.episodeIndex = 0,
  });

  @override
  ConsumerState<VideoPlayerOfficialPage> createState() =>
      _VideoPlayerOfficialPageState();
}

class _VideoPlayerOfficialPageState
    extends ConsumerState<VideoPlayerOfficialPage> {
  vp.VideoPlayerController? _controller;
  bool _initialized = false;
  bool _controlsVisible = true;
  Timer? _controlsTimer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  double _volume = 1.0;
  bool _muted = false;
  double _playbackSpeed = 1.0;
  bool _isFullscreen = false;
  VideoQuality _quality = VideoQuality.q1080p;
  bool _qualityMenuOpen = false;
  bool _speedMenuOpen = false;
  bool _showNextPrev = true;
  String? _currentUrl;
  Map<VideoQuality, String>? _currentQualityMap;
  bool _isDraggingSlider = false;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlayer();
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  bool _isHlsUrl(String? url) =>
      url != null && url.toLowerCase().endsWith('.m3u8');

  String _pickUrlForQuality(VideoQuality q) {
    final m = _currentQualityMap;
    if (m != null && m.containsKey(q) && m[q] != null && m[q]!.isNotEmpty) {
      return m[q]!;
    }
    if (_currentUrl != null) return _currentUrl!;
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  }

  void _initPlayer() {
    final video = ref.read(videoByIdProvider(widget.videoId));
    String? url;
    Map<VideoQuality, String>? qmap;
    if (video != null) {
      if (video.isSeries && video.seasons != null) {
        int counter = 0;
        outer:
        for (final s in video.seasons!) {
          for (final e in s.episodes) {
            if (counter == widget.episodeIndex) {
              if (e.videoUrls != null && e.videoUrls!.isNotEmpty) {
                qmap = Map<VideoQuality, String>.unmodifiable(e.videoUrls!);
                final picked = e.videoUrls![_quality];
                url = picked ?? e.videoUrl ?? e.videoUrls!.values.first;
              } else {
                url = e.videoUrl;
              }
              break outer;
            }
            counter++;
          }
        }
      } else {
        if (video.mainVideoUrls != null && video.mainVideoUrls!.isNotEmpty) {
          qmap = Map<VideoQuality, String>.unmodifiable(video.mainVideoUrls!);
          final picked = video.mainVideoUrls![_quality];
          url = picked ?? video.mainVideoUrl ?? video.mainVideoUrls!.values.first;
        } else {
          url = video.mainVideoUrl;
        }
      }
    }
    url ??=
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    _currentQualityMap = qmap;
    _load(url);
  }

  Future<void> _load(
    String url, {
    Duration? resumeFrom,
    bool autoPlay = true,
    double? playbackSpeed,
  }) async {
    setState(() {
      _initialized = false;
      _isPlaying = false;
      _currentUrl = url;
      if (resumeFrom == null) {
        _position = Duration.zero;
      }
      _total = Duration.zero;
    });
    try {
      final old = _controller;
      final speed = playbackSpeed ?? _playbackSpeed;
      final newCtl = vp.VideoPlayerController.networkUrl(
        Uri.parse(url),
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
      setState(() {
        _initialized = true;
        _total = newCtl.value.duration;
        _playbackSpeed = speed;
      });
      if (resumeFrom != null && resumeFrom > Duration.zero) {
        final d = _clampDuration(resumeFrom, Duration.zero,
            _total > Duration.zero ? _total : resumeFrom);
        try {
          await newCtl.seekTo(d);
          if (mounted) setState(() => _position = d);
        } catch (_) {}
      }
      if (autoPlay) {
        try {
          await newCtl.play();
        } catch (e) {
          debugPrint('Autoplay blocked (user gesture required): $e');
          if (mounted) setState(() => _isPlaying = false);
        }
      }
      if (old != null) {
        try {
          old.removeListener(_onControllerTick);
          await old.dispose();
        } catch (_) {}
      }
    } catch (e, s) {
      debugPrint('VideoPlayerOfficial load error: $e\n$s');
      if (!mounted) return;
      setState(() => _initialized = true);
    }
  }

  void _onControllerTick() {
    if (!mounted || _controller == null) return;
    final v = _controller!.value;
    bool needBuild = false;
    if (v.isPlaying != _isPlaying) {
      _isPlaying = v.isPlaying;
      needBuild = true;
    }
    if (_position != v.position && !_isDraggingSlider) {
      _position = v.position;
      needBuild = true;
    }
    if (_total != v.duration) {
      _total = v.duration;
      needBuild = true;
    }
    if ((_volume - v.volume).abs() > 0.001 && !_muted) {
      _volume = v.volume;
      needBuild = true;
    }
    if (needBuild) setState(() {});
  }

  Future<void> _switchQuality(VideoQuality q) async {
    _resetControlsTimer();
    final oldUrl = _currentUrl;
    final resumePos = _position;
    final oldQuality = _quality;
    setState(() {
      _quality = q;
      _qualityMenuOpen = false;
    });
    final newUrl = _pickUrlForQuality(q);
    final sameUrl = oldUrl != null &&
        newUrl == oldUrl &&
        _isHlsUrl(oldUrl) &&
        _isHlsUrl(newUrl);
    if (sameUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '当前视频使用自适应流（HLS ABR），实际码率由播放器根据带宽自动选择，当前偏好：${q.label}',
          ),
          backgroundColor: AppTheme.surfaceLight,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('画质已切换到 ${q.label}，正在重新加载视频…'),
        backgroundColor: AppTheme.surfaceLight,
        duration: const Duration(seconds: 2),
      ),
    );
    try {
      await _load(newUrl, resumeFrom: resumePos, playbackSpeed: _playbackSpeed);
    } catch (e) {
      debugPrint('Switch quality error: $e');
      if (!mounted) return;
      setState(() => _quality = oldQuality);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('切换画质失败，已回退到原画质'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _togglePlay() async {
    _resetControlsTimer();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      if (c.value.isPlaying) {
        await c.pause();
      } else {
        await c.play();
      }
    } catch (e) {
      debugPrint('togglePlay error: $e');
    }
  }

  Duration _clampDuration(Duration d, Duration min, Duration max) {
    if (d < min) return min;
    if (d > max) return max;
    return d;
  }

  void _seekRelative(Duration d) async {
    _resetControlsTimer();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final t = _clampDuration(_position + d, Duration.zero, _total);
    try {
      await c.seekTo(t);
      if (mounted) setState(() => _position = t);
    } catch (_) {}
  }

  void _seekTo(Duration d) async {
    _resetControlsTimer();
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.seekTo(d);
      if (mounted) setState(() => _position = d);
    } catch (_) {}
  }

  void _toggleMute() async {
    _resetControlsTimer();
    final c = _controller;
    final toMuted = !_muted;
    setState(() => _muted = toMuted);
    if (c == null) return;
    try {
      if (toMuted) {
        await c.setVolume(0.0);
      } else {
        final v = _volume <= 0.01 ? 0.8 : _volume;
        await c.setVolume(v);
      }
    } catch (_) {}
  }

  void _setVolume(double v) async {
    final c = _controller;
    setState(() {
      _volume = v;
      _muted = v <= 0.001;
    });
    if (c == null) return;
    try {
      await c.setVolume(v);
    } catch (_) {}
  }

  void _setSpeed(double s) async {
    _resetControlsTimer();
    final c = _controller;
    setState(() {
      _playbackSpeed = s;
      _speedMenuOpen = false;
    });
    if (c == null) return;
    try {
      await c.setPlaybackSpeed(s);
    } catch (_) {}
  }

  void _showControls() {
    if (!mounted) return;
    setState(() => _controlsVisible = true);
    _resetControlsTimer();
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _controlsVisible = false;
          _qualityMenuOpen = false;
          _speedMenuOpen = false;
        });
      }
    });
  }

  void _skipNextOrPrev({bool next = true}) {
    final video = ref.read(videoByIdProvider(widget.videoId));
    if (video == null || !video.isSeries || video.seasons == null) return;
    final cur = widget.episodeIndex + (next ? 1 : -1);
    if (cur < 0) return;
    int total = 0;
    for (final s in video.seasons!) {
      total += s.episodes.length;
    }
    if (cur >= total) return;
    context.pushReplacement('/player/${widget.videoId}?episode=$cur');
  }

  void _toggleCast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('投屏功能：请稍后补充 Chromecast 配置')),
    );
  }

  void _toggleFullscreen() {
    _resetControlsTimer();
    if (_isFullscreen) {
      try {
        html.document.exitFullscreen();
      } catch (_) {}
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      setState(() => _isFullscreen = false);
    } else {
      try {
        html.document.documentElement?.requestFullscreen();
      } catch (_) {}
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      setState(() => _isFullscreen = true);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(videoByIdProvider(widget.videoId));
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _seekRelative(const Duration(seconds: -10)),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _seekRelative(const Duration(seconds: 10)),
        const SingleActivator(LogicalKeyboardKey.keyJ): () =>
            _seekRelative(const Duration(seconds: -10)),
        const SingleActivator(LogicalKeyboardKey.keyL): () =>
            _seekRelative(const Duration(seconds: 10)),
        const SingleActivator(LogicalKeyboardKey.keyK): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): () {
          _setVolume(((_volume + 0.1) * 10).roundToDouble() / 10
              .clamp(0.0, 1.0));
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): () {
          _setVolume(((_volume - 0.1) * 10).roundToDouble() / 10
              .clamp(0.0, 1.0));
        },
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          setState(() => _isFullscreen = !_isFullscreen);
          _toggleFullscreen();
        },
        const SingleActivator(LogicalKeyboardKey.keyM): _toggleMute,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: MouseRegion(
            onHover: (_) => _showControls(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_controlsVisible && _isPlaying) {
                  setState(() {
                    _controlsVisible = false;
                    _qualityMenuOpen = false;
                    _speedMenuOpen = false;
                  });
                  _controlsTimer?.cancel();
                } else {
                  _showControls();
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _initialized && _controller != null
                          ? vp.VideoPlayer(_controller!)
                          : Container(
                              color: Colors.black,
                              child: const Center(
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryRed,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (!_isPlaying && _initialized)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 120,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xE6000000), Colors.transparent],
                                ),
                              ),
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 24, 0),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          context.canPop()
                                              ? context.pop()
                                              : context.go('/home');
                                        },
                                        icon: const Icon(
                                            Icons.arrow_back_ios_new_rounded),
                                        color: Colors.white,
                                        iconSize: 22,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black26,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (video != null)
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                video.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (video.isSeries)
                                                _buildEpisodeSubtitle(video),
                                            ],
                                          ),
                                        ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: _toggleCast,
                                        icon: const Icon(Icons.cast_rounded),
                                        color: Colors.white,
                                        tooltip: '投屏',
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() => _isFullscreen =
                                              !_isFullscreen);
                                          _toggleFullscreen();
                                        },
                                        icon: Icon(
                                          _isFullscreen
                                              ? Icons.close_fullscreen_rounded
                                              : Icons.open_in_full_rounded,
                                        ),
                                        color: Colors.white,
                                        tooltip: '全屏',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Row(
                              children: [
                                if (_showNextPrev)
                                  Expanded(
                                    child: _SkipButton(
                                      direction: SkipDirection.prev,
                                      onTap: _isPlaying
                                          ? () =>
                                              _skipNextOrPrev(next: false)
                                          : null,
                                    ),
                                  ),
                                if (_showNextPrev)
                                  Expanded(
                                    child: _SkipButton(
                                      direction: SkipDirection.next,
                                      onTap: _isPlaying
                                          ? () => _skipNextOrPrev(next: true)
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 40, 24, 28),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Color(0xE6000000), Colors.transparent],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildProgress(),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: _togglePlay,
                                        color: Colors.white,
                                        icon: Icon(
                                          _isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                        ),
                                        iconSize: 30,
                                      ),
                                      IconButton(
                                        onPressed: () => _seekRelative(
                                            const Duration(seconds: -10)),
                                        color: Colors.white,
                                        icon: const Icon(
                                            Icons.replay_10_rounded),
                                        iconSize: 28,
                                        tooltip: '后退10秒',
                                      ),
                                      IconButton(
                                        onPressed: () => _seekRelative(
                                            const Duration(seconds: 10)),
                                        color: Colors.white,
                                        icon: const Icon(
                                            Icons.forward_10_rounded),
                                        iconSize: 28,
                                        tooltip: '快进10秒',
                                      ),
                                      const SizedBox(width: 4),
                                      _buildVolumeControl(),
                                      const SizedBox(width: 16),
                                      Text(
                                        _formatDuration(_position),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Text(
                                        ' / ',
                                        style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13),
                                      ),
                                      Text(
                                        _formatDuration(_total),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      _buildSpeedMenu(),
                                      _buildQualityMenu(),
                                      const SizedBox(width: 12),
                                      Text(
                                        _quality.label,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeSubtitle(VideoContent video) {
    if (video.seasons == null) return const SizedBox.shrink();
    int c = 0;
    Episode? ep;
    outer:
    for (final s in video.seasons!) {
      for (final e in s.episodes) {
        if (c == widget.episodeIndex) {
          ep = e;
          break outer;
        }
        c++;
      }
    }
    if (ep == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'S${ep.seasonNumber} · E${ep.episodeNumber} ${ep.title}',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final totalInMs = _total.inMilliseconds;
    final posInMs = _position.inMilliseconds;
    final max = totalInMs > 0 ? totalInMs.toDouble() : 1.0;
    final v = posInMs.toDouble().clamp(0.0, max);
    final value = v / max;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 14,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryRed,
              inactiveTrackColor: Colors.white38,
              trackHeight: 4,
              thumbColor: AppTheme.primaryRed,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6, elevation: 2),
              overlayColor: AppTheme.primaryRed.withOpacity(0.2),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              onChangeStart: (_) {
                _isDraggingSlider = true;
                _controlsTimer?.cancel();
              },
              onChanged: (nv) {
                final t = Duration(milliseconds: (nv * totalInMs).round());
                setState(() => _position = t);
              },
              onChangeEnd: (nv) {
                final t = Duration(milliseconds: (nv * totalInMs).round());
                _seekTo(t);
                _isDraggingSlider = false;
                _resetControlsTimer();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _toggleMute,
          color: Colors.white,
          icon: Icon(
            _muted || _volume < 0.01
                ? Icons.volume_off_rounded
                : _volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
          ),
          iconSize: 26,
        ),
        SizedBox(
          width: 70,
          height: 32,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white38,
              trackHeight: 3,
              thumbColor: Colors.white,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayColor: Colors.white12,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: _muted ? 0.0 : _volume,
              min: 0.0,
              max: 1.0,
              onChanged: _setVolume,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedMenu() {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    return PopupMenuButton<double>(
      tooltip: '播放速度',
      color: AppTheme.surfaceDark,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      elevation: 8,
      onSelected: _setSpeed,
      onCanceled: () => setState(() => _speedMenuOpen = false),
      onOpened: () => setState(() {
        _speedMenuOpen = true;
        _qualityMenuOpen = false;
      }),
      itemBuilder: (_) => speeds
          .map((s) => PopupMenuItem(
                value: s,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Icon(
                        (_playbackSpeed - s).abs() < 0.001
                            ? Icons.check
                            : null,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s == 1.0 ? '${s}x 正常' : '${s}x',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: (_playbackSpeed - s).abs() < 0.001
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _speedMenuOpen ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _playbackSpeed == 1.0 ? '1x' : '${_playbackSpeed}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildQualityMenu() {
    const qs = VideoQuality.values;
    return PopupMenuButton<VideoQuality>(
      tooltip: '画质',
      color: AppTheme.surfaceDark,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      elevation: 8,
      onSelected: _switchQuality,
      onCanceled: () => setState(() => _qualityMenuOpen = false),
      onOpened: () => setState(() {
        _qualityMenuOpen = true;
        _speedMenuOpen = false;
      }),
      itemBuilder: (_) => qs
          .map((q) => PopupMenuItem(
                value: q,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Icon(
                        _quality == q ? Icons.check : null,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: _quality == q
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      child: IconButton(
        onPressed: null,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
              _qualityMenuOpen ? Colors.white12 : Colors.transparent),
        ),
        icon: const Icon(Icons.high_quality_rounded, color: Colors.white),
      ),
    );
  }
}

enum SkipDirection { prev, next }

class _SkipButton extends StatefulWidget {
  final SkipDirection direction;
  final VoidCallback? onTap;
  const _SkipButton({required this.direction, this.onTap});

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isNext = widget.direction == SkipDirection.next;
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _hovered ? 1.0 : 0.0,
          child: Align(
            alignment: isNext ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                  right: isNext ? 32 : 0, left: isNext ? 0 : 32),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNext) ...[
                    const Icon(Icons.skip_previous_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment: isNext
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNext ? '下一集' : '上一集',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '点击播放',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (isNext) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.skip_next_rounded,
                        color: Colors.white, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
