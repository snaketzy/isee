import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const String kSentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);

const String kSentryEnvironment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: kReleaseMode
      ? 'production'
      : kDebugMode
          ? 'debug'
          : 'profile',
);

const String kSentryRelease = String.fromEnvironment(
  'SENTRY_RELEASE',
  defaultValue: 'isee@0.1.0+1',
);

const bool kIncludeAdmin = bool.fromEnvironment(
  'INCLUDE_ADMIN',
  defaultValue: true,
);

bool get kSentryEnabled => kSentryDsn.isNotEmpty;

Future<void> bootstrapWithSentry(Future<void> Function() appRunner) async {
  if (kSentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options
          ..dsn = kSentryDsn
          ..environment = kSentryEnvironment
          ..release = kSentryRelease
          ..tracesSampleRate = 1.0
          ..enableAutoNativeBreadcrumbs = true
          ..reportPackages = true
          ..reportSilentFlutterErrors = true;
        try {
          // ignore: avoid_dynamic_calls, deprecated_member_use_from_same_package
          options.profilesSampleRate = 1.0;
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {}
      },
      appRunner: () async {
        if (kIncludeAdmin || true) {
          try {
            final extras = <String, String>{
              'build_features.include_admin': kIncludeAdmin.toString(),
              'build_features.platform': defaultTargetPlatform.name,
            };
            // ignore: deprecated_member_use
            Sentry.configureScope((scope) {
              for (final entry in extras.entries) {
                scope.setExtra(entry.key, entry.value);
              }
            });
            // ignore: avoid_catches_without_on_clauses
          } catch (_) {}
        }
        await appRunner();
      },
    );
  } else {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrintSynchronously(
          '[Sentry:disabled] FlutterError: ${details.exceptionAsString()}\n'
          '${details.stack}',
        );
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrintSynchronously('[Sentry:disabled] Uncaught: $error\n$stack');
      }
      return true;
    };
    await appRunner();
  }
}
