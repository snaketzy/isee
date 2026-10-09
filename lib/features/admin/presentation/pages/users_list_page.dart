import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../user/domain/entities/user_profile.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../widgets/data_table.dart';
import '../widgets/stat_card.dart';

final _allUsersProvider = Provider<List<UserProfile>>((ref) {
  return AdminMockRepository.instance.getAllUsers();
});

class _UsersFilter {
  final String search;
  final MembershipTier? tier;
  final UserStatus? status;
  final DateTime? registerStart;
  final DateTime? registerEnd;

  const _UsersFilter({
    this.search = '',
    this.tier,
    this.status,
    this.registerStart,
    this.registerEnd,
  });

  _UsersFilter copyWith({
    String? search,
    MembershipTier? tier,
    bool clearTier = false,
    UserStatus? status,
    bool clearStatus = false,
    DateTime? registerStart,
    bool clearStart = false,
    DateTime? registerEnd,
    bool clearEnd = false,
  }) {
    return _UsersFilter(
      search: search ?? this.search,
      tier: clearTier ? null : tier ?? this.tier,
      status: clearStatus ? null : status ?? this.status,
      registerStart: clearStart ? null : registerStart ?? this.registerStart,
      registerEnd: clearEnd ? null : registerEnd ?? this.registerEnd,
    );
  }
}

class UsersListPage extends ConsumerStatefulWidget {
  final String? id;
  const UsersListPage({super.key, this.id});

  @override
  ConsumerState<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends ConsumerState<UsersListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  _UsersFilter _filter = const _UsersFilter();
  List<UserProfile> _selected = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserProfile> _filterUsers(List<UserProfile> all) {
    return all.where((u) {
      if (_filter.search.isNotEmpty) {
        final q = _filter.search.toLowerCase();
        if (!u.email.toLowerCase().contains(q) &&
            !u.displayName.toLowerCase().contains(q) &&
            !u.phone.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filter.tier != null && u.membership.tier != _filter.tier) {
        return false;
      }
      UserStatus realStatus = u.status;
      if (u.status == UserStatus.active &&
          u.membership.expireDate.isBefore(DateTime.now())) {
        realStatus = UserStatus.expired;
      }
      if (_filter.status != null && realStatus != _filter.status) {
        return false;
      }
      if (_filter.registerStart != null &&
          u.registeredAt.isBefore(_filter.registerStart!)) {
        return false;
      }
      if (_filter.registerEnd != null &&
          u.registeredAt.isAfter(_filter.registerEnd!
              .add(const Duration(days: 1)))) {
        return false;
      }
      return true;
    }).toList();
  }

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

  UserStatus _effectiveStatus(UserProfile u) {
    if (u.status == UserStatus.active &&
        u.membership.expireDate.isBefore(DateTime.now())) {
      return UserStatus.expired;
    }
    return u.status;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(_allUsersProvider);
    final filtered = _filterUsers(all);
    final fmt = NumberFormat('#,##0', 'zh_CN');
    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('yyyy-MM-dd HH:mm');

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final today = DateTime(now.year, now.month, now.day);

    final totalUsers = all.length;
    final monthNew =
        all.where((u) => u.registeredAt.isAfter(monthStart)).length;
    final todayActive = all.where((u) {
      if (u.lastLoginAt == null) return false;
      final d = DateTime(u.lastLoginAt!.year, u.lastLoginAt!.month,
          u.lastLoginAt!.day);
      return d.isAtSameMomentAs(today);
    }).length;
    final frozen = all.where((u) => u.status == UserStatus.frozen).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatGrid(fmt, totalUsers, monthNew, todayActive, frozen),
          const SizedBox(height: 24),
          _buildFilterBar(context),
          const SizedBox(height: 16),
          if (_selected.isNotEmpty) _buildBatchActionBar(context),
          if (_selected.isNotEmpty) const SizedBox(height: 16),
          AdminDataTable<UserProfile>(
            headerTitle: '用户列表（${filtered.length} 条）',
            headerAction: TextButton.icon(
              onPressed: () {
                setState(() {
                  _filter = const _UsersFilter();
                  _searchCtrl.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('重置筛选'),
            ),
            items: filtered,
            selectable: true,
            onSelectionChanged: (sel) {
              setState(() => _selected = sel);
            },
            rowsPerPage: 20,
            columns: [
              const DataColumnSpec(label: '用户', width: 220),
              const DataColumnSpec(label: '会员等级', width: 110),
              const DataColumnSpec(label: '到期 / 剩余', width: 160),
              DataColumnSpec(
                label: '注册时间',
                sortComparator: (a, b) =>
                    a.registeredAt.compareTo(b.registeredAt),
              ),
              const DataColumnSpec(label: '上次登录'),
              DataColumnSpec(
                label: '总观影(h)',
                numeric: true,
                sortComparator: (a, b) =>
                    a.totalWatchMinutes.compareTo(b.totalWatchMinutes),
              ),
              DataColumnSpec(
                label: '登录次数',
                numeric: true,
                sortComparator: (a, b) => a.loginCount.compareTo(b.loginCount),
              ),
              const DataColumnSpec(label: '状态', width: 90),
              const DataColumnSpec(label: '操作', width: 260),
            ],
            rowBuilder: (ctx, u, _) {
              final effStatus = _effectiveStatus(u);
              final remaining = u.membership.remainingDays;
              return DataRow(cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(u.avatarUrl),
                      onBackgroundImageError: (_, __) {},
                      backgroundColor: AppTheme.surfaceLight,
                      child: const Icon(Icons.person,
                          color: AppTheme.textMuted, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            u.displayName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u.email,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColor(u.membership.tier).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      u.membership.tier.label,
                      style: TextStyle(
                        color: _tierColor(u.membership.tier),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dateFmt.format(u.membership.expireDate),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining >= 0 ? '剩余 $remaining 天' : '已过期 ${-remaining} 天',
                      style: TextStyle(
                        color: remaining >= 7
                            ? AppTheme.textMuted
                            : remaining >= 0
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFF87171),
                        fontSize: 11,
                      ),
                    ),
                  ],
                )),
                DataTextCell(dateFmt.format(u.registeredAt)),
                DataTextCell(u.lastLoginAt == null
                    ? '—'
                    : timeFmt.format(u.lastLoginAt!)),
                DataTextCell(
                  (u.totalWatchMinutes / 60).toStringAsFixed(1),
                  numeric: true,
                ),
                DataTextCell(fmt.format(u.loginCount), numeric: true),
                DataCell(_buildStatusChip(effStatus)),
                DataCell(Row(
                  children: [
                    IconButton(
                      tooltip: '查看详情',
                      onPressed: () => context.go('/admin/users/${u.id}'),
                      icon: const Icon(Icons.visibility_outlined,
                          color: AppTheme.textSecondary, size: 18),
                    ),
                    IconButton(
                      tooltip: '手动续费',
                      onPressed: () {
                        AdminMockRepository.instance
                            .renewUserMembership(u.id);
                        ref.invalidate(_allUsersProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${u.displayName} 续费 30 天成功')),
                        );
                      },
                      icon: Icon(Icons.autorenew_rounded,
                          color: Color(0xFF4ADE80), size: 18),
                    ),
                    IconButton(
                      tooltip: effStatus == UserStatus.frozen
                          ? '解冻账号'
                          : '冻结账号',
                      onPressed: () {
                        AdminMockRepository.instance.toggleUserFrozen(u.id);
                        ref.invalidate(_allUsersProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${u.displayName} ${effStatus == UserStatus.frozen ? '已解冻' : '已冻结'}')),
                        );
                      },
                      icon: Icon(
                        effStatus == UserStatus.frozen
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: effStatus == UserStatus.frozen
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFF87171),
                        size: 18,
                      ),
                    ),
                    IconButton(
                      tooltip: '复制用户ID',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: u.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('已复制: ${u.id}'),
                              duration: const Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded,
                          color: AppTheme.textMuted, size: 18),
                    ),
                  ],
                )),
              ]);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          '用户管理',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.import_export_rounded, size: 18),
          label: const Text('导出 CSV'),
        ),
      ],
    );
  }

  Widget _buildStatGrid(NumberFormat fmt, int total, int monthNew,
      int todayActive, int frozen) {
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
                title: '总用户数',
                value: fmt.format(total),
                subtitle: '累计注册用户',
                icon: Icons.people_alt_rounded,
                accentColor: const Color(0xFF60A5FA),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '本月新增',
                value: fmt.format(monthNew),
                subtitle: '较上月 +12.4%',
                icon: Icons.person_add_rounded,
                accentColor: const Color(0xFF4ADE80),
                trend: const TrendData(
                  value: 12.4,
                  direction: TrendDirection.up,
                  changePercent: 12.4,
                ),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '今日活跃',
                value: fmt.format(todayActive),
                subtitle: 'DAU',
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '冻结账号',
                value: fmt.format(frozen),
                subtitle: '异常账号冻结数',
                icon: Icons.lock_outline_rounded,
                accentColor: const Color(0xFFF87171),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _filter = _filter.copyWith(search: v)),
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: '搜索 邮箱 / 昵称 / 手机',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                isDense: true,
              ),
            ),
          ),
          _buildTierChips(),
          _buildStatusChips(),
          _buildDateRangeButton(context),
        ],
      ),
    );
  }

  Widget _buildTierChips() {
    final items = [
      (label: '全部', value: null as MembershipTier?),
      (label: 'Basic', value: MembershipTier.basic),
      (label: 'Standard', value: MembershipTier.standard),
      (label: 'Premium', value: MembershipTier.premium),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((e) {
        final selected = _filter.tier == e.value;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(e.label),
            selected: selected,
            labelStyle: TextStyle(
              color: selected
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            selectedColor: AppTheme.primaryRed.withOpacity(0.2),
            backgroundColor: AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: selected
                    ? AppTheme.primaryRed.withOpacity(0.6)
                    : Colors.transparent,
              ),
            ),
            onSelected: (_) {
              setState(() {
                _filter = _filter.copyWith(
                    tier: e.value, clearTier: e.value == null);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChips() {
    final items = [
      (label: '全部', value: null as UserStatus?),
      (label: '正常', value: UserStatus.active),
      (label: '冻结', value: UserStatus.frozen),
      (label: '过期', value: UserStatus.expired),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((e) {
        final selected = _filter.status == e.value;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(e.label),
            selected: selected,
            labelStyle: TextStyle(
              color: selected
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            selectedColor: const Color(0xFF60A5FA).withOpacity(0.2),
            backgroundColor: AppTheme.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: selected
                    ? const Color(0xFF60A5FA).withOpacity(0.6)
                    : Colors.transparent,
              ),
            ),
            onSelected: (_) {
              setState(() {
                _filter = _filter.copyWith(
                    status: e.value, clearStatus: e.value == null);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    final fmt = DateFormat('MM-dd');
    final label = (_filter.registerStart != null || _filter.registerEnd != null)
        ? '${_filter.registerStart != null ? fmt.format(_filter.registerStart!) : '...'} ~ ${_filter.registerEnd != null ? fmt.format(_filter.registerEnd!) : '...'}'
        : '注册时间范围';
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2022),
          lastDate: DateTime.now(),
          initialDateRange: (_filter.registerStart != null &&
                  _filter.registerEnd != null)
              ? DateTimeRange(
                  start: _filter.registerStart!, end: _filter.registerEnd!)
              : null,
          builder: (ctx, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.primaryRed,
                  onPrimary: AppTheme.textPrimary,
                  surface: AppTheme.surfaceDark,
                  onSurface: AppTheme.textPrimary,
                ),
                dialogBackgroundColor: AppTheme.surfaceDark,
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _filter = _filter.copyWith(
              registerStart: picked.start,
              registerEnd: picked.end,
            );
          });
        }
      },
      icon: const Icon(Icons.date_range_rounded, size: 16),
      label: Text(label),
    );
  }

  Widget _buildBatchActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppTheme.primaryRed, size: 18),
          const SizedBox(width: 8),
          Text(
            '已选择 ${_selected.length} 个用户',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              final ids = _selected.map((u) => u.id).toList();
              AdminMockRepository.instance
                  .sendEmailNotification(ids, '系统通知');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已向 ${ids.length} 个用户发送邮件通知')),
              );
              setState(() => _selected = []);
            },
            icon: const Icon(Icons.email_rounded, size: 16),
            label: const Text('发送邮件'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              final ids = _selected.map((u) => u.id).toList();
              AdminMockRepository.instance.batchGiftDays(ids, 7);
              ref.invalidate(_allUsersProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已向 ${ids.length} 个用户赠送 7 天会员')),
              );
              setState(() => _selected = []);
            },
            icon: const Icon(Icons.card_giftcard_rounded, size: 16),
            label: const Text('批量赠送 7 天'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(UserStatus s) {
    switch (s) {
      case UserStatus.active:
        return StatusChip.byVariant('正常', StatusVariant.success);
      case UserStatus.frozen:
        return StatusChip.byVariant('冻结', StatusVariant.error);
      case UserStatus.expired:
        return StatusChip.byVariant('过期', StatusVariant.warning);
    }
  }
}
