import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../classification/models/patient_field.dart';
import '../../history/models/history_record.dart';

/// What happened when the user asked to share.
enum ShareOutcome {
  /// Handed over to the platform share sheet.
  shared,

  /// The user closed the share sheet without sharing.
  dismissed,

  /// Sharing is not supported here; the text was copied to the clipboard.
  copiedToClipboard,

  /// Neither sharing nor copying worked.
  failed,
}

/// Shares plain text. Only ever called from an explicit user action.
abstract interface class ShareService {
  Future<ShareOutcome> shareText(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  });
}

/// Uses the platform share sheet and falls back to the clipboard where
/// sharing is unsupported (for example desktop browsers without Web Share).
class PlatformShareService implements ShareService {
  const PlatformShareService();

  @override
  Future<ShareOutcome> shareText(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
          mailToFallbackEnabled: false,
        ),
      );
      switch (result.status) {
        case ShareResultStatus.success:
          return ShareOutcome.shared;
        case ShareResultStatus.dismissed:
          return ShareOutcome.dismissed;
        case ShareResultStatus.unavailable:
          // Some platforms cannot report what happened after the sheet opened.
          return ShareOutcome.shared;
      }
    } catch (error) {
      debugPrint('Platform sharing unavailable: $error');
    }
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ShareOutcome.copiedToClipboard;
    } catch (error) {
      debugPrint('Clipboard unavailable: $error');
      return ShareOutcome.failed;
    }
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => const PlatformShareService(),
);

/// Builds the plain-text summary of a classification.
///
/// Patient measurements are included only when [includeMeasurements] is true,
/// which the user must switch on explicitly.
String buildShareText(
  HistoryRecord record, {
  required bool includeMeasurements,
}) {
  final buffer = StringBuffer()
    ..writeln("${AppConstants.appName} - experimental assessment result")
    ..writeln('Assessment result: ${record.predictedClass.label}')
    ..writeln('Classified: ${formatTimestampPlain(record.timestamp)}');
  if (includeMeasurements) {
    buffer
      ..writeln()
      ..writeln('Submitted measurements:');
    for (final field in PatientField.values) {
      buffer.writeln(
        '- ${field.label}: ${field.displayValueWithUnit(record.input)}',
      );
    }
  }
  buffer
    ..writeln()
    ..write(AppConstants.resultDisclaimer);
  return buffer.toString();
}
