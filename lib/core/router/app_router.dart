import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/mylist/presentation/pages/my_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/video_detail/presentation/pages/video_detail_page.dart';
import '../../features/video_player/presentation/pages/video_player_page.dart';
import '../../features/video_player/presentation/pages/video_player_official_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/shell/presentation/pages/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
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
    ],
  );
});
