import 'package:material_ui/material_ui.dart';

/// J'ealth brand palette.
abstract final class AppColors {
  // Brand.
  static const Color medicalBlue = Color(0xFF146C94);
  static const Color teal = Color(0xFF16A6A1);
  static const Color offWhite = Color(0xFFF5F8FC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkNavy = Color(0xFF172B4D);
  static const Color success = Color(0xFF2E8B57);
  static const Color warning = Color(0xFFE9A23B);
  static const Color error = Color(0xFFD64545);

  /// Slightly deeper shades of the brand status colours, used wherever the
  /// colour carries small text on a light surface (WCAG AA, 4.5:1).
  static const Color successText = Color(0xFF237048);
  static const Color warningText = Color(0xFF8A5A00);
  static const Color errorText = Color(0xFFC23838);
  static const Color tealText = Color(0xFF0B7A76);

  // Dark theme foundations.
  static const Color nightBackground = Color(0xFF0D1626);
  static const Color nightSurface = Color(0xFF152033);
  static const Color nightText = Color(0xFFE6EDF7);

  /// Signature gradient used on the logo, hero cards and primary highlights.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [medicalBlue, teal],
  );

  /// Darker variant that keeps white text readable across the whole surface.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F5B7E), Color(0xFF146C94), Color(0xFF0F7F86)],
    stops: [0, 0.55, 1],
  );
}

/// Semantic status colours that are not part of [ColorScheme].
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.cardShadow,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color cardShadow;

  static const StatusColors light = StatusColors(
    success: AppColors.successText,
    successContainer: Color(0xFFE0F3E8),
    onSuccessContainer: Color(0xFF12482C),
    warning: AppColors.warningText,
    warningContainer: Color(0xFFFCF0DA),
    onWarningContainer: Color(0xFF5E3D00),
    info: AppColors.medicalBlue,
    infoContainer: Color(0xFFE1F0F8),
    onInfoContainer: Color(0xFF0A3E57),
    cardShadow: Color(0x14172B4D),
  );

  static const StatusColors dark = StatusColors(
    success: Color(0xFF7FD6A4),
    successContainer: Color(0xFF16402A),
    onSuccessContainer: Color(0xFFC4F0D6),
    warning: Color(0xFFF4C16F),
    warningContainer: Color(0xFF4A3508),
    onWarningContainer: Color(0xFFFCE3B4),
    info: Color(0xFF7CC7E8),
    infoContainer: Color(0xFF123F57),
    onInfoContainer: Color(0xFFCDEBFA),
    cardShadow: Color(0x00000000),
  );

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>() ?? light;

  @override
  StatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? cardShadow,
  }) {
    return StatusColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}
