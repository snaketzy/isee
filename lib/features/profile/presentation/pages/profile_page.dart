import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/video_quality.dart';
import '../../../user/data/providers/user_providers.dart';
import '../../../user/domain/entities/user_profile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;
    final wide = size.width > 960;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _MembershipHeader(user: user),
            ),
            SliverToBoxAdapter(
              child: wide
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(48, 28, 48, 40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _ProfileInfo(user: user)),
                          const SizedBox(width: 32),
                          Expanded(flex: 3, child: _SettingsPanel(user: user)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                      child: Column(
                        children: [
                          _ProfileInfo(user: user),
                          const SizedBox(height: 28),
                          _SettingsPanel(user: user),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipHeader extends ConsumerWidget {
  final UserProfile user;
  const _MembershipHeader({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = user.membership;
    final tier = m.tier;
    final remainDays = m.remainingDays;

    final colors = {
      MembershipTier.basic: const [Color(0xFF5B8DEF), Color(0xFF3A5FCC)],
      MembershipTier.standard: const [Color(0xFF8E74F5), Color(0xFF5B3ECB)],
      MembershipTier.premium: const [Color(0xFFF2B45B), Color(0xFFE07B1A)],
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors[tier]!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      'iSEE ${tier.shortLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (m.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '✓ 会员有效中',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${user.displayName}，欢迎回来',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tier.label} · 最高 ${m.plan.maxQuality.label} · ${m.plan.maxDevices} 台设备同时观看',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _InfoStat(
                      label: '下次续费',
                      value: DateFormat('yyyy年MM月dd日').format(m.expireDate),
                      hint: m.isAutoRenew ? '自动续费已开启' : '已关闭自动续费',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _InfoStat(
                      label: '剩余时长',
                      value: '$remainDays 天',
                      hint: remainDays < 30 ? '建议提前续费' : '还剩充足时间',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _InfoStat(
                      label: '支付方式',
                      value: m.paymentMethod ?? '未设置',
                      hint: '可随时在账户设置中更改',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => context.push('/subscription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      '管理订阅',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('续费成功（Mock 操作）')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text(
                      '立即续费',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  const _InfoStat({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final UserProfile user;
  const _ProfileInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppTheme.primaryRed,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: user.avatarUrl,
                    fit: BoxFit.cover,
                    width: 88,
                    height: 88,
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.person_rounded,
                          size: 42, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.displayName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.phone,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('编辑资料功能开发中')),
                  );
                },
                child: const Text('编辑个人资料'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _QuickTile(
          icon: Icons.bookmark_rounded,
          title: '我的片单',
          subtitle: '${user.myListIds.length} 部作品已收藏',
          onTap: () => context.go('/mylist'),
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.history_rounded,
          title: '观看历史',
          subtitle: '最近观看的内容',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('观看历史开发中')),
            );
          },
        ),
        const SizedBox(height: 10),
        _QuickTile(
          icon: Icons.card_giftcard_rounded,
          title: '兑换码 / 优惠码',
          subtitle: '使用兑换码延长会员',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('兑换码功能开发中')),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsPanel extends ConsumerStatefulWidget {
  final UserProfile user;
  const _SettingsPanel({required this.user});

  @override
  ConsumerState<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<_SettingsPanel> {
  late bool _autoplayNext;
  late bool _autoplayTrailers;
  late VideoQuality _quality;
  late String _language;

  @override
  void initState() {
    super.initState();
    _autoplayNext = widget.user.autoplayNext;
    _autoplayTrailers = widget.user.autoplayTrailers;
    _quality = widget.user.preferredQuality;
    _language = widget.user.language;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '播放与偏好设置',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '根据你的习惯定制观看体验',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          _SwitchSetting(
            title: '自动播放下一集',
            subtitle: '剧集看完一集后自动播放下一集',
            value: _autoplayNext,
            onChanged: (v) {
              setState(() => _autoplayNext = v);
            },
          ),
          const SizedBox(height: 8),
          _SwitchSetting(
            title: '详情页自动播放预告',
            subtitle: '打开视频详情时自动预览预告片',
            value: _autoplayTrailers,
            onChanged: (v) {
              setState(() => _autoplayTrailers = v);
            },
          ),
          const SizedBox(height: 8),
          _DropdownSetting<VideoQuality>(
            title: '默认画质',
            subtitle: '网络连接良好时自动使用此画质',
            value: _quality,
            items: VideoQuality.values
                .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text(q.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _quality = v);
            },
          ),
          const SizedBox(height: 8),
          _DropdownSetting<String>(
            title: '界面语言',
            subtitle: '选择 iSEE 的显示语言',
            value: _language,
            items: const [
              DropdownMenuItem(value: 'zh-CN', child: Text('简体中文')),
              DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文')),
              DropdownMenuItem(value: 'en-US', child: Text('English')),
              DropdownMenuItem(value: 'ja-JP', child: Text('日本語')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _language = v);
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 24),
          const Text(
            '账户与帮助',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _FlatItem(
            icon: Icons.security_rounded,
            title: '账户安全',
            subtitle: '修改密码、登录设备管理',
            onTap: () {},
          ),
          const SizedBox(height: 4),
          _FlatItem(
            icon: Icons.privacy_tip_rounded,
            title: '隐私设置',
            subtitle: '观看记录与推荐偏好',
            onTap: () {},
          ),
          const SizedBox(height: 4),
          _FlatItem(
            icon: Icons.help_outline_rounded,
            title: '帮助中心',
            subtitle: '常见问题与联系客服',
            onTap: () {},
          ),
          const SizedBox(height: 4),
          _FlatItem(
            icon: Icons.info_outline_rounded,
            title: '关于 iSEE',
            subtitle: '版本信息与用户协议',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const _AboutDialog(),
              );
            },
          ),
          const SizedBox(height: 4),
          _FlatItem(
            icon: Icons.logout_rounded,
            title: '退出登录',
            color: AppTheme.primaryRed,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('这是测试账号，暂不能退出登录')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryRed.withOpacity(0.7),
            activeThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.surfaceLight,
          ),
        ],
      ),
    );
  }
}

class _DropdownSetting<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownSetting({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                dropdownColor: AppTheme.surfaceLight,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: items,
                onChanged: onChanged,
                iconEnabledColor: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  const _FlatItem({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppTheme.textPrimary;
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'iSEE',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '版本 0.1.0 (MVP)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'iSEE 流媒体视频订阅平台，全海外基础设施，\nFlutter 三端统一架构。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 22),
              Text(
                '© 2026 iSEE Inc. All rights reserved.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
