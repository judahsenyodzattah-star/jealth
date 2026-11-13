import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/class_badge.dart';
import '../../../core/widgets/measurements_view.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../classification/models/prediction_result.dart';
import '../../history/models/history_record.dart';

/// Careful, non-diagnostic wording for each class.
String classExplanation(HeartDiseaseClass predictedClass) =>
    switch (predictedClass) {
      HeartDiseaseClass.heartDisease =>
        'The assessment returned “Heart Disease” for these measurements. '
            'This is not a diagnosis and does not confirm that the patient '
            'has heart disease.',
      HeartDiseaseClass.noHeartDisease =>
        'The assessment returned “No Heart Disease” for these measurements. '
            'This does not rule out heart disease.',
    };

/// Full presentation of one classification: predicted class, explanation,
/// result details, the submitted measurements and the disclaimer.
/// Shared by the result screen and the history detail screen.
class ResultSummary extends StatelessWidget {
  const ResultSummary({super.key, required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final look = ClassPresentation.of(context, record.predictedClass);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: look.container,
          borderColor: look.accent.withValues(alpha: 0.3),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(look.icon, size: 30, color: look.accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Semantics(
                      header: true,
                      label: 'Assessment result: ${record.predictedClass.label}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ASSESSMENT RESULT',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: look.onContainer.withValues(alpha: 0.85),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.predictedClass.label,
                            key: const ValueKey('result-class-label'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: look.onContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                classExplanation(record.predictedClass),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: look.onContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Result details',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Classified',
                value: formatDateTime(context, record.timestamp),
              ),
              if (record.modelScore case final score?)
                _DetailRow(
                  icon: Icons.analytics_outlined,
                  label: 'Model score',
                  value: formatModelScore(score),
                ),
              if (record.modelVersion case final version?)
                _DetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Model version',
                  value: version,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Submitted measurements',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 14),
              MeasurementsView(input: record.input),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const NoticeBanner(
          tone: NoticeTone.warning,
          icon: Icons.info_outline_rounded,
          title: 'Important information',
          message: AppConstants.resultDisclaimer,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MergeSemantics(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(value, style: theme.textTheme.titleSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
