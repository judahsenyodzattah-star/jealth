import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';

/// Titled card with paragraphs and optional bullet points, used by the
/// Privacy, About and Model information screens.
class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.icon,
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
    this.child,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(paragraph, style: theme.textTheme.bodyMedium),
            ),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(bullet, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}
