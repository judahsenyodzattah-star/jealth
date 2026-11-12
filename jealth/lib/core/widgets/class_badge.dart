import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../features/classification/models/prediction_result.dart';

/// Colours and icon used to present a predicted class.
///
/// The tones are deliberately informational (blue / amber) rather than
/// "good / bad" (green / red): a model output is not a verdict.
class ClassPresentation {
  const ClassPresentation._(
    this.icon,
    this.accent,
    this.container,
    this.onContainer,
  );

  final IconData icon;
  final Color accent;
  final Color container;
  final Color onContainer;

  factory ClassPresentation.of(BuildContext context, HeartDiseaseClass value) {
    final status = StatusColors.of(context);
    return switch (value) {
      HeartDiseaseClass.heartDisease => ClassPresentation._(
        Icons.monitor_heart_outlined,
        status.warning,
        status.warningContainer,
        status.onWarningContainer,
      ),
      HeartDiseaseClass.noHeartDisease => ClassPresentation._(
        Icons.favorite_border_rounded,
        status.info,
        status.infoContainer,
        status.onInfoContainer,
      ),
    };
  }
}

/// Compact pill naming a predicted class.
class ClassBadge extends StatelessWidget {
  const ClassBadge({super.key, required this.predictedClass});

  final HeartDiseaseClass predictedClass;

  @override
  Widget build(BuildContext context) {
    final look = ClassPresentation.of(context, predictedClass);
    return Semantics(
      label: 'Model predicted class: ${predictedClass.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: look.container,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(look.icon, size: 16, color: look.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                predictedClass.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: look.onContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
