import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/class_badge.dart';
import '../../classification/models/patient_field.dart';
import '../models/history_record.dart';

/// One saved classification in a list.
class HistoryRecordTile extends StatelessWidget {
  const HistoryRecordTile({
    super.key,
    required this.record,
    required this.onTap,
    this.onDelete,
  });

  final HistoryRecord record;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  /// One-line summary of a few measurements.
  static String summary(HistoryRecord record) {
    final input = record.input;
    return [
      'Age ${input.age}',
      input.sex.apiValue,
      'BP ${PatientField.bloodPressure.displayValue(input)}',
      'Chol. ${PatientField.cholesterol.displayValue(input)}',
      'BMI ${PatientField.bmi.displayValue(input)}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final look = ClassPresentation.of(context, record.predictedClass);
    final date = formatDateTime(context, record.timestamp);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label:
            'Assessment result: ${record.predictedClass.label}. '
                  '$date. ${summary(record)}. Open details.',
              excludeSemantics: true,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: look.container,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(look.icon, color: look.accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.predictedClass.label,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              date,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary(record),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onDelete == null)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onDelete != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                onPressed: onDelete,
                tooltip: 'Delete record',
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ),
        ],
      ),
    );
  }
}
