import 'package:material_ui/material_ui.dart';

/// Window-size classes used for responsive layout decisions.
abstract final class Breakpoints {
  /// Below this width: bottom navigation bar and single-column content.
  static const double medium = 600;

  /// From this width: two-column content where it helps.
  static const double expanded = 900;

  /// From this width: extended navigation rail with labels beside icons.
  static const double large = 1200;

  /// Maximum width of readable page content.
  static const double maxContentWidth = 1080;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < medium;
}
