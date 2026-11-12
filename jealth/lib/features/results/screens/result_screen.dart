import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/measurements_view.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../classification/models/patient_input.dart';
import '../../classification/models/prediction_result.dart';
import '../../classification/providers/classification_form_controller.dart';
import '../../classification/providers/prediction_controller.dart';
import '../../history/models/history_record.dart';
import '../../history/providers/history_controller.dart';
import '../widgets/result_summary.dart';
import '../widgets/share_sheet.dart';

/// Shows the outcome of the latest classification request: the real result
/// from the prediction service, or an honest explanation of why there is none.
class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(predictionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: AppRoutes.classify),
        title: const Text('Assessment result'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: switch (state) {
          PredictionIdle() => const _NoResultView(key: ValueKey('idle')),
          PredictionLoading() => const LoadingView(
            key: ValueKey('loading'),
            label: 'Contacting the assessment service…',
          ),
          PredictionFailed(:final input, :final error) => _FailureView(
            key: const ValueKey('failed'),
            input: input,
            error: error,
          ),
          PredictionSuccess(:final outcome) => _SuccessView(
            key: ValueKey('success-${outcome.id}'),
            outcome: outcome,
          ),
        },
      ),
    );
  }
}

void _editMeasurements(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.classify);
  }
}

void _classifyAnother(BuildContext context, WidgetRef ref) {
  ref.read(classificationFormControllerProvider.notifier).reset();
  ref.read(predictionControllerProvider.notifier).clear();
  context.go(AppRoutes.classify);
}

class _NoResultView extends StatelessWidget {
  const _NoResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        StateView(
          icon: Icons.pending_actions_outlined,
      title: 'No assessment to show',
          message:
      'Complete the health assessment form and request an assessment.',
          actions: [
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.classify),
              icon: const Icon(Icons.monitor_heart_rounded),
      label: const Text('Start assessment'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return Home'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FailureView extends ConsumerWidget {
  const _FailureView({super.key, required this.input, required this.error});

  final PatientInput input;
  final PredictionException error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final notConnected = error.type == PredictionFailureType.notConfigured;

    final icon = switch (error.type) {
      PredictionFailureType.notConfigured => Icons.cloud_off_outlined,
      PredictionFailureType.unreachable => Icons.wifi_off_rounded,
      PredictionFailureType.timeout => Icons.hourglass_bottom_rounded,
      PredictionFailureType.invalidResponse => Icons.rule_folder_outlined,
      PredictionFailureType.rejected => Icons.assignment_late_outlined,
      _ => Icons.error_outline_rounded,
    };

    final detail = [
      if (error.statusCode != null) 'HTTP ${error.statusCode}',
      ?error.detail,
    ].join(' · ');

    return PageBody(
      maxWidth: 880,
      children: [
        StateView(
          icon: icon,
          iconBackground: notConnected
              ? status.warningContainer
              : scheme.errorContainer,
          iconColor: notConnected
              ? status.onWarningContainer
              : scheme.onErrorContainer,
          title: error.title,
          message: error.message,
          detail: detail.isEmpty ? null : 'Details: $detail',
          actions: [
            if (error.canRetry)
              FilledButton.icon(
                key: const ValueKey('result-retry'),
                onPressed: () =>
                    ref.read(predictionControllerProvider.notifier).retry(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            if (notConnected || error.type == PredictionFailureType.unreachable)
              (error.canRetry ? OutlinedButton.icon : FilledButton.icon)(
                onPressed: () => context.push(AppRoutes.settings),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Service settings'),
              ),
            OutlinedButton.icon(
              onPressed: () => _editMeasurements(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit measurements'),
            ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return Home'),
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Measurements you submitted',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'These were validated but not classified. Nothing was saved.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              MeasurementsView(input: input),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends ConsumerStatefulWidget {
  const _SuccessView({super.key, required this.outcome});

  final ClassificationOutcome outcome;

  @override
  ConsumerState<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends ConsumerState<_SuccessView> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(historyControllerProvider.notifier).save(widget.outcome);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Result saved to history on this device.',
        action: SnackBarAction(
          label: 'View',
          onPressed: () => context.go(AppRoutes.history),
        ),
      );
    } on StorageException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = HistoryRecord.fromOutcome(widget.outcome);
    final saved =
        ref.watch(historyControllerProvider).value?.contains(record.id) ??
        false;

    return PageBody(
      maxWidth: 880,
      children: [
        ResultSummary(record: record),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const ValueKey('result-save'),
              onPressed: saved || _saving ? null : _save,
              icon: Icon(
                saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
              ),
              label: Text(saved ? 'Saved' : 'Save Result'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('result-share'),
              onPressed: () => showShareSheet(context, record),
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share Result'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('result-classify-another'),
              onPressed: () => _classifyAnother(context, ref),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Start another assessment'),
            ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.history),
              icon: const Icon(Icons.history_rounded),
              label: const Text('View History'),
            ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.home),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Return Home'),
            ),
          ],
        ),
      ],
    );
  }
}
