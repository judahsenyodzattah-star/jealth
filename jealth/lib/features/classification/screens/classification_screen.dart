import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/prediction_service.dart';
import '../models/patient_field.dart';
import '../models/patient_input.dart';
import '../providers/classification_form_controller.dart';
import '../providers/prediction_controller.dart';
import '../widgets/form_fields.dart';

/// The patient classification form: ten model inputs, validation, reset and
/// submission to the prediction service.
class ClassificationScreen extends ConsumerStatefulWidget {
  const ClassificationScreen({super.key});

  @override
  ConsumerState<ClassificationScreen> createState() =>
      _ClassificationScreenState();
}

class _ClassificationScreenState extends ConsumerState<ClassificationScreen> {
  static final List<PatientField> _numericFields = PatientField.values
      .where((f) => f.isNumeric)
      .toList(growable: false);

  late final Map<PatientField, TextEditingController> _controllers;
  final Map<PatientField, GlobalKey> _fieldKeys = {
    for (final field in PatientField.values) field: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final form = ref.read(classificationFormControllerProvider);
    _controllers = {
      for (final field in _numericFields)
        field: TextEditingController(text: form.textOf(field)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ClassificationFormController get _form =>
      ref.read(classificationFormControllerProvider.notifier);

  void _syncControllers(ClassificationFormState state) {
    for (final entry in _controllers.entries) {
      final text = state.textOf(entry.key);
      if (entry.value.text != text) entry.value.text = text;
    }
  }

  void _reset() {
    FocusManager.instance.primaryFocus?.unfocus();
    final previous = _form.reset();
    showAppSnackBar(
      context,
      'Form cleared.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => _form.restore(previous),
      ),
    );
  }

  Future<void> _predict() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final input = _form.submit();
    if (input == null) {
      final state = ref.read(classificationFormControllerProvider);
      final invalid = PatientField.values
          .where((f) => state.errorFor(f) != null)
          .toList();
      showAppSnackBar(
        context,
        invalid.length == 1
            ? '1 field needs attention.'
            : '${invalid.length} fields need attention.',
        isError: true,
      );
      final target = _fieldKeys[invalid.first]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
        );
      }
      return;
    }

    // The controller ignores calls while a request is already running.
    await ref.read(predictionControllerProvider.notifier).submit(input);
    if (!mounted) return;
    context.go(AppRoutes.result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final form = ref.watch(classificationFormControllerProvider);
    final loading =
        ref.watch(predictionControllerProvider) is PredictionLoading;
    final serviceConfigured = ref.watch(predictionServiceProvider).isConfigured;

    // Reset / Undo replace the text shown in the fields.
    ref.listen(
      classificationFormControllerProvider.select((s) => s.resetCount),
      (_, _) =>
          _syncControllers(ref.read(classificationFormControllerProvider)),
    );

    String? errorFor(PatientField field) =>
        form.showErrors ? form.errorFor(field) : null;

    Widget numeric(PatientField field) {
      final isLast = field == _numericFields.last;
      return KeyedSubtree(
        key: _fieldKeys[field],
        child: NumericInputField(
          field: field,
          controller: _controllers[field]!,
          enabled: !loading,
          errorText: errorFor(field),
          onChanged: (value) => _form.setText(field, value),
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: isLast
              ? () => FocusManager.instance.primaryFocus?.unfocus()
              : null,
        ),
      );
    }

    Widget yesNo(PatientField field) => KeyedSubtree(
      key: _fieldKeys[field],
      child: ChoiceInputField<YesNo>(
        field: field,
        options: YesNo.values,
        labelOf: (v) => v.apiValue,
        selected: form.yesNoOf(field),
        enabled: !loading,
        errorText: errorFor(field),
        onSelected: (value) => _form.setYesNo(field, value),
      ),
    );

    final completed = form.completedCount;
    final total = PatientField.values.length;

    return Scaffold(
      appBar: const JealthAppBar(title: 'Health assessment'),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: PageBody(
          maxWidth: 880,
          spacing: 20,
          children: [
            const SectionHeader(
              title: 'Your health assessment',
              subtitle:
                  'Enter the ten measurements used by the assessment service. '
                  'No names, addresses or identification numbers are collected.',
              padding: EdgeInsets.zero,
            ),
            if (!serviceConfigured)
              NoticeBanner(
                tone: NoticeTone.warning,
                icon: Icons.cloud_off_outlined,
            title: 'Assessment service unavailable',
                message:
                'You can complete the form, but an assessment cannot be '
                'produced until the service is available. Nothing is simulated.',
                action: TextButton(
                  onPressed: () => context.push(AppRoutes.settings),
                  child: const Text('Service settings'),
                ),
              ),
            Semantics(
              label: '$completed of $total fields complete',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '$completed of $total fields complete',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completed / total,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            _FormSection(
              icon: Icons.person_outline_rounded,
              title: 'Patient profile',
              children: [
                numeric(PatientField.age),
                KeyedSubtree(
                  key: _fieldKeys[PatientField.sex],
                  child: ChoiceInputField<Sex>(
                    field: PatientField.sex,
                    options: Sex.values,
                    labelOf: (v) => v.apiValue,
                    selected: form.sex,
                    enabled: !loading,
                    errorText: errorFor(PatientField.sex),
                    onSelected: _form.setSex,
                  ),
                ),
              ],
            ),
            _FormSection(
              icon: Icons.monitor_heart_outlined,
              title: 'Measurements',
              children: [
                numeric(PatientField.bloodPressure),
                numeric(PatientField.cholesterol),
                numeric(PatientField.bmi),
              ],
            ),
            _FormSection(
              icon: Icons.self_improvement_outlined,
              title: 'Health and lifestyle',
              children: [
                yesNo(PatientField.smoker),
                yesNo(PatientField.diabetes),
                numeric(PatientField.physicalActivity),
                yesNo(PatientField.familyHistory),
                numeric(PatientField.stressLevel),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('reset-form'),
                  onPressed: loading || form.isPristine ? null : _reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset Form'),
                ),
                FilledButton.icon(
                  key: const ValueKey('predict'),
                  // Disabled while a request runs: no duplicate submissions.
                  onPressed: loading ? null : _predict,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            semanticsLabel: 'Classifying',
                          ),
                        )
                      : const Icon(Icons.analytics_outlined),
                  label: Text(loading ? 'Reviewing…' : 'Get insight'),
                ),
              ],
            ),
            const NoticeBanner.educational(),
          ],
        ),
      ),
    );
  }
}

/// A titled card holding a responsive group of form fields.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 20.0;
              final columns = constraints.maxWidth >= 600 ? 2 : 1;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final child in children)
                    SizedBox(width: width, child: child),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
