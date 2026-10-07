import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../content/data/providers/content_providers.dart';
import '../../../content/domain/entities/video_content.dart';
import '../../../user/data/providers/user_providers.dart';
import '../../../content/presentation/widgets/video_card.dart';

class VideoDetailPage extends ConsumerStatefulWidget {
  final String videoId;
  const VideoDetailPage({super.key, required this.videoId});

  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage> {
  late final ScrollController _scrollController;
  int _selectedSeason = 1;
  static final Map<String, VideoContent> _cache = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = ref.watch(videoByIdProvider(widget.videoId));
    final allVideos = ref.watch(allVideosProvider);

    if (video == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundDark,
          title: const Text('内容未找到'),
        ),
        body: const Center(
          child: Text('未找到该视频内容', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    _cache[video.id] = video;

    final similar = allVideos
        .where((v) =>
            v.id != video.id &&
            v.genres.any((g) => video.genres.contains(g)))
        .take(12)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _DetailHero(video: video)),
              SliverToBoxAdapter(
                child: _DetailBody(video: video, selectedSeason: _selectedSeason),
              ),
              if (video.isSeries && video.seasons != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 0, 48, 12),
                    child: _SeasonSelector(
                      seasons: video.seasons!,
                      selected: _selectedSeason,
                      onChanged: (s) => setState(() => _selectedSeason = s),
                    ),
                  ),
                ),
              if (video.isSeries && video.seasons != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
                  sliver: _EpisodeList(
                    videoId: video.id,
                    season: video.seasons!.firstWhere(
                      (s) => s.seasonNumber == _selectedSeason,
                      orElse: () => video.seasons!.first,
                    ),
                  ),
                ),
              if (similar.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 20, 48, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '更多相似内容',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 330,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: similar.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (ctx, i) =>
                                VideoCard(video: similar[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 4,
            child: SafeArea(
              child: IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/home'),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                  foregroundColor: AppTheme.textPrimary,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static VideoContent? findVideoCached(String id) => _cache[id];
}

class _DetailHero extends StatelessWidget {
  final VideoContent video;
  const _DetailHero({required this.video});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.width > 1000 ? 620.0 : 480.0;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: video.backdropUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: AppTheme.surfaceDark),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    AppTheme.backgroundDark.withOpacity(0.5),
                    AppTheme.backgroundDark,
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    AppTheme.backgroundDark.withOpacity(0.9),
                  ],
                  stops: const [0.35, 0.85],
                ),
              ),
            ),
          ),
          Positioned(
            left: size.width * 0.04,
            right: size.width * 0.4,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1,
                    shadows: [Shadow(blurRadius: 12, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber.shade400, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      video.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${video.releaseYear}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.textSecondary.withOpacity(0.6),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        video.maturityRating,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (video.duration != null)
                      Text(
                        _formatDur(video.duration!),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else if (video.totalEpisodes != null)
                      Text(
                        '共 ${video.totalEpisodes} 集',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/player/${video.id}'),
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text(
                        '播放',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(20, 10, 28, 10),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _MyListBtn(videoId: video.id),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.thumb_down_alt_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}小时${m}分';
    return '${m}分钟';
  }
}

class _MyListBtn extends ConsumerWidget {
  final String videoId;
  const _MyListBtn({required this.videoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inList = ref.watch(isInMyListProvider(videoId));
    return IconButton.filled(
      onPressed: () =>
          ref.read(toggleMyListProvider.notifier).toggle(videoId),
      icon: Icon(inList ? Icons.check_rounded : Icons.add_rounded, size: 26),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: AppTheme.textPrimary,
      ),
      tooltip: inList ? '已加入片单' : '加入片单',
    );
  }
}

class _DetailBody extends StatelessWidget {
  final VideoContent video;
  final int selectedSeason;
  const _DetailBody({required this.video, required this.selectedSeason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 48, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '97% 匹配  ',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${video.releaseYear}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.textSecondary.withOpacity(0.6),
                                width: 0.5),
                          ),
                          child: Text(
                            video.maturityRating,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (video.duration != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            _formatDur(video.duration!),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryRed,
                          ),
                          child: const Text(
                            'HD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      video.description,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine('演员：', video.cast.join('、')),
                    const SizedBox(height: 8),
                    _InfoLine('导演：', video.directors.join('、')),
                    const SizedBox(height: 8),
                    _InfoLine('类型：', video.genres.join('、')),
                    if (video.isSeries) ...[
                      const SizedBox(height: 8),
                      _InfoLine(
                          '剧集：',
                          '${video.seasons?.length ?? 1} 季 · 共 ${video.totalEpisodes} 集'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}小时${m}分';
    return '${m}分钟';
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.5),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  final List<Season> seasons;
  final int selected;
  final ValueChanged<int> onChanged;

  const _SeasonSelector({
    required this.seasons,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selected,
          isDense: true,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textPrimary),
          items: seasons
              .map((s) => DropdownMenuItem(
                    value: s.seasonNumber,
                    child: Text('第 ${s.seasonNumber} 季'),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _EpisodeList extends StatelessWidget {
  final String videoId;
  final Season season;
  const _EpisodeList({required this.videoId, required this.season});

  int _accumulatedEpisodeIndex() {
    final v = _VideoDetailPageState.findVideoCached(videoId);
    if (v == null || v.seasons == null) return 0;
    int idx = 0;
    for (final s in v.seasons!) {
      if (s.seasonNumber == season.seasonNumber) return idx;
      idx += s.episodes.length;
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final acc = _accumulatedEpisodeIndex();
    return SliverList.separated(
      itemCount: season.episodes.length,
      separatorBuilder: (_, __) => const Divider(
        color: AppTheme.divider,
        thickness: 1,
        height: 16,
      ),
      itemBuilder: (ctx, i) {
        final ep = season.episodes[i];
        return _EpisodeTile(
          videoId: videoId,
          episode: ep,
          episodeIndex: acc + i,
          index: i + 1,
        );
      },
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  final String videoId;
  final Episode episode;
  final int episodeIndex;
  final int index;

  const _EpisodeTile({
    required this.videoId,
    required this.episode,
    required this.episodeIndex,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressKey =
        '${videoId}_s${episode.seasonNumber}_e${episode.episodeNumber}';
    final progress = ref.watch(watchProgressProvider(progressKey));

    return InkWell(
      onTap: () => context.push('/player/$videoId?episode=$episodeIndex'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '$index',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 200,
                    height: 112,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: episode.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: AppTheme.surfaceLight),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        if (progress != null && progress > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 4,
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppTheme.primaryRed),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${episode.duration.inMinutes}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '第 ${episode.episodeNumber} · ${episode.title}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    episode.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
