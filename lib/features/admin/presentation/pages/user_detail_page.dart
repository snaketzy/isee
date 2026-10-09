import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/data/mock_data.dart';
import '../../../../../core/models/video_quality.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../widgets/mock_line_chart.dart';

final _userByIdProvider =
    Provider.family<UserProfile?, String>((ref, id) {
  return AdminMockRepository.instance.getUserById(id);
});

class UserDetailPage extends ConsumerWidget {
  final String? id;
  const UserDetailPage({super.key, this.id});

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

  Color _eventColor(String type) {
    switch (type) {
      case 'subscribe':
        return const Color(0xFF4ADE80);
      case 'renew':
        return const Color(0xFF60A5FA);
      case 'upgrade':
        return const Color(0xFFA78BFA);
      case 'gift':
        return const Color(0xFFF59E0B);
      case 'freeze':
        return const Color(0xFFF87171);
      case 'unfreeze':
        return const Color(0xFF4ADE80);
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'subscribe':
        return Icons.add_card_rounded;
      case 'renew':
        return Icons.autorenew_rounded;
      case 'upgrade':
        return Icons.arrow_upward_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'freeze':
        return Icons.lock_rounded;
      case 'unfreeze':
        return Icons.lock_open_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = id;
    if (userId == null) {
      return const Center(
        child: Text('缺少用户 ID 参数',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    final userAsync = ref.watch(_userByIdProvider(userId));
    final user = userAsync;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('未找到用户 $userId',
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/users'),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('返回用户列表'),
            ),
          ],
        ),
      );
    }

    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('yyyy-MM-dd HH:mm');
    final moneyFmt = NumberFormat.currency(
        locale: 'zh_CN', symbol: '¥', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(context, user),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 1400;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildLeftCol(context, ref, user, dateFmt, moneyFmt),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: _buildMiddleCol(context, user, dateFmt, timeFmt),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: _buildRightCol(context, user),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildLeftCol(context, ref, user, dateFmt, moneyFmt),
                  const SizedBox(height: 20),
                  _buildMiddleCol(context, user, dateFmt, timeFmt),
                  const SizedBox(height: 20),
                  _buildRightCol(context, user),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, UserProfile u) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/admin/users'),
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage(u.avatarUrl),
          backgroundColor: AppTheme.surfaceLight,
          child: const Icon(Icons.person,
              color: AppTheme.textMuted, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              u.displayName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${u.id} · ${u.email}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.email_rounded, size: 16),
          label: const Text('发送邮件'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_note_rounded, size: 16),
          label: const Text('编辑资料'),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    String? title,
    List<Widget>? actions,
  }) {
    return Container(
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
              child: Row(
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
                  if (actions != null) ...actions,
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

  // ============ Left: Profile + Membership Status ============
  Widget _buildLeftCol(
    BuildContext context,
    WidgetRef ref,
    UserProfile u,
    DateFormat dateFmt,
    NumberFormat moneyFmt,
  ) {
    return Column(
      children: [
        _buildProfileCard(u, dateFmt),
        const SizedBox(height: 20),
        _buildMembershipCard(context, ref, u, dateFmt, moneyFmt),
      ],
    );
  }

  Widget _buildProfileCard(UserProfile u, DateFormat dateFmt) {
    return _buildSectionCard(
      title: '用户信息',
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: NetworkImage(u.avatarUrl),
                  backgroundColor: AppTheme.surfaceLight,
                  child: const Icon(Icons.person,
                      color: AppTheme.textMuted, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  u.displayName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  u.email,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_rounded, '手机', u.phone),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.location_on_rounded, '地区',
              u.region ?? '—'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.language_rounded, '语言',
              u.language == 'zh-CN' ? '简体中文' : u.language),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.hd_rounded, '偏好画质',
              u.preferredQuality.label),
          const SizedBox(height: 10),
          _buildInfoRow(
              Icons.calendar_today_rounded,
              '注册时间',
              dateFmt.format(u.registeredAt)),
          const SizedBox(height: 10),
          _buildInfoRow(
              Icons.login_rounded,
              '上次登录',
              u.lastLoginAt == null
                  ? '—'
                  : dateFmt.format(u.lastLoginAt!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style:
                const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard(
    BuildContext context,
    WidgetRef ref,
    UserProfile u,
    DateFormat dateFmt,
    NumberFormat moneyFmt,
  ) {
    final tier = u.membership.tier;
    final color = _tierColor(tier);
    final remaining = u.membership.remainingDays;

    return _buildSectionCard(
      title: '会员状态',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_tierIcon(tier), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.membership.plan.name,
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        remaining >= 0
                            ? '到期：${dateFmt.format(u.membership.expireDate)}（剩 $remaining 天）'
                            : '已过期 ${-remaining} 天',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.credit_card_rounded, '支付方式',
              u.membership.paymentMethod ?? '未设置'),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.autorenew_rounded,
                  size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 10),
              const SizedBox(
                width: 72,
                child: Text('自动续费',
                    style:
                        TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Switch(
                    value: u.membership.isAutoRenew,
                    onChanged: (_) {
                      AdminMockRepository.instance
                          .toggleUserAutoRenew(u.id);
                      ref.invalidate(_userByIdProvider(u.id));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '自动续费已${u.membership.isAutoRenew ? '关闭' : '开启'}')),
                      );
                    },
                    activeColor: AppTheme.primaryRed,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AdminMockRepository.instance.renewUserMembership(u.id);
                    ref.invalidate(_userByIdProvider(u.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('续费 30 天成功')),
                    );
                  },
                  icon: const Icon(Icons.autorenew_rounded, size: 16),
                  label: const Text('续费 30 天'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showUpgradeDialog(context, ref, u),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: const Text('升级套餐'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    AdminMockRepository.instance.batchGiftDays([u.id], 7);
                    ref.invalidate(_userByIdProvider(u.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('赠送 7 天会员成功')),
                    );
                  },
                  icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                  label: const Text('赠送 7 天'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AdminMockRepository.instance.toggleUserFrozen(u.id);
                    ref.invalidate(_userByIdProvider(u.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '账号已${u.status == UserStatus.frozen ? '解冻' : '冻结'}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        u.status == UserStatus.frozen
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFF87171),
                    foregroundColor: Colors.black,
                  ),
                  icon: Icon(
                    u.status == UserStatus.frozen
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                      u.status == UserStatus.frozen ? '解冻账号' : '冻结账号'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(
      BuildContext context, WidgetRef ref, UserProfile u) {
    final plans = AdminMockRepository.instance.getMembershipPlans();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.divider)),
          title: const Text('升级套餐',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: plans.map((p) {
              final color = _tierColor(p.tier);
              final selected = p.tier == u.membership.tier;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: selected
                          ? color
                          : AppTheme.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  tileColor:
                      selected ? color.withOpacity(0.1) : AppTheme.surfaceLight,
                  leading: Icon(_tierIcon(p.tier), color: color),
                  title: Text(p.name,
                      style: TextStyle(
                          color: selected ? color : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '¥${p.monthlyPrice.toStringAsFixed(0)}/月 · ¥${p.yearlyPrice.toStringAsFixed(0)}/年',
                      style: const TextStyle(color: AppTheme.textSecondary)),
                  trailing: selected
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF4ADE80))
                      : const SizedBox(width: 4),
                  onTap: selected
                      ? null
                      : () {
                          AdminMockRepository.instance
                              .upgradeUserPlan(u.id, p.tier);
                          ref.invalidate(_userByIdProvider(u.id));
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已升级至 ${p.name}')),
                          );
                        },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // ============ Middle: Subscription Timeline + Watch History ============
  Widget _buildMiddleCol(
    BuildContext context,
    UserProfile u,
    DateFormat dateFmt,
    DateFormat timeFmt,
  ) {
    return Column(
      children: [
        _buildSubscriptionTimeline(u, dateFmt),
        const SizedBox(height: 20),
        _buildWatchHistory(u, timeFmt),
      ],
    );
  }

  Widget _buildSubscriptionTimeline(UserProfile u, DateFormat dateFmt) {
    final history = u.membership.history;
    return _buildSectionCard(
      title: '订阅时间线',
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text('查看全部'),
        ),
      ],
      child: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('暂无订阅记录',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          : Column(
              children: List.generate(history.length, (i) {
                final ev = history[i];
                final last = i == history.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _eventColor(ev.type).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_eventIcon(ev.type),
                              color: _eventColor(ev.type), size: 16),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ev.description,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (ev.amount != null && ev.amount! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryRed
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '¥${ev.amount!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryRed,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateFmt.format(ev.date) +
                                  ' · ${ev.type.toUpperCase()}',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }

  Widget _buildWatchHistory(UserProfile u, DateFormat timeFmt) {
    final list = u.recentWatchHistory;
    return _buildSectionCard(
      title: '最近观影历史',
      actions: [
        Text('${list.length} 条',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
      child: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('暂无观影记录',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          : Column(
              children: List.generate(list.length, (i) {
                final item = list[i];
                final last = i == list.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : 12),
                  child: _buildWatchHistoryTile(item, timeFmt),
                );
              }),
            ),
    );
  }

  Widget _buildWatchHistoryTile(WatchHistoryItem item, DateFormat timeFmt) {
    final videos = MockData.getAllVideos();
    final video = videos.where((v) => v.id == item.videoId).firstOrNull;
    final poster = video?.posterUrl ??
        'https://picsum.photos/seed/${item.videoId}/200/300';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            poster,
            width: 72,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 72,
              height: 42,
              color: AppTheme.surfaceLight,
              child: const Icon(Icons.movie,
                  color: AppTheme.textMuted, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.videoTitle,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor: AlwaysStoppedAnimation(item.progress > 0.8
                            ? const Color(0xFF4ADE80)
                            : AppTheme.primaryRed),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(item.progress * 100).toStringAsFixed(0)}% · ${item.watchMinutes}分',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '观看于 ${_timeAgo(item.watchedAt)}',
                style: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes} 分钟前';
    if (d.inHours < 24) return '${d.inHours} 小时前';
    if (d.inDays < 7) return '${d.inDays} 天前';
    return DateFormat('MM-dd HH:mm').format(t);
  }

  // ============ Right: Habits charts ============
  Widget _buildRightCol(BuildContext context, UserProfile u) {
    final now = DateTime.now();
    final random = Random(u.id.hashCode);
    final watch7d = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DailyDataPoint(
          date: d,
          value: (30 + random.nextDouble() * 180).toDouble());
    });

    final genres = ['科幻', '动作', '剧情', '喜剧', '其他'];
    final colors = [
      AppTheme.primaryRed,
      const Color(0xFF60A5FA),
      const Color(0xFF4ADE80),
      const Color(0xFFF59E0B),
      AppTheme.textMuted,
    ];
    final genreValues = [35.0, 28.0, 18.0, 12.0, 7.0];

    return Column(
      children: [
        MockLineChart(
          title: '7 日观影时长',
          unit: '分钟',
          data: watch7d,
          height: 180,
        ),
        const SizedBox(height: 20),
        MockPieChart(
          size: 160,
          title: '分类观看占比',
          slices: Map.fromIterables(
            genres,
            genreValues.asMap().entries.map((e) => PieSlice(
                  e.value,
                  colors[e.key],
                )),
          ),
        ),
      ],
    );
  }
}
