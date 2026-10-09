import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../data/providers/admin_auth_provider.dart';

class AdminAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? searchField;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.searchField,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  ConsumerState<AdminAppBar> createState() => _AdminAppBarState();
}

class _AdminAppBarState extends ConsumerState<AdminAppBar> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    final user = auth.user;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 32),
          if (widget.searchField != null)
            Expanded(child: widget.searchField!)
          else
            const Spacer(),
          if (widget.searchField != null) const SizedBox(width: 24),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('暂无新通知')),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.textSecondary,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: '通知',
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(
              Icons.visibility_rounded,
              color: AppTheme.textSecondary,
            ),
            tooltip: '前往前台',
          ),
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 8),
          if (user != null) _buildUserMenu(context, user),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, dynamic user) {
    return PopupMenuButton<String>(
      tooltip: user.displayName,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.label,
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: const [
              Icon(Icons.settings_outlined,
                  size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 10),
              Text('系统设置',
                  style: TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout_rounded,
                  size: 18, color: AppTheme.primaryRed),
              SizedBox(width: 10),
              Text('退出登录',
                  style:
                      TextStyle(color: AppTheme.primaryRed, fontSize: 13)),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(adminAuthProvider.notifier).logout();
          if (mounted) {
            context.go('/admin/login');
          }
        } else if (value == 'settings') {
          context.go('/admin/settings');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(user.avatarUrl),
            ),
          ],
        ),
      ),
    );
  }
}
