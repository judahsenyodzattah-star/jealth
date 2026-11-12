import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../constants/app_constants.dart';

enum NoticeTone { info, warning, success, error, neutral }

/// Inline, non-modal notice with an icon, optional title and optional action.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = NoticeTone.info,
    this.icon,
    this.action,
  });

  /// The standard educational-use notice.
  const NoticeBanner.educational({super.key, this.action})
    : title = 'For education only',
      message = AppConstants.educationalNotice,
      tone = NoticeTone.warning,
      icon = Icons.school_outlined;

  final String message;
  final String? title;
  final NoticeTone tone;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);

    final (
      Color background,
      Color foreground,
      Color accent,
      IconData defaultIcon,
    ) = switch (tone) {
      NoticeTone.info => (
        status.infoContainer,
        status.onInfoContainer,
        status.info,
        Icons.info_outline_rounded,
      ),
      NoticeTone.warning => (
        status.warningContainer,
        status.onWarningContainer,
        status.warning,
        Icons.warning_amber_rounded,
      ),
      NoticeTone.success => (
        status.successContainer,
        status.onSuccessContainer,
        status.success,
        Icons.check_circle_outline_rounded,
      ),
      NoticeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        scheme.error,
        Icons.error_outline_rounded,
      ),
      NoticeTone.neutral => (
        scheme.surfaceContainer,
        scheme.onSurface,
        scheme.onSurfaceVariant,
        Icons.info_outline_rounded,
      ),
    };

    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon ?? defaultIcon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: action,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
