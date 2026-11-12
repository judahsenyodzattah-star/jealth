import 'package:material_ui/material_ui.dart';

/// Formats a number without a trailing ".0" (105.0 -> "105", 23.5 -> "23.5").
String formatNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final fixed = value.toStringAsFixed(2);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Formats a 0..1 metric with three decimals ("0.505").
String formatMetric(double value) => value.toStringAsFixed(3);

/// Formats a 0..1 ratio as a whole percentage ("56%").
String formatPercent(double value) => '${(value * 100).round()}%';

/// Formats an optional model score exactly as a plain number ("0.6802").
String formatModelScore(double value) {
  final fixed = value.toStringAsFixed(4);
  return fixed.replaceFirst(RegExp(r'0{1,2}$'), '');
}

/// Locale-aware "12 Nov 2026, 14:05" style date and time.
String formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final l10n = MaterialLocalizations.of(context);
  // Includes the year: saved records can be much older than this week.
  final date = '${l10n.formatShortMonthDay(local)}, ${local.year}';
  final time = l10n.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date, $time';
}

/// Locale-independent timestamp for plain-text exports ("2026-11-12 14:05").
String formatTimestampPlain(DateTime value) {
  final v = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${v.year}-${two(v.month)}-${two(v.day)} ${two(v.hour)}:${two(v.minute)}';
}
