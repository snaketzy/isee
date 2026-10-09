import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/media_upload_task.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../widgets/stat_card.dart';
import '../widgets/mock_line_chart.dart';
import '../widgets/data_table.dart';
import '../widgets/upload_progress_tile.dart';

final _dashboardProvider = Provider<DashboardData>((ref) {
  return AdminMockRepository.instance.getDashboardData();
});

final _recentUploadsProvider = Provider<List<MediaUploadTask>>((ref) {
  return AdminMockRepository.instance
      .getAllUploadTasks()
      .where((t) => !t.stage.isCompleted)
      .take(5)
      .toList();
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_dashboardProvider);
    final uploads = ref.watch(_recentUploadsProvider);
    final fmt = NumberFormat('#,##0', 'zh_CN');
    final moneyFmt = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: '¥',
      decimalDigits: 0,
    );
    final overview = data.overview;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(context, fmt),
          const SizedBox(height: 24),
          _buildStatGrid(fmt, moneyFmt, context, overview),
          const SizedBox(height: 24),
          _buildChartsRow(data),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildTopContentTable(data.topContentThisWeek, fmt),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildRecentActivity(data.recentActivity),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildUploadQueueSection(context, uploads),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, NumberFormat fmt) {
    final repo = AdminMockRepository.instance;
    final stats = repo.getDashboardData().overview;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryRed.withOpacity(0.18),
            AppTheme.surfaceDark,
            AppTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '早上好，欢迎回来 👋',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'iSEE 流媒体运营控制台',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '实时监控内容表现、用户增长与收入数据，快速处理上传队列与运营任务。',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '系统运行正常',
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '待处理任务：${stats.pendingUploads + stats.transcodingTasks}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(
    NumberFormat fmt,
    NumberFormat moneyFmt,
    BuildContext context,
    DashboardOverviewStats o,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1400
            ? 4
            : constraints.maxWidth > 900
                ? 2
                : 1;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '总内容数',
                value: fmt.format(o.totalContent),
                subtitle: '新增：+${o.totalContentTrend.value.toInt()} 本月',
                icon: Icons.movie_creation_rounded,
                trend: o.totalContentTrend,
                accentColor: const Color(0xFF60A5FA),
                onTap: () => context.go('/admin/content'),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '总用户数',
                value: fmt.format(o.totalUsers),
                subtitle: '今日活跃：${fmt.format(o.activeUsersToday)}',
                icon: Icons.people_alt_rounded,
                trend: o.totalUsersTrend,
                accentColor: const Color(0xFF4ADE80),
                onTap: () => context.go('/admin/users'),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '今日播放次数',
                value: fmt.format(o.todayPlays),
                subtitle: '转码任务：${o.transcodingTasks}',
                icon: Icons.play_circle_fill_rounded,
                trend: o.todayPlaysTrend,
                accentColor: const Color(0xFFF59E0B),
                onTap: () => context.go('/admin/analytics'),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '本月收入',
                value: moneyFmt.format(o.monthlyRevenue),
                subtitle: '待上传：${o.pendingUploads} 项',
                icon: Icons.payments_rounded,
                trend: o.monthlyRevenueTrend,
                accentColor: AppTheme.primaryRed,
                onTap: () => context.go('/admin/membership'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsRow(DashboardData data) {
    final mem = data.charts.membershipDistribution;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 1200;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: MockLineChart(
                  title: '近 30 天播放量趋势',
                  unit: '次',
                  data: data.charts.playsLast30Days,
                  height: 220,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: MockPieChart(
                  size: 180,
                  title: '会员等级分布',
                  slices: {
                    '基础版': PieSlice(
                      (mem[MembershipTier.basic] ?? 0).toDouble(),
                      const Color(0xFF60A5FA),
                    ),
                    '标准版': PieSlice(
                      (mem[MembershipTier.standard] ?? 0).toDouble(),
                      const Color(0xFFA78BFA),
                    ),
                    '高级版': PieSlice(
                      (mem[MembershipTier.premium] ?? 0).toDouble(),
                      AppTheme.primaryRed,
                    ),
                  },
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            MockLineChart(
              title: '近 30 天播放量趋势',
              unit: '次',
              data: data.charts.playsLast30Days,
              height: 200,
            ),
            const SizedBox(height: 20),
            MockLineChart(
              title: '近 7 天新增用户',
              unit: '人',
              data: data.charts.newUsersLast7Days,
              lineColor: const Color(0xFF4ADE80),
              height: 200,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopContentTable(List<TopContentItem> items, NumberFormat fmt) {
    return AdminDataTable<TopContentItem>(
      headerTitle: '本周热播 Top 10',
      headerAction: TextButton(
        onPressed: () {},
        child: const Text('查看全部 →'),
      ),
      items: items,
      selectable: false,
      columns: const [
        DataColumnSpec(label: '排名', width: 64, numeric: true),
        DataColumnSpec(label: '标题'),
        DataColumnSpec(
          label: '播放次数',
          numeric: true,
        ),
        DataColumnSpec(label: '观看时长', numeric: true),
        DataColumnSpec(label: '完播率', numeric: true),
      ],
      rowBuilder: (ctx, item, _) {
        final idx = items.indexOf(item) + 1;
        Color rankColor = AppTheme.textMuted;
        if (idx == 1) rankColor = const Color(0xFFFBBF24);
        if (idx == 2) rankColor = const Color(0xFFC0C0C0);
        if (idx == 3) rankColor = const Color(0xFFCD7F32);
        return DataRow(cells: [
          DataCell(
            Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: idx <= 3 ? rankColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: idx <= 3
                      ? Border.all(color: rankColor.withOpacity(0.5))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$idx',
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    item.posterUrl,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 56,
                      color: AppTheme.surfaceLight,
                      child: const Icon(Icons.movie,
                          color: AppTheme.textMuted, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          DataTextCell(fmt.format(item.playCount), numeric: true),
          DataTextCell(
            '${(item.watchMinutes / 60).toStringAsFixed(0)}h',
            numeric: true,
          ),
          DataCell(
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(item.completionRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.completionRate,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor: AlwaysStoppedAnimation(item.completionRate > 0.7
                            ? const Color(0xFF4ADE80)
                            : AppTheme.primaryRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildRecentActivity(List<RecentActivityItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                '最近动态',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Icon(Icons.more_horiz_rounded, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((e) {
            final i = e.value;
            Color iconColor;
            IconData iconData;
            switch (i.type) {
              case 'content':
                iconColor = const Color(0xFF60A5FA);
                iconData = Icons.movie_creation_rounded;
                break;
              case 'upload':
                iconColor = const Color(0xFFF59E0B);
                iconData = Icons.cloud_upload_rounded;
                break;
              case 'user':
                iconColor = const Color(0xFF4ADE80);
                iconData = Icons.person_add_rounded;
                break;
              case 'subscription':
                iconColor = AppTheme.primaryRed;
                iconData = Icons.payments_rounded;
                break;
              case 'system':
              default:
                iconColor = AppTheme.textMuted;
                iconData = Icons.settings_system_daydream_rounded;
                break;
            }
            final last = e.key == items.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconData, color: iconColor, size: 16),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i.description,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _timeAgo(i.time),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            if (i.actorName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  i.actorName!,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildUploadQueueSection(BuildContext context, List<MediaUploadTask> uploads) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_queue_rounded,
                  color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              const Text(
                '上传队列（进行中）',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${uploads.length} 项',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('上传新视频'),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => context.go('/admin/upload'),
                child: const Text('查看全部队列 →'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (uploads.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '暂无进行中的上传任务',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...List.generate(uploads.length, (i) {
              return Padding(
                padding: i == uploads.length - 1
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 12),
                child: UploadProgressTile(
                  task: uploads[i],
                  onViewLogs: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('查看 ${uploads[i].fileName} 日志'),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return '刚刚';
    if (d.inMinutes < 60) return '${d.inMinutes} 分钟前';
    if (d.inHours < 24) return '${d.inHours} 小时前';
    if (d.inDays < 30) return '${d.inDays} 天前';
    return '${t.month}/${t.day}';
  }
}
