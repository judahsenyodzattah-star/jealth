import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// Rounded surface with a soft shadow (light theme) or hairline border (dark
/// theme). Becomes an accessible button when [onTap] is provided.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.gradient,
    this.borderColor,
    this.semanticLabel,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final String? semanticLabel;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      );
    }

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? scheme.surface) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(
          color:
              borderColor ??
              (gradient != null
                  ? Colors.transparent
                  : scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          if (status.cardShadow.a > 0)
            BoxShadow(
              color: status.cardShadow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );

    if (onTap == null || semanticLabel == null) return card;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: card,
    );
  }
}
