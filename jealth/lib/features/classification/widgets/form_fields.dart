import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../models/patient_field.dart';
import '../validation/field_validators.dart';

/// Text field for one numeric assessment input.
class NumericInputField extends StatelessWidget {
  const NumericInputField({
    super.key,
    required this.field,
    required this.controller,
    required this.onChanged,
    required this.errorText,
    required this.enabled,
    required this.textInputAction,
    this.onSubmitted,
  });

  final PatientField field;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = StatusColors.of(context);
    final whole = field.isWholeNumber;
    final advisory = FieldValidators.trainingRangeAdvisory(
      field,
      controller.text,
    );
    final helper = field.helper;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: ValueKey('field-${field.name}'),
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted?.call(),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: textInputAction,
          keyboardType: TextInputType.numberWithOptions(decimal: !whole),
          inputFormatters: [
            whole
                ? FilteringTextInputFormatter.digitsOnly
                : const _DecimalTextInputFormatter(),
            LengthLimitingTextInputFormatter(whole ? 4 : 8),
          ],
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: field.labelWithUnit,
            prefixIcon: Icon(field.icon),
            helperText: helper,
            errorText: errorText,
          ),
        ),
        if (advisory != null && errorText == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: status.warning,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      advisory,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: status.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Allows digits with a single "." or "," decimal separator.
class _DecimalTextInputFormatter extends TextInputFormatter {
  const _DecimalTextInputFormatter();

  static final RegExp _pattern = RegExp(r'^\d*[.,]?\d{0,2}$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _pattern.hasMatch(newValue.text) ? newValue : oldValue;
}

/// Two-option selector for a categorical model input.
class ChoiceInputField<T extends Object> extends StatelessWidget {
  const ChoiceInputField({
    super.key,
    required this.field,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
    required this.errorText,
    required this.enabled,
  });

  final PatientField field;
  final List<T> options;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      label: field.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                Icon(field.icon, size: 20, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(field.label, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<T>(
            key: ValueKey('field-${field.name}'),
            segments: [
              for (final option in options)
                ButtonSegment<T>(value: option, label: Text(labelOf(option))),
            ],
            selected: {?selected},
            emptySelectionAllowed: true,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isNotEmpty) onSelected(selection.first);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: errorText != null
                ? Semantics(
                    liveRegion: true,
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  )
                : Text(
                    field.helper,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
