import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../content/data/providers/content_providers.dart';
import '../../../content/domain/entities/video_content.dart';
import '../../../user/data/providers/user_providers.dart';

class MyListPage extends ConsumerWidget {
  const MyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listIds = ref.watch(myListProvider);
    final all = ref.watch(allVideosProvider);
    final myListVideos =
        all.where((v) => listIds.contains(v.id)).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Text(
                  '我的片单',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Text(
                  '${myListVideos.length} 部作品已收藏',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (myListVideos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 2 / 3,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _MyListTile(video: myListVideos[i]),
                    childCount: myListVideos.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(48),
            ),
            child: const Icon(
              Icons.bookmark_outline_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '你的片单还是空的',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '在观看影片时点击「+」按钮，把喜欢的作品添加到这里',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('去发现好片'),
          ),
        ],
      ),
    );
  }
}

class _MyListTile extends ConsumerStatefulWidget {
  final VideoContent video;
  const _MyListTile({required this.video});

  @override
  ConsumerState<_MyListTile> createState() => _MyListTileState();
}

class _MyListTileState extends ConsumerState<_MyListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(watchProgressProvider(widget.video.id));
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/detail/${widget.video.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _hovered
              ? (Matrix4.identity()..scale(1.03))
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.video.posterUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.surfaceLight,
                    child: const Icon(Icons.movie,
                        size: 48, color: AppTheme.textMuted),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _hovered ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(10, 0, 10, 8),
                            child: Text(
                              widget.video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                      '/player/${widget.video.id}'),
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    '播放',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _removeButton(),
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
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
                      backgroundColor: Colors.transparent,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.primaryRed),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _removeButton() {
    return GestureDetector(
      onTap: () {
        ref.read(toggleMyListProvider.notifier).toggle(widget.video.id);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white60, width: 1),
        ),
        child: const Icon(Icons.remove_rounded,
            size: 18, color: Colors.white),
      ),
    );
  }
}
