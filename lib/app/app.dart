import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/router/app_router.dart';
import '../core/utils/sentry_setup.dart';

class IseeApp extends ConsumerWidget {
  const IseeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'iSee - 流媒体视频平台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: kSentryEnabled
          ? (context, child) {
              Widget root = child ?? const SizedBox.shrink();
              try {
                final navigator = Navigator.of(context);
                // ignore: avoid_print
                assert(() {
                  debugPrint('Sentry: navigator context=${navigator.context.widget.runtimeType}');
                  return true;
                }());
              } catch (_) {}
              return root;
            }
          : null,
    );
  }
}
