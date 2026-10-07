import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/video_content.dart';
import '../../data/providers/content_providers.dart';
import '../../../user/data/providers/user_providers.dart';

class VideoCard extends ConsumerStatefulWidget {
  final VideoContent video;
  final bool showRank;
  final int? rank;
  final bool isLarge;

  const VideoCard({
    super.key,
    required this.video,
    this.showRank = false,
    this.rank,
    this.isLarge = false,
  });

  @override
  ConsumerState<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<VideoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.isLarge
        ? const Size(260, 390)
        : const Size(200, 300);

    final card = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/detail/${widget.video.id}'),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            _buildPoster(size),
            if (widget.showRank) _buildRankBadge(),
            Positioned(
              left: -12,
              right: -12,
              bottom: -80,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovered ? 1.0 : 0.0,
                child: _buildInfoCard(),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.showRank) {
      return SizedBox(width: size.width + 40, child: card);
    }
    return SizedBox(width: size.width, child: card);
  }

  Widget _buildPoster(Size size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      transform: _hovered
          ? (Matrix4.identity()
            ..scale(1.08)
            ..translate(0.0, -20.0))
          : Matrix4.identity(),
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_hovered ? 6 : 4),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.video.posterUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.surfaceLight,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.movie_rounded, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    final rank = widget.rank ?? 1;
    return Positioned(
      left: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: const Size(60, 140),
              painter: _RankBadgePainter(),
            ),
            Positioned(
              left: 6,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontFamily: 'Arial',
                  letterSpacing: -4,
                  height: 1.0,
                ),
                strutStyle: const StrutStyle(height: 1.0),
              ),
            ),
            Positioned(
              left: 5,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = AppTheme.textPrimary,
                  fontFamily: 'Arial',
                  letterSpacing: -4,
                  height: 1.0,
                ),
                strutStyle: const StrutStyle(height: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return IgnorePointer(
      ignoring: !_hovered,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 48, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: '播放',
                    filled: true,
                    onTap: () => context.push('/player/${widget.video.id}'),
                  ),
                ),
                const SizedBox(width: 6),
                _MyListButton(videoId: widget.video.id),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                _ActionButton(
                  icon: Icons.keyboard_arrow_down_rounded,
                  onTap: () => context.push('/detail/${widget.video.id}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${widget.video.rating.toStringAsFixed(1)} 分',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textMuted, width: 0.5),
                  ),
                  child: Text(
                    widget.video.maturityRating,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.video.type == VideoType.movie &&
                    widget.video.duration != null)
                  Text(
                    _formatDuration(widget.video.duration!),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  )
                else if (widget.video.isSeries)
                  Text(
                    '${widget.video.totalEpisodes ?? ''} 集',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(width: 8),
                if (widget.video.isTopTen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    color: AppTheme.primaryRed,
                    child: const Text(
                      'TOP 10',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: widget.video.genres.take(4).map((g) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (g != widget.video.genres.take(4).last)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(hasLabel ? 24 : 999),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Ink(
          padding: EdgeInsets.all(hasLabel ? 8 : 10),
          decoration: ShapeDecoration(
            shape: shape,
            color: filled ? AppTheme.textPrimary : Colors.white12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: filled ? Colors.black : AppTheme.textPrimary,
                size: 20,
              ),
              if (hasLabel) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: TextStyle(
                    color: filled ? Colors.black : AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MyListButton extends ConsumerWidget {
  final String videoId;
  const _MyListButton({required this.videoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inList = ref.watch(isInMyListProvider(videoId));
    return _ActionButton(
      icon: inList ? Icons.check_rounded : Icons.add_rounded,
      onTap: () {
        ref.read(toggleMyListProvider.notifier).toggle(videoId);
      },
    );
  }
}

class _RankBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.backgroundDark
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(48, 0)
      ..quadraticBezierTo(24, size.height * 0.12, 0, size.height * 0.28)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
