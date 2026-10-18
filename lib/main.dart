import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app/app.dart';
import 'core/utils/sentry_setup.dart';

Future<void> main() async {
  await bootstrapWithSentry(() async {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    final Widget app;
    if (kSentryEnabled) {
      app = ProviderScope(
        child: DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: const IseeApp(),
        ),
      );
      runApp(
        SentryUserInteractionWidget(
          child: SentryScreenshotWidget(
            child: app,
          ),
        ),
      );
    } else {
      app = const ProviderScope(
        child: IseeApp(),
      );
      runApp(app);
    }
  });
}
