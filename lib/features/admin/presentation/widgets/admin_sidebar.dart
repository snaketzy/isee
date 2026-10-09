import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MenuItem {
  final String route;
  final String label;
  final IconData icon;
  final String permission;

  const _MenuItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.permission,
  });
}

class AdminSidebar extends ConsumerStatefulWidget {
  final bool collapsed;
  final VoidCallback onToggle;

  const AdminSidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  ConsumerState<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<AdminSidebar> {
  static const _menu = <_MenuItem>[
    _MenuItem(
      route: '/admin/dashboard',
      label: '仪表盘',
      icon: Icons.dashboard_rounded,
      permission: 'dashboard.view',
    ),
    _MenuItem(
      route: '/admin/content',
      label: '内容管理',
      icon: Icons.movie_creation_rounded,
      permission: 'content.view',
    ),
    _MenuItem(
      route: '/admin/categories',
      label: '分类与榜单',
      icon: Icons.playlist_play_rounded,
      permission: 'content.edit',
    ),
    _MenuItem(
      route: '/admin/upload',
      label: '上传队列',
      icon: Icons.cloud_upload_rounded,
      permission: 'media.upload',
    ),
    _MenuItem(
      route: '/admin/mux',
      label: 'Mux 资产',
      icon: Icons.smart_display_rounded,
      permission: 'media.view',
    ),
    _MenuItem(
      route: '/admin/r2',
      label: 'R2 存储',
      icon: Icons.storage_rounded,
      permission: 'media.view',
    ),
    _MenuItem(
      route: '/admin/users',
      label: '用户管理',
      icon: Icons.people_alt_rounded,
      permission: 'users.view',
    ),
    _MenuItem(
      route: '/admin/membership',
      label: '会员套餐',
      icon: Icons.card_membership_rounded,
      permission: 'subscription.view',
    ),
    _MenuItem(
      route: '/admin/analytics',
      label: '数据分析',
      icon: Icons.analytics_rounded,
      permission: 'analytics.view',
    ),
    _MenuItem(
      route: '/admin/staff',
      label: '管理员账户',
      icon: Icons.admin_panel_settings_rounded,
      permission: 'admin.manage',
    ),
    _MenuItem(
      route: '/admin/settings',
      label: '系统设置',
      icon: Icons.settings_rounded,
      permission: 'settings.manage',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    final items = _menu
        .where((m) => auth.user == null || auth.user!.hasPermission(m.permission))
        .toList();
    final width = widget.collapsed ? 72.0 : 256.0;
    final currentPath = GoRouterState.of(context).uri.path;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          right: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppTheme.divider),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = currentPath.startsWith(item.route);
                return _buildMenuItem(context, item, selected);
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 12 : 20, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'i',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (!widget.collapsed) ...[
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'iSEE',
                      style: TextStyle(
                        color: AppTheme.primaryRed,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    Text(
                      '管理后台',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, _MenuItem item, bool selected) {
    return Tooltip(
      message: widget.collapsed ? item.label : '',
      preferBelow: false,
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 14 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryRed.withOpacity(0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(color: AppTheme.primaryRed.withOpacity(0.35))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: selected
                    ? AppTheme.primaryRed
                    : AppTheme.textSecondary,
                size: 22,
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return InkWell(
      onTap: widget.onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 10 : 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              widget.collapsed
                  ? Icons.keyboard_arrow_right_rounded
                  : Icons.keyboard_arrow_left_rounded,
              color: AppTheme.textMuted,
              size: 22,
            ),
            if (!widget.collapsed) ...[
              const SizedBox(width: 12),
              const Text(
                '收起侧栏',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
