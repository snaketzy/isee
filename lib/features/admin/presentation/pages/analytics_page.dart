import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../widgets/data_table.dart';
import '../widgets/mock_line_chart.dart';

final _analyticsProvider = Provider<AnalyticsData>((ref) {
  return AdminMockRepository.instance.getAnalyticsData();
});

class AnalyticsPage extends ConsumerStatefulWidget {
  final String? id;
  const AnalyticsPage({super.key, this.id});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '数据分析',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '内容、用户、收入与观看行为全景分析',
                style:
                    TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: false,
                  labelColor: AppTheme.textPrimary,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400),
                  indicator: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryRed.withOpacity(0.4)),
                  ),
                  indicatorPadding: const EdgeInsets.all(4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: const EdgeInsets.symmetric(vertical: 4),
                  tabs: const [
                    Tab(text: '内容表现'),
                    Tab(text: '用户增长'),
                    Tab(text: '收入分析'),
                    Tab(text: '观看行为'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ContentPerformanceTab(),
              _UserGrowthTab(),
              _RevenueTab(),
              _WatchBehaviorTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============ Helper widgets ============

Widget _buildSectionCard({
  required Widget child,
  String? title,
  Widget? subtitle,
  double? height,
}) {
  return Container(
    constraints: height != null ? BoxConstraints(minHeight: height) : null,
    decoration: BoxDecoration(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  subtitle,
                ],
              ],
            ),
          ),
        if (title != null)
          const Divider(height: 1, color: AppTheme.divider),
        Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ],
    ),
  );
}

// ============ 1. Content Performance ============

class _ContentPerformanceTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_analyticsProvider);
    final numFmt = NumberFormat('#,##0', 'zh_CN');

    // Category comparison line chart - flatten categories
    final cats = data.categoryPlays30d;
    final catKeys = cats.isNotEmpty ? cats.first.byCategory.keys.toList() : <String>[];
    final catColors = [
      AppTheme.primaryRed,
      const Color(0xFF60A5FA),
      const Color(0xFF4ADE80),
      const Color(0xFFF59E0B),
      const Color(0xFFA78BFA),
      const Color(0xFFF472B6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          AdminDataTable<TopContentItem>(
            headerTitle: 'Top 10 热播内容',
            headerAction: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterChip('全部分类', true),
                const SizedBox(width: 8),
                _buildFilterChip('近 30 天', true, outlined: false),
              ],
            ),
            items: data.topContentList,
            selectable: false,
            columns: const [
              DataColumnSpec(label: '排名', width: 60, numeric: true),
              DataColumnSpec(label: '内容'),
              DataColumnSpec(label: '播放量', numeric: true),
              DataColumnSpec(label: '观看时长(h)', numeric: true),
              DataColumnSpec(label: '完播率', numeric: true),
            ],
            rowBuilder: (ctx, item, _) {
              final idx = data.topContentList.indexOf(item) + 1;
              Color rankColor = AppTheme.textMuted;
              if (idx == 1) rankColor = const Color(0xFFFBBF24);
              if (idx == 2) rankColor = const Color(0xFFC0C0C0);
              if (idx == 3) rankColor = const Color(0xFFCD7F32);
              return DataRow(cells: [
                DataCell(Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: idx <= 3
                          ? rankColor.withOpacity(0.15)
                          : Colors.transparent,
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
                )),
                DataCell(Row(
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
                )),
                DataTextCell(numFmt.format(item.playCount), numeric: true),
                DataTextCell(
                    (item.watchMinutes / 60).toStringAsFixed(1),
                    numeric: true),
                DataCell(Padding(
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
                            valueColor: AlwaysStoppedAnimation(
                                item.completionRate > 0.7
                                    ? const Color(0xFF4ADE80)
                                    : AppTheme.primaryRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ]);
            },
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: '30 天各分类播放量对比',
            child: _buildMultiLineChart(
              cats,
              catKeys,
              catColors,
            ),
            height: 320,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected,
      {bool outlined = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.surfaceLight
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(6),
        border: outlined
            ? Border.all(color: AppTheme.divider)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? AppTheme.textPrimary
              : AppTheme.textMuted,
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildMultiLineChart(
    List<CategoryPlaysPoint> data,
    List<String> keys,
    List<Color> colors,
  ) {
    if (data.isEmpty || keys.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child:
              Text('No data', style: TextStyle(color: AppTheme.textMuted)),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: CustomPaint(
            painter: _MultiLinePainter(
              data: data,
              keys: keys,
              colors: colors,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: keys.asMap().entries.map((e) {
            final i = e.key;
            final k = e.value;
            final c = colors[i % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  k,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11.5),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MultiLinePainter extends CustomPainter {
  final List<CategoryPlaysPoint> data;
  final List<String> keys;
  final List<Color> colors;

  _MultiLinePainter({
    required this.data,
    required this.keys,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.only(left: 44, right: 10, top: 8, bottom: 20);
    final plotW = size.width - padding.left - padding.right;
    final plotH = size.height - padding.top - padding.bottom;

    // compute max value across all
    double maxV = 0;
    for (final d in data) {
      for (final k in keys) {
        maxV = math.max(maxV, d.byCategory[k] ?? 0);
      }
    }
    maxV = maxV * 1.15;

    // grid
    final gridPaint = Paint()
      ..color = AppTheme.divider.withOpacity(0.8)
      ..strokeWidth = 1;
    final labelStyle =
        const TextStyle(color: AppTheme.textMuted, fontSize: 9);
    for (int i = 0; i <= 4; i++) {
      final y = padding.top + (plotH * i / 4);
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(padding.left + plotW, y),
        gridPaint,
      );
      final v = maxV - (maxV * i / 4);
      final str = v >= 1000
          ? '${(v / 1000).toStringAsFixed(1)}k'
          : v.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: str, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    final stepX = data.length == 1 ? 0.0 : plotW / (data.length - 1);
    double xFor(int i) => padding.left + i * stepX;
    double yFor(double v) =>
        padding.top + plotH - ((v) / maxV) * plotH;

    // draw each line
    for (int ki = 0; ki < keys.length; ki++) {
      final k = keys[ki];
      final color = colors[ki % colors.length];
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      final path = Path();
      for (int i = 0; i < data.length; i++) {
        final x = xFor(i);
        final y = yFor(data[i].byCategory[k] ?? 0);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
    }

    // x-axis labels
    final len = data.length;
    final step = len <= 7
        ? 1
        : len <= 14
            ? 2
            : 5;
    final bottomY = padding.top + plotH;
    for (int i = 0; i < len; i++) {
      final show = i % step == 0 || i == len - 1;
      if (!show) continue;
      final d = data[i].date;
      final diff = DateTime.now().difference(d).inDays;
      final label = diff == 0
          ? '今'
          : diff == 1
              ? '昨'
              : diff < 7
                  ? '$diff天'
                  : '${d.month}/${d.day}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final x = xFor(i);
      tp.paint(canvas, Offset(x - tp.width / 2, bottomY + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLinePainter old) => true;
}

// ============ 2. User Growth ============

class _UserGrowthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_analyticsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 1100;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: MockLineChart(
                        title: '新增用户（30 天）',
                        unit: '人',
                        data: data.newUsers30d,
                        height: 240,
                        lineColor: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildSectionCard(
                        title: '7 日留存率',
                        subtitle: const Text(
                          '新用户后续 7 天回访情况',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11.5),
                        ),
                        child: _RetentionBarChart(points: data.retention7d),
                        height: 260,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  MockLineChart(
                    title: '新增用户（30 天）',
                    unit: '人',
                    data: data.newUsers30d,
                    height: 220,
                    lineColor: const Color(0xFF4ADE80),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '7 日留存率',
                    child: _RetentionBarChart(points: data.retention7d),
                    height: 240,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: '转化漏斗：注册 → 首看 → 订阅 → 续费',
            subtitle: Text(
              '漏斗共 4 阶段，总转化率 ${(data.conversionFunnel.last.value / data.conversionFunnel.first.value * 100).toStringAsFixed(1)}%',
              style:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
            ),
            child: _FunnelChart(stages: data.conversionFunnel),
            height: 320,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RetentionBarChart extends StatelessWidget {
  final List<RetentionDayPoint> points;
  const _RetentionBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _RetentionPainter(points: points),
      ),
    );
  }
}

class _RetentionPainter extends CustomPainter {
  final List<RetentionDayPoint> points;
  _RetentionPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.only(left: 36, right: 10, top: 8, bottom: 28);
    final plotW = size.width - padding.left - padding.right;
    final plotH = size.height - padding.top - padding.bottom;
    final n = points.length;
    final barGap = 12.0;
    final barW = n > 0 ? (plotW - barGap * (n - 1)) / n : 0.0;

    // grid
    final grid = Paint()
      ..color = AppTheme.divider.withOpacity(0.6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding.top + plotH * i / 4;
      canvas.drawLine(Offset(padding.left, y),
          Offset(padding.left + plotW, y), grid);
      final v = 100 - (100 * i / 4);
      final tp = TextPainter(
        text: TextSpan(
            text: '${v.toStringAsFixed(0)}%',
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 9)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    // bars
    for (int i = 0; i < n; i++) {
      final p = points[i];
      final x = padding.left + i * (barW + barGap);
      final barH = p.rate * plotH;
      final y = padding.top + plotH - barH;
      final grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4ADE80),
          const Color(0xFF4ADE80).withOpacity(0.3),
        ],
      );
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rrect,
        Paint()..shader = grad.createShader(Rect.fromLTWH(x, y, barW, barH)),
      );
      // label top
      final pct = '${(p.rate * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
            text: pct,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, y - 14));
      // x label
      final tp2 = TextPainter(
        text: TextSpan(
            text: 'D${p.day}',
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 10)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp2.paint(canvas,
          Offset(x + barW / 2 - tp2.width / 2, padding.top + plotH + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _RetentionPainter old) => true;
}

class _FunnelChart extends StatelessWidget {
  final List<FunnelStage> stages;
  const _FunnelChart({required this.stages});

  @override
  Widget build(BuildContext context) {
    final numFmt = NumberFormat('#,##0', 'zh_CN');
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 600;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 240,
                  child: CustomPaint(
                    painter: _FunnelPainter(stages: stages),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  children: stages.asMap().entries.map((e) {
                    final i = e.key;
                    final s = e.value;
                    final prev = i > 0 ? stages[i - 1].value : s.value;
                    final conv = i == 0
                        ? 1.0
                        : stages[i].value / stages[i - 1].value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.label,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${numFmt.format(s.value)} 人'
                                  '${i > 0 ? ' · 转化 ${(conv * 100).toStringAsFixed(1)}%' : ''}',
                                  style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _FunnelPainter(stages: stages),
              ),
            ),
            const SizedBox(height: 12),
            ...stages.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${i + 1}. ${s.label}：${numFmt.format(s.value)} 人',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FunnelPainter extends CustomPainter {
  final List<FunnelStage> stages;
  _FunnelPainter({required this.stages});

  @override
  void paint(Canvas canvas, Size size) {
    if (stages.isEmpty) return;
    final maxV = stages.first.value;
    const colors = [
      Color(0xFFE50914),
      Color(0xFFF59E0B),
      Color(0xFFA78BFA),
      Color(0xFF4ADE80),
    ];
    final stageH = size.height / stages.length * 0.85;
    final gap = size.height / stages.length * 0.15;

    for (int i = 0; i < stages.length; i++) {
      final s = stages[i];
      final ratio = s.value / maxV;
      final y = i * (stageH + gap);
      final topW = size.width *
          (i == 0 ? ratio : stages[i - 1].value / maxV);
      final botW = size.width * ratio;
      final topX = (size.width - topW) / 2;
      final botX = (size.width - botW) / 2;
      final path = Path()
        ..moveTo(topX, y)
        ..lineTo(topX + topW, y)
        ..lineTo(botX + botW, y + stageH)
        ..lineTo(botX, y + stageH)
        ..close();
      final c = colors[i % colors.length];
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.withOpacity(0.85), c.withOpacity(0.55)],
          ).createShader(Rect.fromLTWH(0, y, size.width, stageH)),
      );
      // label
      final pct = i == 0
          ? '100%'
          : '${(s.value / stages[i - 1].value * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${s.label}\n',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text:
                  '${NumberFormat('#,##0', 'zh_CN').format(s.value)} · $pct',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 10.5),
            ),
          ],
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          size.width / 2 - tp.width / 2,
          y + stageH / 2 - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FunnelPainter old) => true;
}

// ============ 3. Revenue ============

class _RevenueTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_analyticsProvider);
    final mem = data.planDistribution;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          MockLineChart(
            title: '30 天收入趋势',
            unit: '¥',
            data: data.revenue30d,
            height: 240,
            lineColor: AppTheme.primaryRed,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 1100;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: MockLineChart(
                        title: 'ARPU 趋势（月均收入 / 用户）',
                        unit: '¥',
                        data: data.arpuTrend,
                        height: 220,
                        lineColor: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: MockPieChart(
                        size: 180,
                        title: '套餐分布（订阅人数）',
                        slices: {
                          '基础版': PieSlice(
                            (mem[MembershipTier.basic] ?? 0)
                                .toDouble(),
                            const Color(0xFF60A5FA),
                          ),
                          '标准版': PieSlice(
                            (mem[MembershipTier.standard] ?? 0)
                                .toDouble(),
                            const Color(0xFFA78BFA),
                          ),
                          '高级版': PieSlice(
                            (mem[MembershipTier.premium] ?? 0)
                                .toDouble(),
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
                    title: 'ARPU 趋势（月均收入 / 用户）',
                    unit: '¥',
                    data: data.arpuTrend,
                    height: 220,
                    lineColor: const Color(0xFF4ADE80),
                  ),
                  const SizedBox(height: 20),
                  MockPieChart(
                    size: 180,
                    title: '套餐分布（订阅人数）',
                    slices: {
                      '基础版': PieSlice(
                        (mem[MembershipTier.basic] ?? 0).toDouble(),
                        const Color(0xFF60A5FA),
                      ),
                      '标准版': PieSlice(
                        (mem[MembershipTier.standard] ?? 0)
                            .toDouble(),
                        const Color(0xFFA78BFA),
                      ),
                      '高级版': PieSlice(
                        (mem[MembershipTier.premium] ?? 0).toDouble(),
                        AppTheme.primaryRed,
                      ),
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ============ 4. Watch Behavior ============

class _WatchBehaviorTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_analyticsProvider);
    final dev = data.deviceDistribution;
    final devTotal = dev.values.fold<int>(0, (a, b) => a + b);
    final devColors = const [
      Color(0xFF60A5FA),
      Color(0xFF4ADE80),
      Color(0xFFF59E0B),
      Color(0xFFA78BFA),
      Color(0xFFF472B6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          MockLineChart(
            title: '平均观影时长 / 日（30 天）',
            unit: '分钟',
            data: data.avgWatchMinutesDaily,
            height: 220,
            lineColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 1100;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: MockPieChart(
                        size: 180,
                        title: '终端设备分布（$devTotal 会话）',
                        slices: Map.fromIterables(
                          dev.keys,
                          dev.values.toList().asMap().entries.map((e) => PieSlice(
                                e.value.toDouble(),
                                devColors[e.key % devColors.length],
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildSectionCard(
                        title: '24 小时活跃时段分布',
                        subtitle: const Text(
                          '按小时统计活跃用户数',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11.5),
                        ),
                        child: _HourlyBarChart(
                            points: data.hourDistribution24h),
                        height: 260,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  MockPieChart(
                    size: 180,
                    title: '终端设备分布',
                    slices: Map.fromIterables(
                      dev.keys,
                      dev.values.toList().asMap().entries.map((e) => PieSlice(
                            e.value.toDouble(),
                            devColors[e.key % devColors.length],
                          )),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '24 小时活跃时段分布',
                    child: _HourlyBarChart(points: data.hourDistribution24h),
                    height: 260,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HourlyBarChart extends StatelessWidget {
  final List<HourDistributionPoint> points;
  const _HourlyBarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _HourlyPainter(points: points),
      ),
    );
  }
}

class _HourlyPainter extends CustomPainter {
  final List<HourDistributionPoint> points;
  _HourlyPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.only(left: 40, right: 10, top: 8, bottom: 28);
    final plotW = size.width - padding.left - padding.right;
    final plotH = size.height - padding.top - padding.bottom;
    final n = points.length;
    final barW = n > 0 ? plotW / n - 2 : 0.0;
    final maxV = points.fold<double>(
        0, (a, b) => math.max(a, b.value)) * 1.15;

    // grid
    final grid = Paint()
      ..color = AppTheme.divider.withOpacity(0.6)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding.top + plotH * i / 4;
      canvas.drawLine(Offset(padding.left, y),
          Offset(padding.left + plotW, y), grid);
      final v = maxV - (maxV * i / 4);
      final str = v >= 1000
          ? '${(v / 1000).toStringAsFixed(1)}k'
          : v.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(
            text: str,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 9)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }

    // bars
    for (int i = 0; i < n; i++) {
      final p = points[i];
      final x = padding.left + i * (barW + 2);
      final barH = (p.value / maxV) * plotH;
      final y = padding.top + plotH - barH;
      final isPeak = p.value ==
          points.fold<double>(
              0, (a, b) => math.max(a, b.value));
      final color = isPeak ? AppTheme.primaryRed : const Color(0xFFF59E0B);
      final grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withOpacity(0.45)],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, barH),
          Radius.circular(2),
        ),
        Paint()
          ..shader = grad.createShader(Rect.fromLTWH(x, y, barW, barH)),
      );
      // x label
      if (i % 3 == 0 || i == n - 1) {
        final tp2 = TextPainter(
          text: TextSpan(
              text: '${p.hour}:00',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 9)),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp2.paint(canvas,
            Offset(x + barW / 2 - tp2.width / 2, padding.top + plotH + 8));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyPainter old) => true;
}
