import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/dashboard_stats.dart';

class MockLineChart extends StatelessWidget {
  final List<DailyDataPoint> data;
  final String title;
  final String? unit;
  final Color lineColor;
  final double height;
  final bool showAxis;

  const MockLineChart({
    super.key,
    required this.data,
    required this.title,
    this.unit,
    this.lineColor = AppTheme.primaryRed,
    this.height = 200,
    this.showAxis = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (unit != null)
                Text(
                  '单位: $unit',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                points: data,
                lineColor: lineColor,
                showAxis: showAxis,
              ),
            ),
          ),
          if (showAxis) _buildXAxisLabels(),
        ],
      ),
    );
  }

  Widget _buildXAxisLabels() {
    final len = data.length;
    final step = len <= 7
        ? 1
        : len <= 14
            ? 2
            : len <= 30
                ? 5
                : 7;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: List.generate(len, (i) {
          bool show = i % step == 0 || i == len - 1;
          return Expanded(
            child: Text(
              show ? _formatDate(data[i].date) : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return '今';
    if (diff == 1) return '昨';
    if (diff < 7) return '$diff天前';
    return '${d.month}/${d.day}';
  }
}

class _LineChartPainter extends CustomPainter {
  final List<DailyDataPoint> points;
  final Color lineColor;
  final bool showAxis;

  _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.showAxis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final padding = showAxis
        ? const EdgeInsets.only(left: 36, right: 10, top: 8, bottom: 8)
        : const EdgeInsets.all(4);
    final plotW = size.width - padding.left - padding.right;
    final plotH = size.height - padding.top - padding.bottom;

    final values = points.map((e) => e.value).toList();
    final maxV = values.reduce((a, b) => a > b ? a : b) * 1.15;
    final minV = 0.0;
    final range = maxV - minV > 0 ? maxV - minV : 1;

    final stepX = points.length == 1 ? 0.0 : plotW / (points.length - 1);

    double xFor(int i) => padding.left + i * stepX;
    double yFor(double v) =>
        padding.top + plotH - ((v - minV) / range) * plotH;

    // Grid
    if (showAxis) {
      final gridPaint = Paint()
        ..color = AppTheme.divider.withOpacity(0.8)
        ..strokeWidth = 1;
      final labelStyle = const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 9,
      );
      for (int i = 0; i <= 4; i++) {
        final y = padding.top + (plotH * i / 4);
        canvas.drawLine(
          Offset(padding.left, y),
          Offset(padding.left + plotW, y),
          gridPaint,
        );
        final v = maxV - (range * i / 4);
        final label = _formatNum(v);
        final tp = TextPainter(
          text: TextSpan(text: label, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(2, y - tp.height / 2));
      }
    }

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(xFor(0), padding.top + plotH);
    for (int i = 0; i < points.length; i++) {
      final x = xFor(i);
      final y = yFor(points[i].value);
      if (i == 0) {
        fillPath.lineTo(x, y);
      } else {
        final prevX = xFor(i - 1);
        final prevY = yFor(points[i - 1].value);
        final cpx = (prevX + x) / 2;
        fillPath.cubicTo(cpx, prevY, cpx, y, x, y);
      }
    }
    fillPath.lineTo(xFor(points.length - 1), padding.top + plotH);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withOpacity(0.35),
        lineColor.withOpacity(0.0),
      ],
    );
    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient.createShader(
        Rect.fromLTWH(padding.left, padding.top, plotW, plotH),
      ),
    );

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = xFor(i);
      final y = yFor(points[i].value);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        final prevX = xFor(i - 1);
        final prevY = yFor(points[i - 1].value);
        final cpx = (prevX + x) / 2;
        linePath.cubicTo(cpx, prevY, cpx, y, x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotPaintInner = Paint()
      ..color = AppTheme.surfaceDark
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final x = xFor(i);
      final y = yFor(points[i].value);
      canvas.drawCircle(Offset(x, y), 3.8, dotPaint);
      canvas.drawCircle(Offset(x, y), 1.5, dotPaintInner);
    }
  }

  String _formatNum(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    } else if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    } else if (v >= 100) {
      return v.toStringAsFixed(0);
    } else {
      return v.toStringAsFixed(0);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) {
    return old.points.length != points.length ||
        old.lineColor != lineColor;
  }
}

class MockPieChart extends StatelessWidget {
  final Map<String, PieSlice> slices;
  final String title;
  final double size;

  const MockPieChart({
    super.key,
    required this.slices,
    required this.title,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.values.fold<double>(0, (a, b) => a + b.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _PiePainter(slices: slices, total: total),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: slices.entries.map((e) {
                    final pct = total == 0
                        ? 0.0
                        : (e.value.value / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.value.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PieSlice {
  final double value;
  final Color color;
  const PieSlice(this.value, this.color);
}

class _PiePainter extends CustomPainter {
  final Map<String, PieSlice> slices;
  final double total;

  _PiePainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty || total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final innerR = radius * 0.62;

    double start = -90.0;
    slices.forEach((_, slice) {
      final sweep = total > 0 ? (slice.value / total) * 360 : 0;
      if (sweep <= 0) return;
      final path = Path();
      final startRad = start * math.pi / 180;
      final endRad = (start + sweep) * math.pi / 180;
      path.moveTo(
        center.dx + radius * math.cos(startRad),
        center.dy + radius * math.sin(startRad),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startRad,
        endRad - startRad,
        false,
      );
      path.lineTo(
        center.dx + innerR * math.cos(endRad),
        center.dy + innerR * math.sin(endRad),
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerR),
        endRad,
        startRad - endRad,
        true,
      );
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      start += sweep;
    });

    // Center text
    final totalStr = total >= 1000
        ? '${(total / 1000).toStringAsFixed(1)}k'
        : total.toStringAsFixed(0);
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: totalStr,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(
            text: '\n总计',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) {
    return old.total != total || old.slices.length != slices.length;
  }
}
