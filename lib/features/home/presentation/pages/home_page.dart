import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/platform/platform.dart';
import '../../../content/data/providers/content_providers.dart';
import '../../../content/domain/entities/video_content.dart';
import '../../../content/presentation/widgets/video_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ScrollController _scrollController;

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
    final hero = ref.watch(heroBannerProvider);
    final categories = ref.watch(homeCategoriesProvider);
    final topTen = ref.watch(topTenProvider);
    final isMobile = Breakpoints.isMobile(context);

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroBanner(video: hero, isMobile: isMobile),
          const SizedBox(height: 8),
          _CategoryRow(
            title: categories.firstWhere((c) => c.id == 'cat_top10').name,
            videos: topTen,
            showRank: true,
            isMobile: isMobile,
          ),
          ...categories
              .where((c) => c.id != 'cat_top10' && c.videos.isNotEmpty)
              .map((c) => _CategoryRow(
                    title: c.name,
                    videos: c.videos,
                    isMobile: isMobile,
                  )),
          SizedBox(height: isMobile ? 100 : 80),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatefulWidget {
  final VideoContent video;
  final bool isMobile;
  const _HeroBanner({required this.video, required this.isMobile});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  bool _muted = true;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile;
    final bannerH = isMobile
        ? 520.0
        : screenW > 1200
            ? 640.0
            : screenW > 800
                ? 520.0
                : 420.0;
    final titleSize = isMobile ? 28.0 : (screenW > 1200 ? 56.0 : 44.0);
    final contentWidth = isMobile ? screenW * 0.92 : screenW * 0.50;
    final contentLeft = isMobile ? 16.0 : screenW * 0.05;
    final contentBottom = isMobile ? 100.0 : 120.0;

    return SizedBox(
      width: double.infinity,
      height: bannerH,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.video.backdropUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppTheme.surfaceDark),
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
                    AppTheme.backgroundDark.withOpacity(0.1),
                    Colors.transparent,
                    AppTheme.backgroundDark.withOpacity(0.3),
                    AppTheme.backgroundDark,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
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
                    AppTheme.backgroundDark.withOpacity(0.85),
                  ],
                  stops: const [0.4, 0.9],
                ),
              ),
            ),
          ),
          Positioned(
            left: contentLeft,
            bottom: contentBottom,
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.video.isTopTen)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: AppTheme.primaryRed,
                        child: Text(
                          'iSEE 热门榜 TOP 10',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: isMobile ? 10 : 12),
                Text(
                  widget.video.title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.5,
                    height: 1.05,
                    shadows: const [
                      Shadow(
                        blurRadius: 18,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.textSecondary, width: 0.5),
                      ),
                      child: Text(
                        widget.video.maturityRating,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.video.releaseYear}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.video.duration != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        _formatDuration(widget.video.duration!),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (widget.video.isSeries) ...[
                      const SizedBox(width: 10),
                      Text(
                        '${widget.video.seasons?.length ?? 1}季 全${widget.video.totalEpisodes ?? ''}集',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: isMobile ? 8 : 14),
                SizedBox(
                  width: isMobile ? double.infinity : 480,
                  child: Text(
                    widget.video.description,
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: isMobile ? 13 : 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black45),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 14 : 22),
                Wrap(
                  spacing: isMobile ? 8 : 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/player-mk/${widget.video.id}'),
                      icon: Icon(Icons.play_arrow_rounded,
                          size: isMobile ? 22 : 28),
                      label: Text(
                        '播放',
                        style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 20,
                            isMobile ? 8 : 10,
                            isMobile ? 22 : 28,
                            isMobile ? 8 : 10),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/detail/${widget.video.id}'),
                      icon: Icon(Icons.info_outline_rounded,
                          size: isMobile ? 20 : 24),
                      label: Text(
                        '详细信息',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: isMobile ? 16 : 36,
            bottom: isMobile ? 110 : 140,
            child: IconButton(
              onPressed: () => setState(() => _muted = !_muted),
              icon: Icon(
                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                size: isMobile ? 22 : 28,
                color: AppTheme.textSecondary,
              ),
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              style: IconButton.styleFrom(
                side: const BorderSide(color: AppTheme.textSecondary),
                shape: const CircleBorder(),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: isMobile ? 110 : 140,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                border: Border(
                  left: BorderSide(color: AppTheme.textSecondary, width: 3),
                ),
              ),
              child: Text(
                widget.video.isSeries
                    ? 'S${widget.video.seasons?.first.seasonNumber ?? 1} · E1'
                    : '电影',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}小时${m}分';
    return '${m}分钟';
  }
}

class _CategoryRow extends StatefulWidget {
  final String title;
  final List<VideoContent> videos;
  final bool showRank;
  final bool isMobile;

  const _CategoryRow({
    required this.title,
    required this.videos,
    this.showRank = false,
    this.isMobile = false,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  late final ScrollController _controller;
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_onScroll);
      _onScroll();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _controller.offset;
    final maxScroll = _controller.position.maxScrollExtent;
    setState(() {
      _showLeftArrow = offset > 0.5;
      _showRightArrow = offset < maxScroll - 0.5;
    });
  }

  void _scrollBy(bool left) {
    final v = _controller.position.viewportDimension * 0.9;
    _controller.animateTo(
      _controller.offset + (left ? -v : v),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) return const SizedBox.shrink();
    final isMobile = widget.isMobile;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, isMobile ? 8 : 10),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: isMobile ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    '查看全部',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withOpacity(0.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: isMobile
                ? (widget.showRank ? 300 : 260)
                : (widget.showRank ? 380 : 330),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24),
                    child: ListView.separated(
                      controller: _controller,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.videos.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(width: isMobile ? 8 : 12),
                      itemBuilder: (ctx, i) {
                        final v = widget.videos[i];
                        return VideoCard(
                          video: v,
                          showRank: widget.showRank,
                          rank: v.topTenRank ?? (i + 1),
                          compact: isMobile,
                        );
                      },
                    ),
                  ),
                ),
                if (!isMobile && _showLeftArrow) _buildArrow(true),
                if (!isMobile && _showRightArrow) _buildArrow(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow(bool left) {
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 30,
      bottom: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _scrollBy(left),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(left ? 0 : 8),
                bottomLeft: Radius.circular(left ? 0 : 8),
                topRight: Radius.circular(left ? 8 : 0),
                bottomRight: Radius.circular(left ? 8 : 0),
              ),
            ),
            child: Center(
              child: Icon(
                left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 36,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
