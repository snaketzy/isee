import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/models/video_quality.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../widgets/stat_card.dart';

final _plansProvider = StateProvider<List<MembershipPlan>>((ref) {
  return AdminMockRepository.instance.getMembershipPlans();
});

class MembershipPlansPage extends ConsumerStatefulWidget {
  final String? id;
  const MembershipPlansPage({super.key, this.id});

  @override
  ConsumerState<MembershipPlansPage> createState() =>
      _MembershipPlansPageState();
}

class _MembershipPlansPageState extends ConsumerState<MembershipPlansPage> {
  final Set<String> _editing = {};

  Color _tierColor(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.basic:
        return const Color(0xFF60A5FA);
      case MembershipTier.standard:
        return const Color(0xFFA78BFA);
      case MembershipTier.premium:
        return AppTheme.primaryRed;
    }
  }

  Gradient _tierGradient(MembershipTier tier) {
    final c = _tierColor(tier);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.withOpacity(0.35), c.withOpacity(0.04)],
    );
  }

  IconData _tierIcon(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.basic:
        return Icons.workspace_premium_outlined;
      case MembershipTier.standard:
        return Icons.star_rounded;
      case MembershipTier.premium:
        return Icons.diamond_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(_plansProvider);
    final users = AdminMockRepository.instance.getAllUsers();
    final moneyFmt = NumberFormat.currency(
        locale: 'zh_CN', symbol: '¥', decimalDigits: 0);
    final numFmt = NumberFormat('#,##0', 'zh_CN');

    // 统计
    final totalSubscribers = users.length;
    double totalMonthlyValue = 0;
    for (final u in users) {
      final plan = plans.where((p) => p.tier == u.membership.tier).firstOrNull;
      if (plan != null) totalMonthlyValue += plan.monthlyPrice;
    }
    final arpu = totalSubscribers > 0
        ? totalMonthlyValue / totalSubscribers
        : 0.0;
    final estMonthlyRevenue = totalMonthlyValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatsGrid(
              numFmt, moneyFmt, totalSubscribers, arpu, estMonthlyRevenue),
          const SizedBox(height: 24),
          const Text(
            '套餐配置',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 1200;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plans
                      .asMap()
                      .entries
                      .map((e) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: e.key == plans.length - 1 ? 0 : 16),
                            child: _buildPlanCard(
                              context,
                              e.value,
                              numFmt,
                            ),
                          ),
                        );
                      })
                      .toList(),
                );
              }
              return Column(
                children: plans
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlanCard(context, p, numFmt),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '会员套餐管理',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Icon(Icons.sync_rounded,
                  color: Color(0xFF4ADE80), size: 14),
              SizedBox(width: 6),
              Text(
                '已同步至前台订阅页',
                style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    NumberFormat numFmt,
    NumberFormat moneyFmt,
    int subscribers,
    double arpu,
    double monthlyRev,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1400
            ? 3
            : constraints.maxWidth > 900
                ? 3
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
                title: '总订阅人数',
                value: numFmt.format(subscribers),
                subtitle: '活跃订阅会员',
                icon: Icons.people_alt_rounded,
                accentColor: const Color(0xFF60A5FA),
                trend: const TrendData(
                  value: 8.4,
                  direction: TrendDirection.up,
                  changePercent: 8.4,
                ),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: 'ARPU (月)',
                value: moneyFmt.format(arpu),
                subtitle: '每用户平均收入',
                icon: Icons.show_chart_rounded,
                accentColor: const Color(0xFF4ADE80),
                trend: const TrendData(
                  value: 3.2,
                  direction: TrendDirection.up,
                  changePercent: 3.2,
                ),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '预估月收入',
                value: moneyFmt.format(monthlyRev),
                subtitle: '基于当前订阅',
                icon: Icons.payments_rounded,
                accentColor: AppTheme.primaryRed,
                trend: const TrendData(
                  value: 11.2,
                  direction: TrendDirection.up,
                  changePercent: 11.2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    MembershipPlan plan,
    NumberFormat numFmt,
  ) {
    final isEditing = _editing.contains(plan.id);
    final color = _tierColor(plan.tier);
    final editingCtrl =
        TextEditingController(text: plan.monthlyPrice.toStringAsFixed(0));
    final yearlyCtrl =
        TextEditingController(text: plan.yearlyPrice.toStringAsFixed(0));
    final devicesCtrl =
        TextEditingController(text: plan.maxDevices.toString());
    final downloadsCtrl =
        TextEditingController(text: plan.maxDownloads.toString());
    final descCtrl = TextEditingController(text: plan.description);
    final features = List<String>.from(plan.features);

    return StatefulBuilder(
      builder: (ctx, setState2) {
        return Container(
          decoration: BoxDecoration(
            gradient: _tierGradient(plan.tier),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            Icon(_tierIcon(plan.tier), color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  plan.name,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!plan.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.textMuted
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '已停用',
                                      style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan.tier.shortLabel,
                              style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: plan.isActive,
                        onChanged: isEditing
                            ? (v) {
                                setState2(() {
                                  final idx = ref
                                      .read(_plansProvider.notifier)
                                      .state
                                      .indexWhere((p) => p.id == plan.id);
                                  final list = List<MembershipPlan>.from(
                                      ref.read(_plansProvider.notifier).state);
                                  list[idx] = list[idx].copyWith(isActive: v);
                                  ref.read(_plansProvider.notifier).state =
                                      list;
                                });
                              }
                            : null,
                        activeColor: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price section
                  if (!isEditing)
                    _buildPriceDisplay(plan, color)
                  else
                    _buildPriceEditors(
                      plan,
                      editingCtrl,
                      yearlyCtrl,
                      devicesCtrl,
                      downloadsCtrl,
                      descCtrl,
                    ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 14),

                  // Features
                  Row(
                    children: [
                      const Text(
                        '权益列表',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                      ),
                      if (isEditing) ...[
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            setState2(() {
                              features.add('新权益');
                              final idx = ref
                                  .read(_plansProvider.notifier)
                                  .state
                                  .indexWhere((p) => p.id == plan.id);
                              final list = List<MembershipPlan>.from(
                                  ref.read(_plansProvider.notifier).state);
                              list[idx] = list[idx].copyWith(features: List<String>.from(features));
                              ref.read(_plansProvider.notifier).state =
                                  list;
                            });
                          },
                          icon: const Icon(Icons.add_rounded,
                              size: 18, color: AppTheme.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...features.asMap().entries.map((entry) {
                    final i = entry.key;
                    final f = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: color, size: 16),
                          const SizedBox(width: 8),
                          if (isEditing)
                            Expanded(
                              child: TextFormField(
                                initialValue: f,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12.5),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: AppTheme.surfaceLight,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                ),
                                onChanged: (v) {
                                  features[i] = v;
                                  final idx = ref
                                      .read(_plansProvider.notifier)
                                      .state
                                      .indexWhere((p) => p.id == plan.id);
                                  final list =
                                      List<MembershipPlan>.from(ref
                                          .read(_plansProvider.notifier)
                                          .state);
                                  list[idx] = list[idx].copyWith(
                                      features: List<String>.from(features));
                                  ref
                                      .read(_plansProvider.notifier)
                                      .state = list;
                                },
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                f,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12.5),
                              ),
                            ),
                          if (isEditing && features.length > 1)
                            IconButton(
                              onPressed: () {
                                setState2(() {
                                  features.removeAt(i);
                                  final idx = ref
                                      .read(_plansProvider.notifier)
                                      .state
                                      .indexWhere((p) => p.id == plan.id);
                                  final list =
                                      List<MembershipPlan>.from(ref
                                          .read(_plansProvider.notifier)
                                          .state);
                                  list[idx] = list[idx].copyWith(
                                      features: List<String>.from(features));
                                  ref
                                      .read(_plansProvider.notifier)
                                      .state = list;
                                });
                              },
                              icon: const Icon(Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFFF87171)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: isEditing
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _editing.remove(plan.id);
                                  });
                                  setState2(() {});
                                  ref
                                      .read(_plansProvider.notifier)
                                      .state = AdminMockRepository
                                          .instance
                                          .getMembershipPlans();
                                },
                                icon: const Icon(Icons.close_rounded,
                                    size: 16),
                                label: const Text('取消'),
                              )
                            : OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _editing.add(plan.id);
                                  });
                                },
                                icon: const Icon(Icons.edit_rounded,
                                    size: 16),
                                label: const Text('编辑'),
                              ),
                      ),
                      if (isEditing) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final list = ref.read(_plansProvider.notifier).state;
                              final updated = list.firstWhere(
                                  (p) => p.id == plan.id,
                                  orElse: () => plan);
                              try {
                                final newMonthly = double.parse(editingCtrl.text
                                    .trim()
                                    .replaceAll(RegExp(r'[^0-9.]'), ''));
                                final newYearly = double.parse(yearlyCtrl.text
                                    .trim()
                                    .replaceAll(RegExp(r'[^0-9.]'), ''));
                                final newDevices = int.parse(devicesCtrl.text
                                    .trim()
                                    .replaceAll(RegExp(r'[^0-9]'), ''));
                                final newDownloads = int.parse(
                                    downloadsCtrl.text
                                        .trim()
                                        .replaceAll(RegExp(r'[^0-9]'), ''));
                                final toSave = updated.copyWith(
                                  monthlyPrice: newMonthly,
                                  yearlyPrice: newYearly,
                                  maxDevices: newDevices,
                                  maxDownloads: newDownloads,
                                  description: descCtrl.text,
                                );
                                AdminMockRepository.instance
                                    .updateMembershipPlan(toSave);
                                ref
                                    .read(_plansProvider.notifier)
                                    .state = AdminMockRepository
                                        .instance
                                        .getMembershipPlans();
                                setState(() {
                                  _editing.remove(plan.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF4ADE80),
                                    content: Text(
                                      '${plan.name} 已保存，前台订阅页已同步',
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('请检查输入格式：$e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.save_rounded,
                                size: 16),
                            label: const Text('保存'),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceDisplay(MembershipPlan plan, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text('¥',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 2),
            Text(
              plan.monthlyPrice.toStringAsFixed(0),
              style: TextStyle(
                  color: color,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1),
            ),
            const SizedBox(width: 4),
            const Text('/ 月',
                style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '年费 ¥${plan.yearlyPrice.toStringAsFixed(0)}（省 ¥${(plan.monthlyPrice * 12 - plan.yearlyPrice).toStringAsFixed(0)}）',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 14),
        _buildMetaInfoRow(Icons.hd_rounded, '最高画质',
            plan.maxQuality.label),
        const SizedBox(height: 8),
        _buildMetaInfoRow(Icons.devices_rounded, '并发设备',
            '${plan.maxDevices} 台'),
        const SizedBox(height: 8),
        _buildMetaInfoRow(Icons.download_rounded, '离线下载',
            '${plan.maxDownloads} 台设备'),
        const SizedBox(height: 8),
        _buildMetaInfoRow(Icons.notes_rounded, '套餐说明',
            plan.description, multi: true),
      ],
    );
  }

  Widget _buildPriceEditors(
    MembershipPlan plan,
    TextEditingController monthCtrl,
    TextEditingController yearCtrl,
    TextEditingController devicesCtrl,
    TextEditingController downloadsCtrl,
    TextEditingController descCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumField('月费 (¥)', monthCtrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumField('年费 (¥)', yearCtrl),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildNumField('并发设备', devicesCtrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildNumField('下载数', downloadsCtrl),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQualitySelector(plan),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '套餐说明',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: descCtrl,
              maxLines: 2,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 12.5),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style:
              const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySelector(MembershipPlan plan) {
    final colors = [
      VideoQuality.q720p,
      VideoQuality.q1080p,
      VideoQuality.q4k,
    ];
    return StatefulBuilder(
      builder: (ctx, setState2) {
        MembershipPlan current;
        try {
          current = ref.watch(_plansProvider.notifier).state.firstWhere(
              (p) => p.id == plan.id,
              orElse: () => plan);
        } catch (_) {
          current = plan;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最高画质',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              children: colors.map((q) {
                final selected = current.maxQuality == q;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: q == colors.last ? 0 : 6),
                    child: InkWell(
                      onTap: () {
                        final idx = ref
                            .read(_plansProvider.notifier)
                            .state
                            .indexWhere((p) => p.id == plan.id);
                        final list = List<MembershipPlan>.from(
                            ref.read(_plansProvider.notifier).state);
                        list[idx] = list[idx].copyWith(maxQuality: q);
                        ref.read(_plansProvider.notifier).state = list;
                        setState2(() {});
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryRed.withOpacity(0.2)
                              : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryRed.withOpacity(0.6)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          q.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetaInfoRow(IconData icon, String label, String value,
      {bool multi = false}) {
    return Row(
      crossAxisAlignment:
          multi ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 12.5),
            maxLines: multi ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
