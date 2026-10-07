import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide ImageShader, ImageFilter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/video_quality.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../../user/data/providers/user_providers.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _yearly = true;
  int _selectedIndex = 2;
  bool _qrVisible = false;
  String? _qrChannel;
  final oCcy = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(membershipPlansProvider);
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/profile'),
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text(
          'iSEE',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('客服通道：请稍后补充真实联系方式')),
              );
            },
            child: const Text(
              '帮助',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(size),
                _buildBillingToggle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                  child: LayoutBuilder(
                    builder: (ctx, cons) {
                      final wide = cons.maxWidth > 900;
                      return Column(
                        children: [
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(plans.length, (i) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        right: i < plans.length - 1 ? 18 : 0),
                                    child: _PlanCard(
                                      plan: plans[i],
                                      yearly: _yearly,
                                      selected: _selectedIndex == i,
                                      currentTier: user.membership.tier,
                                      onSelect: () =>
                                          setState(() => _selectedIndex = i),
                                      onSubscribe: () =>
                                          _showSubscribeSheet(plans[i]),
                                    ),
                                  ),
                                );
                              }),
                            )
                          else
                            Column(
                              children: List.generate(plans.length, (i) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: _PlanCard(
                                    plan: plans[i],
                                    yearly: _yearly,
                                    selected: _selectedIndex == i,
                                    currentTier: user.membership.tier,
                                    onSelect: () =>
                                        setState(() => _selectedIndex = i),
                                    onSubscribe: () =>
                                        _showSubscribeSheet(plans[i]),
                                  ),
                                );
                              }),
                            ),
                          const SizedBox(height: 40),
                          _buildFeatureCompare(plans),
                          const SizedBox(height: 48),
                          _buildFooter(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_qrVisible)
            _QRCodeDialog(
              plan: plans[_selectedIndex],
              yearly: _yearly,
              channel: _qrChannel ?? 'stripe',
              onClose: () => setState(() {
                _qrVisible = false;
                _qrChannel = null;
              }),
              onMockSuccess: () {
                setState(() {
                  _qrVisible = false;
                  _qrChannel = null;
                });
                final now = DateTime.now();
                final p = plans[_selectedIndex];
                final exp = now.add(Duration(days: _yearly ? 365 : 30));
                final userNotifier =
                    ref.read(currentUserProvider.notifier);
                final u = userNotifier.state;
                userNotifier.state = _UserMembershipUpdate(u).update(p, exp);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '🎉 ${p.name} 订阅成功！有效期至 ${DateFormat('yyyy-MM-dd').format(exp)}'),
                    backgroundColor: Colors.green.shade700,
                    duration: const Duration(seconds: 4),
                  ),
                );
                Future.delayed(const Duration(milliseconds: 600), () {
                  context.go('/profile');
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHero(Size size) {
    final h = size.width > 900 ? 360.0 : 420.0;
    return Container(
      width: double.infinity,
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, AppTheme.backgroundDark],
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: SizedBox(
            width: 720,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '选择适合你的方案',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '电视、平板、手机、电脑全平台无广告观影\n随时取消，不设最低合约',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepChip(label: '挑选方案', active: true),
                    _StepDivider(),
                    _StepChip(label: '扫码支付', active: false),
                    _StepDivider(),
                    _StepChip(label: '开始观影', active: false),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BillingLabel('按月', active: !_yearly),
          const SizedBox(width: 18),
          SizedBox(
            height: 32,
            child: FittedBox(
              child: Switch(
                value: _yearly,
                onChanged: (v) => setState(() => _yearly = v),
                activeTrackColor: AppTheme.primaryRed.withOpacity(0.7),
                activeThumbColor: Colors.white,
                inactiveTrackColor: AppTheme.surfaceLight,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BillingLabel('按年', active: _yearly),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '省 2 个月',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCompare(List<MembershipPlan> plans) {
    final features = [
      '无广告观看',
      '独家首播内容',
      '全平台多屏观看',
      '下载离线观看',
      '杜比全景声',
      '4K Ultra HD + HDR',
      '优先客服通道',
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '方案对比',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.0),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppTheme.divider, width: 1)),
                ),
                children: [
                  const TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '功能',
                        style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  ...plans
                      .map((p) => TableCell(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                p.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: p.tier == plans[_selectedIndex].tier
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ],
              ),
              ...features.map(
                (f) => TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom:
                          BorderSide(color: AppTheme.divider, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        f,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...plans.map((p) {
                      final available = _isAvailable(p, f, features);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Icon(
                          available
                              ? Icons.check_circle_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: available
                              ? Colors.greenAccent
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isAvailable(MembershipPlan p, String feature, List<String> all) {
    switch (feature) {
      case '无广告观看':
        return true;
      case '独家首播内容':
        return p.tier != MembershipTier.basic;
      case '全平台多屏观看':
        return p.maxDevices >= 1;
      case '下载离线观看':
        return p.maxDownloads >= 1;
      case '杜比全景声':
        return p.tier == MembershipTier.premium;
      case '4K Ultra HD + HDR':
        return p.tier == MembershipTier.premium;
      case '优先客服通道':
        return p.tier == MembershipTier.premium;
      default:
        return true;
    }
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Divider(color: AppTheme.divider),
        SizedBox(height: 24),
        Text(
          '随时可取消订阅 · 退款保障 · 安全加密传输',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded,
                color: AppTheme.textMuted, size: 14),
            SizedBox(width: 6),
            Text(
              '采用 256-bit SSL/TLS 加密保护您的支付信息',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 24),
      ],
    );
  }

  void _showSubscribeSheet(MembershipPlan plan) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 520,
            minWidth: 320,
          ),
          child: Material(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: _PaymentSheet(
              plan: plan,
              yearly: _yearly,
              onSelectChannel: (ch) {
                setState(() {
                  _qrChannel = ch;
                  _qrVisible = true;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MembershipPlan plan;
  final bool yearly;
  final bool selected;
  final MembershipTier currentTier;
  final VoidCallback onSelect;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.yearly,
    required this.selected,
    required this.currentTier,
    required this.onSelect,
    required this.onSubscribe,
  });

  Color get _bg {
    switch (plan.tier) {
      case MembershipTier.basic:
        return const Color(0xFF5B8DEF);
      case MembershipTier.standard:
        return const Color(0xFF8E74F5);
      case MembershipTier.premium:
        return const Color(0xFFE07B1A);
    }
  }

  double get _price => yearly ? plan.yearlyPrice : plan.monthlyPrice;
  double get _monthlyEq => yearly ? plan.yearlyPrice / 12 : plan.monthlyPrice;

  @override
  Widget build(BuildContext context) {
    final isCurrent = currentTier.index >= plan.tier.index &&
        currentTier == plan.tier;
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _bg : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _bg.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '当前方案',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    plan.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppTheme.textPrimary),
                      children: [
                        TextSpan(
                          text: '¥${_monthlyEq.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const TextSpan(
                          text: '/月',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (yearly)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '一次性付 ¥${plan.yearlyPrice.toStringAsFixed(0)} / 年',
                        style: TextStyle(
                          color: _bg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.divider, height: 1),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: plan.features
                        .map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: _bg, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected && !isCurrent
                            ? _bg
                            : AppTheme.textPrimary,
                        foregroundColor: selected && !isCurrent
                            ? Colors.white
                            : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        isCurrent ? '当前方案' : '立即订阅',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String label;
  final bool active;
  const _StepChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryRed : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: active ? AppTheme.primaryRed : AppTheme.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppTheme.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 2,
      color: AppTheme.surfaceLight,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _BillingLabel extends StatelessWidget {
  final String text;
  final bool active;
  const _BillingLabel(this.text, {required this.active});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: active ? AppTheme.textPrimary : AppTheme.textMuted,
        fontSize: 15,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final MembershipPlan plan;
  final bool yearly;
  final ValueChanged<String> onSelectChannel;

  const _PaymentSheet({
    required this.plan,
    required this.yearly,
    required this.onSelectChannel,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  int? _selectedChannel;
  final channels = const [
    {'id': 'stripe', 'name': 'Stripe / 信用卡', 'sub': 'Visa · Master · Amex · Apple Pay', 'color': Color(0xFF635BFF), 'icon': Icons.credit_card_rounded},
    {'id': 'paypal', 'name': 'PayPal', 'sub': '全球 200+ 国家通用', 'color': Color(0xFF003087), 'icon': Icons.paypal_rounded},
    {'id': 'crypto', 'name': 'USDT / 加密货币', 'sub': 'TRC20 · ERC20 · BTC', 'color': Color(0xFF27A17C), 'icon': Icons.currency_bitcoin_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final price = widget.yearly ? widget.plan.yearlyPrice : widget.plan.monthlyPrice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.plan.name} · ${widget.yearly ? '按年' : '按月'}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '订单将在支付成功后自动激活',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '¥${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              '请选择支付方式',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(channels.length, (i) {
              final c = channels[i];
              final selected = _selectedChannel == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => setState(() => _selectedChannel = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? (c['color'] as Color)
                              : AppTheme.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (c['color'] as Color).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              c['icon'] as IconData,
                              color: c['color'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['name'] as String,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  c['sub'] as String,
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? (c['color'] as Color)
                                : AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedChannel == null
                    ? null
                    : () {
                        final id = channels[_selectedChannel!]['id'] as String;
                        Navigator.of(context).pop();
                        widget.onSelectChannel(id);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  disabledBackgroundColor:
                      AppTheme.primaryRed.withOpacity(0.35),
                  disabledForegroundColor: Colors.white70,
                ),
                child: const Text(
                  '生成支付二维码',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回方案选择'),
            ),
          ],
        ),
      );
  }
}

class _QRCodeDialog extends StatelessWidget {
  final MembershipPlan plan;
  final bool yearly;
  final String channel;
  final VoidCallback onClose;
  final VoidCallback onMockSuccess;

  const _QRCodeDialog({
    required this.plan,
    required this.yearly,
    required this.channel,
    required this.onClose,
    required this.onMockSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final price = yearly ? plan.yearlyPrice : plan.monthlyPrice;
    final chNames = {
      'stripe': 'Stripe Checkout',
      'paypal': 'PayPal',
      'crypto': 'USDT (TRC20)',
    };
    final priceText = channel == 'crypto'
        ? '≈ \$${(price / 7.2).toStringAsFixed(2)} USDT'
        : '¥${price.toStringAsFixed(2)}';
    final mockAddress = channel == 'crypto'
        ? 'TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE'
        : 'https://pay.isee.video/checkout/${plan.id}/${yearly ? 'Y' : 'M'}/${DateTime.now().millisecondsSinceEpoch}';

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  '请扫码支付',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${chNames[channel]} · ${plan.name} ${yearly ? '按年' : '按月'}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  priceText,
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    painter: _MockQRPainter(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Column(
                  children: [
                    const _CountdownTimer(),
                    const SizedBox(height: 4),
                    Text(
                      '二维码有效期 15 分钟',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      channel == 'crypto' ? '链上收款地址' : '支付链接',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mockAddress,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onMockSuccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  '✅ 模拟支付成功（用于测试）',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onClose,
                child: const Text('取消并返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockQRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cell = size.width / 24;
    final rand = List.generate(
        24 * 24, (i) => (((i * 1103515245 + 12345) >> 16) & 0x7fff) % 3 == 0);
    for (int y = 0; y < 24; y++) {
      for (int x = 0; x < 24; x++) {
        final isCornerFinder = (x < 7 && y < 7) ||
            (x > 16 && y < 7) ||
            (x < 7 && y > 16);
        if (isCornerFinder) {
          final fx = x < 7 ? 0 : 17;
          final fy = y < 7 ? 0 : 17;
          final dx = x - fx;
          final dy = y - fy;
          final isBorder = dx == 0 || dx == 6 || dy == 0 || dy == 6;
          final isCenter = dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4;
          if (isBorder || isCenter) {
            canvas.drawRect(
              Rect.fromLTWH(x * cell, y * cell, cell, cell),
              paint,
            );
          }
          continue;
        }
        if (rand[y * 24 + x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint,
          );
        }
      }
    }
    final center = size.width / 2;
    canvas.drawCircle(
      Offset(center, center),
      cell * 3,
      Paint()..color = Colors.white,
    );
    final innerPaint = Paint()..color = AppTheme.primaryRed;
    for (int i = -1; i <= 1; i += 2) {
      for (int j = -1; j <= 1; j += 2) {
        if (i == 0 && j == 0) continue;
        final cx = center + i * cell * 3;
        final cy = center + j * cell * 3;
        canvas.drawCircle(Offset(cx, cy), cell * 0.6, innerPaint);
      }
    }
    canvas.drawCircle(
      Offset(center, center),
      cell * 1.4,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer();

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late int _remaining;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remaining = 15 * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining > 0 && mounted) {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined,
            color: AppTheme.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(
          '$m:$s',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _UserMembershipUpdate {
  final UserProfile u;
  _UserMembershipUpdate(this.u);

  UserProfile update(MembershipPlan plan, DateTime expire) {
    final newM = UserMembership(
      tier: plan.tier,
      plan: plan,
      startDate: DateTime.now(),
      expireDate: expire,
      isActive: true,
      isAutoRenew: u.membership.isAutoRenew,
      paymentMethod: u.membership.paymentMethod,
    );
    return UserProfile(
      id: u.id,
      email: u.email,
      phone: u.phone,
      displayName: u.displayName,
      avatarUrl: u.avatarUrl,
      language: u.language,
      preferredQuality: u.preferredQuality,
      autoplayNext: u.autoplayNext,
      autoplayTrailers: u.autoplayTrailers,
      myListIds: u.myListIds,
      watchProgress: u.watchProgress,
      membership: newM,
    );
  }
}
