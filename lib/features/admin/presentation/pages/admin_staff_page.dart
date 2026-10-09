import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_auth_provider.dart';
import '../../data/repositories/admin_mock_repository.dart';
import '../../domain/entities/admin_user.dart';
import '../widgets/data_table.dart';
import '../widgets/stat_card.dart';

final _adminUsersProvider = StateProvider<List<AdminUser>>((ref) {
  return AdminMockRepository.instance.getAllAdminUsers();
});

class AdminStaffPage extends ConsumerStatefulWidget {
  final String? id;
  const AdminStaffPage({super.key, this.id});

  @override
  ConsumerState<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends ConsumerState<AdminStaffPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  AdminUser? _editingUser;
  bool _isCreating = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminUser> _filterUsers(List<AdminUser> all) {
    if (_search.isEmpty) return all;
    final q = _search.toLowerCase();
    return all
        .where((u) =>
            u.email.toLowerCase().contains(q) ||
            u.displayName.toLowerCase().contains(q) ||
            u.id.toLowerCase().contains(q))
        .toList();
  }

  Color _roleColor(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AppTheme.primaryRed;
      case AdminRole.contentEditor:
        return const Color(0xFF60A5FA);
      case AdminRole.analyst:
        return const Color(0xFF4ADE80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    final isSuperAdmin = auth.user?.role == AdminRole.superAdmin;

    if (!isSuperAdmin) {
      return _buildNoPermission();
    }

    final all = ref.watch(_adminUsersProvider);
    final filtered = _filterUsers(all);
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final numFmt = NumberFormat('#,##0', 'zh_CN');

    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    final totalAdmins = all.length;
    final onlineAdmins = all.where((u) {
      if (u.lastLoginAt == null) return false;
      return u.lastLoginAt!.isAfter(twentyFourHoursAgo);
    }).length;

    final roleCounts = <AdminRole, int>{};
    for (final u in all) {
      roleCounts[u.role] = (roleCounts[u.role] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatGrid(
            numFmt,
            totalAdmins,
            onlineAdmins,
            roleCounts,
          ),
          const SizedBox(height: 24),
          _buildFilterBar(context),
          const SizedBox(height: 16),
          AdminDataTable<AdminUser>(
            headerTitle: '管理员列表（${filtered.length} 条）',
            headerAction: TextButton.icon(
              onPressed: () {
                setState(() {
                  _search = '';
                  _searchCtrl.clear();
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('重置'),
            ),
            items: filtered,
            rowsPerPage: 20,
            columns: [
              const DataColumnSpec(label: '头像', width: 60),
              const DataColumnSpec(label: '姓名 / 邮箱', width: 220),
              const DataColumnSpec(label: '角色', width: 120),
              const DataColumnSpec(label: '状态', width: 100),
              DataColumnSpec(
                label: '创建时间',
                sortComparator: (a, b) => a.createdAt.compareTo(b.createdAt),
              ),
              const DataColumnSpec(label: '上次登录'),
              DataColumnSpec(
                label: '登录次数',
                numeric: true,
                sortComparator: (a, b) => a.loginCount.compareTo(b.loginCount),
              ),
              const DataColumnSpec(label: '操作', width: 200),
            ],
            rowBuilder: (context, user, selected) {
              return DataRow(
                cells: [
                  DataCell(
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.avatarUrl),
                      radius: 20,
                    ),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _roleColor(user.role).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _roleColor(user.role).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        user.role.label,
                        style: TextStyle(
                          color: _roleColor(user.role),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Switch(
                      value: user.isActive,
                      onChanged: (v) {
                        final idx = all.indexWhere((u) => u.id == user.id);
                        if (idx < 0) return;
                        final list = List<AdminUser>.from(all);
                        final updated = user.copyWith(isActive: v);
                        list[idx] = updated;
                        AdminMockRepository.instance.upsertAdminUser(updated);
                        ref.read(_adminUsersProvider.notifier).state = list;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${user.displayName} 已${v ? '启用' : '禁用'}',
                            ),
                          ),
                        );
                      },
                      activeTrackColor:
                          const Color(0xFF4ADE80).withValues(alpha: 0.6),
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: AppTheme.surfaceLight,
                    ),
                  ),
                  DataTextCell(dateFmt.format(user.createdAt)),
                  DataTextCell(
                    user.lastLoginAt == null
                        ? '—'
                        : dateFmt.format(user.lastLoginAt!),
                    color: AppTheme.textSecondary,
                  ),
                  DataTextCell(
                    numFmt.format(user.loginCount),
                    numeric: true,
                  ),
                  DataCell(
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openEditDialog(user),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('编辑'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '已向 ${user.email} 发送密码重置邮件（Mock）'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.key_outlined, size: 14),
                          label: const Text('重置密码'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('已复制 ID: ${user.id}'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('复制ID'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNoPermission() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: AppTheme.primaryRed,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '无权限访问',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '仅超级管理员可访问管理员账户管理模块',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Text(
          '管理员账户管理',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _openCreateDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('新增管理员'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(
    NumberFormat numFmt,
    int total,
    int online,
    Map<AdminRole, int> roleCounts,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1200
            ? 3
            : constraints.maxWidth > 700
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
                title: '总管理员数',
                value: numFmt.format(total),
                subtitle: '所有已注册的管理员账户',
                icon: Icons.admin_panel_settings_rounded,
                accentColor: AppTheme.primaryRed,
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: StatCard(
                title: '24h 内在线',
                value: numFmt.format(online),
                subtitle: '过去 24 小时内登录过',
                icon: Icons.online_prediction_rounded,
                accentColor: const Color(0xFF4ADE80),
              ),
            ),
            SizedBox(
              width: crossCount == 1
                  ? double.infinity
                  : (constraints.maxWidth - 20 * (crossCount - 1)) / crossCount,
              child: _buildRolePieCard(roleCounts),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRolePieCard(Map<AdminRole, int> roleCounts) {
    final total = roleCounts.values.fold<int>(0, (a, b) => a + b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '角色分布',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _MiniPiePainter(
                    segments: [
                      _PieSegment(
                        value: roleCounts[AdminRole.superAdmin] ?? 0,
                        color: _roleColor(AdminRole.superAdmin),
                      ),
                      _PieSegment(
                        value: roleCounts[AdminRole.contentEditor] ?? 0,
                        color: _roleColor(AdminRole.contentEditor),
                      ),
                      _PieSegment(
                        value: roleCounts[AdminRole.analyst] ?? 0,
                        color: _roleColor(AdminRole.analyst),
                      ),
                    ],
                    total: total,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AdminRole.values.map((r) {
                    final count = roleCounts[r] ?? 0;
                    final pct = total > 0 ? (count / total * 100) : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _roleColor(r),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.label,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '$count (${pct.toStringAsFixed(0)}%)',
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

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.surfaceLight,
                  hintText: '搜索姓名、邮箱、ID...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateDialog() {
    setState(() {
      _isCreating = true;
      _editingUser = null;
    });
    _showFormDialog(context);
  }

  void _openEditDialog(AdminUser user) {
    setState(() {
      _isCreating = false;
      _editingUser = user;
    });
    _showFormDialog(context);
  }

  void _showFormDialog(BuildContext context) {
    final emailCtrl = TextEditingController(text: _editingUser?.email ?? '');
    final nameCtrl =
        TextEditingController(text: _editingUser?.displayName ?? '');
    final pwdCtrl = TextEditingController();
    AdminRole selectedRole = _editingUser?.role ?? AdminRole.contentEditor;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.divider),
              ),
              title: Text(
                _isCreating ? '新增管理员' : '编辑管理员',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      label: '邮箱',
                      controller: emailCtrl,
                      hint: 'name@isee.video',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      label: '姓名',
                      controller: nameCtrl,
                      hint: '显示名称',
                    ),
                    const SizedBox(height: 14),
                    _buildRoleDropdown(ctx2, selectedRole, (r) {
                      setDialogState(() => selectedRole = r);
                    }),
                    if (_isCreating) ...[
                      const SizedBox(height: 14),
                      _buildTextField(
                        label: '初始密码',
                        controller: pwdCtrl,
                        hint: '至少 8 位',
                        obscureText: true,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (emailCtrl.text.trim().isEmpty ||
                        nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请填写邮箱和姓名')),
                      );
                      return;
                    }
                    if (_isCreating && pwdCtrl.text.trim().length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('初始密码至少 6 位')),
                      );
                      return;
                    }

                    final all = ref.read(_adminUsersProvider);
                    final list = List<AdminUser>.from(all);
                    final now = DateTime.now();
                    String avatarSeed =
                        'admin_${DateTime.now().millisecondsSinceEpoch}';

                    if (_isCreating) {
                      final newId =
                          'admin_${(list.length + 1).toString().padLeft(3, '0')}';
                      final newUser = AdminUser(
                        id: newId,
                        email: emailCtrl.text.trim(),
                        displayName: nameCtrl.text.trim(),
                        avatarUrl:
                            'https://picsum.photos/seed/$avatarSeed/200/200',
                        role: selectedRole,
                        createdAt: now,
                        loginCount: 0,
                      );
                      AdminMockRepository.instance.upsertAdminUser(newUser);
                      list.insert(0, newUser);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ 管理员创建成功'),
                          backgroundColor: Color(0xFF4ADE80),
                        ),
                      );
                    } else {
                      final user = _editingUser!;
                      final idx = list.indexWhere((u) => u.id == user.id);
                      if (idx >= 0) {
                        final updated = user.copyWith(
                          email: emailCtrl.text.trim(),
                          displayName: nameCtrl.text.trim(),
                          role: selectedRole,
                        );
                        list[idx] = updated;
                        AdminMockRepository.instance.upsertAdminUser(updated);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ 管理员信息已更新'),
                          backgroundColor: Color(0xFF4ADE80),
                        ),
                      );
                    }
                    ref.read(_adminUsersProvider.notifier).state = list;
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text(_isCreating ? '创建' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppTheme.surfaceLight,
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown(
    BuildContext ctx,
    AdminRole selected,
    ValueChanged<AdminRole> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '角色',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<AdminRole>(
          initialValue: selected,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: AdminRole.values.map((r) {
            return DropdownMenuItem<AdminRole>(
              value: r,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _roleColor(r),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(r.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _PieSegment {
  final int value;
  final Color color;
  _PieSegment({required this.value, required this.color});
}

class _MiniPiePainter extends CustomPainter {
  final List<_PieSegment> segments;
  final int total;

  _MiniPiePainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final innerRadius = radius * 0.55;

    if (total == 0) {
      final paint = Paint()..color = AppTheme.surfaceLight;
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, innerRadius, Paint()..color = AppTheme.surfaceDark);
      return;
    }

    double startAngle = -pi / 2;
    for (final seg in segments) {
      if (seg.value == 0) continue;
      final sweepAngle = (seg.value / total) * 2 * pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    final innerPaint = Paint()..color = AppTheme.surfaceDark;
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniPiePainter oldDelegate) =>
      oldDelegate.total != total || oldDelegate.segments.length != segments.length;
}
