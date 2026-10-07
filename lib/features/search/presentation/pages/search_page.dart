import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../content/data/providers/content_providers.dart';
import '../../../content/domain/entities/video_content.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final all = ref.watch(allVideosProvider);
    final hasQuery = query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) => ref
                      .read(searchQueryProvider.notifier)
                      .state = v,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16),
                  cursorColor: AppTheme.primaryRed,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.textSecondary, size: 24),
                    suffixIcon: query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _controller.clear();
                              ref.read(searchQueryProvider.notifier).state = '';
                              FocusScope.of(context)
                                  .requestFocus(_focusNode);
                            },
                            child: const Icon(Icons.close_rounded,
                                color: AppTheme.textSecondary),
                          )
                        : null,
                    hintText:
                        '搜索影片、剧集、演员、导演、类型…',
                    hintStyle:
                        const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryRed, width: 1.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: hasQuery
              ? _buildSearchResults(results, query)
              : _buildExplore(all),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<VideoContent> results, String query) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 72,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到与「$query」相关的结果',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '试试其他关键词吧',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    return _GridResults(results: results);
  }

  Widget _buildExplore(List<VideoContent> all) {
    const genres = [
      {'name': '科幻', 'icon': Icons.rocket_launch_rounded, 'color': Color(0xFF5B8DEF)},
      {'name': '动作', 'icon': Icons.local_fire_department_rounded, 'color': Color(0xFFEF6A6A)},
      {'name': '爱情', 'icon': Icons.favorite_rounded, 'color': Color(0xFFF07CA8)},
      {'name': '悬疑', 'icon': Icons.search_rounded, 'color': Color(0xFF8E74F5)},
      {'name': '喜剧', 'icon': Icons.emoji_emotions_rounded, 'color': Color(0xFFF2B45B)},
      {'name': '剧情', 'icon': Icons.theater_comedy_rounded, 'color': Color(0xFF4CC9B4)},
      {'name': '纪录片', 'icon': Icons.landscape_rounded, 'color': Color(0xFF6CBE6B)},
      {'name': '古装', 'icon': Icons.brush_rounded, 'color': Color(0xFFC89A67)},
    ];

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              '按类型浏览',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final g = genres[i];
                return _GenreCard(
                  name: g['name'] as String,
                  icon: g['icon'] as IconData,
                  color: g['color'] as Color,
                  onTap: () {
                    _controller.text = g['name'] as String;
                    ref.read(searchQueryProvider.notifier).state =
                        g['name'] as String;
                  },
                );
              },
              childCount: genres.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              '热门推荐',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _GridResults(results: all.take(20).toList()),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _GenreCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _GenreCard({
    required this.name,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                icon,
                size: 86,
                color: color.withOpacity(0.4),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.22), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: Text(
                name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridResults extends StatelessWidget {
  final List<VideoContent> results;
  const _GridResults({required this.results});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        primary: false,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2 / 3,
        ),
        itemCount: results.length,
        itemBuilder: (ctx, i) {
          final v = results[i];
          return _SearchTile(video: v);
        },
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  final VideoContent video;
  const _SearchTile({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${video.id}'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: video.posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.surfaceLight,
                        child: const Icon(Icons.movie,
                            size: 48, color: AppTheme.textMuted),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ),
                    if (video.isTopTen)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: AppTheme.primaryRed,
                          child: Text(
                            '#${video.topTenRank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              video.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  '${video.releaseYear}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  video.genres.isNotEmpty ? '· ${video.genres.first}' : '',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
