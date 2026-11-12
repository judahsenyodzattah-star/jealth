import 'package:material_ui/material_ui.dart';

import '../../features/classification/models/patient_field.dart';
import '../../features/classification/models/patient_input.dart';

/// Responsive grid listing the ten submitted measurements.
class MeasurementsView extends StatelessWidget {
  const MeasurementsView({super.key, required this.input});

  final PatientInput input;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 640
            ? 3
            : (constraints.maxWidth >= 330 ? 2 : 1);
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final field in PatientField.values)
              SizedBox(
                width: itemWidth,
                child: _MeasurementTile(
                  field: field,
                  value: field.displayValueWithUnit(input),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({required this.field, required this.value});

  final PatientField field;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '${field.label}: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Icon(field.icon, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }
}
