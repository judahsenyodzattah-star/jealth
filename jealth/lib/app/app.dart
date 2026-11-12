import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/constants/app_constants.dart';
import '../features/settings/providers/theme_controller.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget of J'ealth.
class JealthApp extends ConsumerWidget {
  const JealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeControllerProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Honour the user's text size while keeping layouts usable at the
        // extreme end of the accessibility range.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 2.0,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
