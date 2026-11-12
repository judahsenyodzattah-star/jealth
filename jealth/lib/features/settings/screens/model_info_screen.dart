import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/dataset_info.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/service_status.dart';
import '../../../services/prediction_service.dart';
import '../../analytics/models/model_evaluation.dart';
import '../../classification/models/patient_field.dart';
import '../widgets/info_section.dart';

class ModelInfoScreen extends ConsumerWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final config = ref.watch(apiConfigProvider);
    const model = EvaluationData.logisticRegression;
    const matrix = EvaluationData.confusionMatrix;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: AppRoutes.settings),
        title: const Text('Model information'),
      ),
      body: PageBody(
        maxWidth: 760,
        children: [
          InfoSection(
            icon: Icons.model_training_outlined,
            title: 'Selected model: ${model.name}',
            paragraphs: const [
              'A binary classifier trained with supervised learning. It '
                  'reads ten input features and outputs class 0 (No Heart '
                  'Disease) or class 1 (Heart Disease).',
              'The model is not part of this app. It runs in a separate '
                  'prediction service, and the app only displays what that '
                  'service returns.',
            ],
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const ServiceStatusPill(),
                  Text(
                    config.isConfigured
                        ? 'Service address: ${config.baseUrl}'
                        : 'No service address is set.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InfoSection(
            icon: Icons.input_rounded,
            title: 'Model inputs',
            paragraphs: const [
              'Field names sent to the service, with the values seen in the '
                  'training data. These ranges describe the dataset; they '
                  'are not clinical thresholds.',
            ],
            child: Column(
              children: [
                for (final field in PatientField.values)
                  _InputRow(field: field),
              ],
            ),
          ),
          InfoSection(
            icon: Icons.dataset_outlined,
            title: 'Training data',
            bullets: [
              'Synthetic dataset of ${DatasetInfo.totalRecords} records.',
              '${DatasetInfo.inputFeatures} input features and '
                  '${DatasetInfo.targetColumns} binary target '
                  '(${DatasetInfo.targetName}).',
              '${DatasetInfo.trainingRecords} training records and '
                  '${DatasetInfo.testingRecords} testing records.',
            ],
          ),
          InfoSection(
            icon: Icons.insights_rounded,
            title: 'Historical test results',
            paragraphs: const [
              'Measured once on the 100 test records. These are not live '
                  'figures.',
            ],
            bullets: [
              'Accuracy ${formatPercent(model.testAccuracy)}, against a '
                  'majority-class baseline of '
                  '${formatPercent(matrix.majorityBaselineAccuracy)}.',
              'Precision ${formatMetric(model.testPrecision)}, recall '
                  '${formatMetric(model.testRecall)}, F1-score '
                  '${formatMetric(model.testF1)}.',
              'ROC-AUC ${formatMetric(model.testRocAuc)}: near random '
                  'discrimination.',
            ],
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.analytics),
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Open Analytics'),
              ),
            ),
          ),
          InfoSection(
            icon: Icons.api_rounded,
            title: 'Service interface',
            paragraphs: [
              'The app sends a POST request with the ten fields above as '
                  'JSON to ${ApiConfig.defaultPredictPath} and expects '
                  'predicted_class (0 or 1) in the reply. class_label, '
                  'model_score and model_version are optional.',
            ],
          ),
          const InfoSection(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Limitations',
            bullets: [
              'Only slightly better than always predicting the more common '
                  'class.',
              'Trained on a small synthetic dataset that does not describe '
                  'real patients.',
              'Several inputs have no documented unit or scoring scale.',
              'Not clinically validated. Not suitable for diagnosis or '
                  'medical decisions.',
            ],
          ),
          const NoticeBanner.educational(),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({required this.field});

  final PatientField field;

  String get _values => switch (field) {
    PatientField.sex => 'Male or Female',
    PatientField.smoker ||
    PatientField.diabetes ||
    PatientField.familyHistory => 'Yes or No',
    _ => field.trainingRange!.label,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(field.icon, size: 20, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              // The value drops below the name when there is no room beside it.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 2,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        field.labelWithUnit,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        field.jsonKey,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Text(_values, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
