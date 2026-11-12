import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Material Design 3 themes for J'ealth.
abstract final class AppTheme {
  static const String fontFamily = 'PlusJakartaSans';

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.medicalBlue,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD6ECF7),
    onPrimaryContainer: Color(0xFF05344A),
    secondary: AppColors.tealText,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD3F3F1),
    onSecondaryContainer: Color(0xFF064A47),
    tertiary: Color(0xFF4A5FA8),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE1E6FA),
    onTertiaryContainer: Color(0xFF1B2A63),
    error: AppColors.errorText,
    onError: Colors.white,
    errorContainer: Color(0xFFFBE3E3),
    onErrorContainer: Color(0xFF6E1717),
    surface: AppColors.white,
    onSurface: AppColors.darkNavy,
    onSurfaceVariant: Color(0xFF4F607C),
    outline: Color(0xFF7A8AA3),
    outlineVariant: Color(0xFFDAE2EC),
    shadow: Color(0xFF172B4D),
    scrim: Color(0xFF0B1424),
    inverseSurface: Color(0xFF22344F),
    onInverseSurface: Color(0xFFF1F5FA),
    inversePrimary: Color(0xFF8DCFEC),
    surfaceTint: Colors.transparent,
    surfaceDim: Color(0xFFDDE5EE),
    surfaceBright: AppColors.white,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: Color(0xFFF7FAFD),
    surfaceContainer: Color(0xFFF0F4F9),
    surfaceContainerHigh: Color(0xFFE9EFF6),
    surfaceContainerHighest: Color(0xFFE1E8F1),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7CC7E8),
    onPrimary: Color(0xFF00344A),
    primaryContainer: Color(0xFF0F5574),
    onPrimaryContainer: Color(0xFFCDEBFA),
    secondary: Color(0xFF5FD4CE),
    onSecondary: Color(0xFF003734),
    secondaryContainer: Color(0xFF0B5552),
    onSecondaryContainer: Color(0xFFBDF3EF),
    tertiary: Color(0xFFB4C1F5),
    onTertiary: Color(0xFF1B2A63),
    tertiaryContainer: Color(0xFF33437F),
    onTertiaryContainer: Color(0xFFE1E6FA),
    error: Color(0xFFFF9A91),
    onError: Color(0xFF5B0F0F),
    errorContainer: Color(0xFF7A2424),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.nightSurface,
    onSurface: AppColors.nightText,
    onSurfaceVariant: Color(0xFFAAB8CD),
    outline: Color(0xFF7888A2),
    outlineVariant: Color(0xFF2B3B54),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE6EDF7),
    onInverseSurface: Color(0xFF172B4D),
    inversePrimary: AppColors.medicalBlue,
    surfaceTint: Colors.transparent,
    surfaceDim: AppColors.nightBackground,
    surfaceBright: Color(0xFF26354D),
    surfaceContainerLowest: Color(0xFF0A111E),
    surfaceContainerLow: Color(0xFF121C2D),
    surfaceContainer: Color(0xFF19263A),
    surfaceContainerHigh: Color(0xFF1F2D44),
    surfaceContainerHighest: Color(0xFF27364F),
  );

  static ThemeData get light =>
      _build(_lightScheme, AppColors.offWhite, StatusColors.light);

  static ThemeData get dark =>
      _build(_darkScheme, AppColors.nightBackground, StatusColors.dark);

  static ThemeData _build(
    ColorScheme scheme,
    Color background,
    StatusColors status,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      extensions: [status],
    );

    final text = _textTheme(base.textTheme, scheme);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 14);
    final buttonText = text.labelLarge?.copyWith(fontSize: 15);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: inputBorder(scheme.outlineVariant),
        enabledBorder: inputBorder(scheme.outlineVariant),
        disabledBorder: inputBorder(
          scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        helperMaxLines: 4,
        errorMaxLines: 4,
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        hintStyle: text.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surfaceContainerLow,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: 0.45)
                : states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurface,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        checkmarkColor: scheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleSmall?.copyWith(fontSize: 15),
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.primary,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        expandedAlignment: Alignment.topLeft,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? style(
      TextStyle? s, {
      required FontWeight weight,
      double? spacing,
      double? height,
      Color? color,
    }) => s?.copyWith(
      fontFamily: fontFamily,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color ?? scheme.onSurface,
    );

    return base.copyWith(
      displayLarge: style(
        base.displayLarge,
        weight: FontWeight.w700,
        spacing: -1.5,
      ),
      displayMedium: style(
        base.displayMedium,
        weight: FontWeight.w700,
        spacing: -1,
      ),
      displaySmall: style(
        base.displaySmall,
        weight: FontWeight.w700,
        spacing: -0.8,
      ),
      headlineLarge: style(
        base.headlineLarge,
        weight: FontWeight.w700,
        spacing: -0.8,
      ),
      headlineMedium: style(
        base.headlineMedium,
        weight: FontWeight.w700,
        spacing: -0.6,
      ),
      headlineSmall: style(
        base.headlineSmall,
        weight: FontWeight.w700,
        spacing: -0.4,
      ),
      titleLarge: style(
        base.titleLarge,
        weight: FontWeight.w700,
        spacing: -0.3,
      ),
      titleMedium: style(
        base.titleMedium,
        weight: FontWeight.w600,
        spacing: -0.1,
      ),
      titleSmall: style(base.titleSmall, weight: FontWeight.w600, spacing: 0),
      bodyLarge: style(
        base.bodyLarge,
        weight: FontWeight.w400,
        spacing: 0,
        height: 1.5,
      ),
      bodyMedium: style(
        base.bodyMedium,
        weight: FontWeight.w400,
        spacing: 0,
        height: 1.5,
      ),
      bodySmall: style(
        base.bodySmall,
        weight: FontWeight.w400,
        spacing: 0.1,
        height: 1.45,
      ),
      labelLarge: style(base.labelLarge, weight: FontWeight.w600, spacing: 0.1),
      labelMedium: style(
        base.labelMedium,
        weight: FontWeight.w600,
        spacing: 0.2,
      ),
      labelSmall: style(base.labelSmall, weight: FontWeight.w600, spacing: 0.3),
    );
  }
}
