import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();
  runApp(
    // Failed providers are surfaced to the UI with an explicit "Try again"
    // action rather than being retried silently in the background.
    ProviderScope(retry: (retryCount, error) => null, child: const JealthApp()),
  );
}

/// Adds the bundled typeface's licence to the in-app "Licenses" page.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    try {
      final license = await rootBundle.loadString('assets/fonts/OFL.txt');
      yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], license);
    } catch (error) {
      // A missing licence asset must not break the Licenses page.
      debugPrint('Font licence asset unavailable: $error');
    }
  });
}
