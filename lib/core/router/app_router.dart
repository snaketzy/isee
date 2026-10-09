import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/mylist/presentation/pages/my_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/video_detail/presentation/pages/video_detail_page.dart';
import '../../features/video_player/presentation/pages/video_player_page.dart';
import '../../features/video_player/presentation/pages/video_player_official_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/shell/presentation/pages/main_shell.dart';

import '../../features/admin/data/providers/admin_auth_provider.dart';
import '../../features/admin/presentation/widgets/admin_shell.dart';
import '../../features/admin/presentation/widgets/admin_app_bar.dart';
import '../../features/admin/presentation/pages/admin_login_page.dart';
import '../../features/admin/presentation/pages/dashboard_page.dart';
import '../../features/admin/presentation/pages/content_list_page.dart';
import '../../features/admin/presentation/pages/content_edit_page.dart';
import '../../features/admin/presentation/pages/category_manage_page.dart';
import '../../features/admin/presentation/pages/upload_queue_page.dart';
import '../../features/admin/presentation/pages/mux_assets_page.dart';
import '../../features/admin/presentation/pages/r2_storage_page.dart';
import '../../features/admin/presentation/pages/users_list_page.dart';
import '../../features/admin/presentation/pages/user_detail_page.dart';
import '../../features/admin/presentation/pages/membership_plans_page.dart';
import '../../features/admin/presentation/pages/analytics_page.dart';
import '../../features/admin/presentation/pages/admin_staff_page.dart';
import '../../features/admin/presentation/pages/system_settings_page.dart';

class _AdminShellPage extends StatelessWidget {
  final Widget child;
  final String title;
  const _AdminShellPage({
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      pageTitle: title,
      appBar: AdminAppBar(title: title),
      child: child,
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AdminAuthListenable(ref);
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final path = state.uri.path;
      final isAdminRoute = path.startsWith('/admin');
      final authState = ref.read(adminAuthProvider);
      final loggedIn = authState.isAuthenticated;
      if (isAdminRoute && path != '/admin/login' && !loggedIn) {
        final target = Uri.encodeQueryComponent(state.uri.toString());
        return '/admin/login?redirect=$target';
      }
      if (path == '/admin/login' && loggedIn) {
        return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/mylist',
            name: 'mylist',
            builder: (context, state) => const MyListPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/detail/:id',
        name: 'detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VideoDetailPage(videoId: id);
        },
      ),
      GoRoute(
        path: '/player/:id',
        name: 'player',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final episodeIndex = state.uri.queryParameters['episode'] ?? '0';
          final engine = state.uri.queryParameters['engine'] ?? 'official';
          if (engine == 'mk' || engine == 'media_kit') {
            return VideoPlayerPage(
              videoId: id,
              episodeIndex: int.tryParse(episodeIndex) ?? 0,
            );
          }
          return VideoPlayerOfficialPage(
            videoId: id,
            episodeIndex: int.tryParse(episodeIndex) ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/player-mk/:id',
        name: 'player-mk',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final episodeIndex = state.uri.queryParameters['episode'] ?? '0';
          return VideoPlayerPage(
            videoId: id,
            episodeIndex: int.tryParse(episodeIndex) ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return AdminLoginPage(redirect: redirect);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          String title = '管理后台';
          final path = state.uri.path;
          if (path.startsWith('/admin/dashboard')) {
            title = '仪表盘';
          } else if (path.startsWith('/admin/content/new')) {
            title = '新建内容';
          } else if (path.startsWith('/admin/content/edit')) {
            title = '编辑内容';
          } else if (path.startsWith('/admin/content')) {
            title = '内容管理';
          } else if (path.startsWith('/admin/categories')) {
            title = '分类与榜单';
          } else if (path.startsWith('/admin/upload')) {
            title = '上传队列';
          } else if (path.startsWith('/admin/mux')) {
            title = 'Mux 资产';
          } else if (path.startsWith('/admin/r2')) {
            title = 'R2 存储';
          } else if (path.startsWith('/admin/users/')) {
            title = '用户详情';
          } else if (path.startsWith('/admin/users')) {
            title = '用户管理';
          } else if (path.startsWith('/admin/membership')) {
            title = '会员套餐';
          } else if (path.startsWith('/admin/analytics')) {
            title = '数据分析';
          } else if (path.startsWith('/admin/staff')) {
            title = '管理员账户';
          } else if (path.startsWith('/admin/settings')) {
            title = '系统设置';
          }
          return _AdminShellPage(
            title: title,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/admin/content',
            name: 'admin-content',
            builder: (context, state) => const ContentListPage(),
          ),
          GoRoute(
            path: '/admin/content/new',
            name: 'admin-content-new',
            builder: (context, state) => const ContentEditPage(),
          ),
          GoRoute(
            path: '/admin/content/edit/:id',
            name: 'admin-content-edit',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return ContentEditPage(id: id);
            },
          ),
          GoRoute(
            path: '/admin/categories',
            name: 'admin-categories',
            builder: (context, state) => const CategoryManagePage(),
          ),
          GoRoute(
            path: '/admin/upload',
            name: 'admin-upload',
            builder: (context, state) => const UploadQueuePage(),
          ),
          GoRoute(
            path: '/admin/mux',
            name: 'admin-mux',
            builder: (context, state) => const MuxAssetsPage(),
          ),
          GoRoute(
            path: '/admin/r2',
            name: 'admin-r2',
            builder: (context, state) => const R2StoragePage(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'admin-users',
            builder: (context, state) => const UsersListPage(),
          ),
          GoRoute(
            path: '/admin/users/:id',
            name: 'admin-user-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return UserDetailPage(id: id);
            },
          ),
          GoRoute(
            path: '/admin/membership',
            name: 'admin-membership',
            builder: (context, state) => const MembershipPlansPage(),
          ),
          GoRoute(
            path: '/admin/analytics',
            name: 'admin-analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: '/admin/staff',
            name: 'admin-staff',
            builder: (context, state) => const AdminStaffPage(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'admin-settings',
            builder: (context, state) => const SystemSettingsPage(),
          ),
        ],
      ),
    ],
  );
});

class _AdminAuthListenable extends ChangeNotifier {
  _AdminAuthListenable(Ref ref) {
    ref.listen(adminAuthProvider, (_, __) => notifyListeners());
  }
}
