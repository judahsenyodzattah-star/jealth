import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../classification/models/prediction_result.dart';
import '../../history/providers/history_controller.dart';
import '../../history/repositories/history_repository.dart';
import '../../history/widgets/history_record_tile.dart';

/// Personal insights based only on assessments the user explicitly saved.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: const JealthAppBar(title: 'Insights'),
      body: switch (history) {
        AsyncValue(:final value?) => _InsightsContent(snapshot: value),
        AsyncValue(hasError: true) => PageBody(
          children: [
            StateView(
              icon: Icons.insights_outlined,
              iconBackground: Theme.of(context).colorScheme.errorContainer,
              iconColor: Theme.of(context).colorScheme.onErrorContainer,
              title: "Insights couldn't be loaded",
              message:
                  'Saved assessments could not be read from this device. '
                  'Your stored records have not been changed.',
              actions: [
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(historyControllerProvider.notifier).reload(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
        _ => const LoadingView(label: 'Loading your insights…'),
      },
    );
  }
}

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.snapshot});

  final HistorySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.isEmpty) {
      return PageBody(
        maxWidth: 880,
        children: [
          const SectionHeader(
            title: 'Personal assessment insights',
            subtitle:
                'Save an assessment to see a simple summary of your own '
                'saved results here.',
            padding: EdgeInsets.zero,
          ),
          StateView(
            icon: Icons.insights_outlined,
            title: 'No saved assessments yet',
            message:
                'Insights are created from results you choose to save. '
                'Nothing is estimated or added automatically.',
            actions: [
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.classify),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Start assessment'),
              ),
            ],
          ),
          const NoticeBanner.educational(),
        ],
      );
    }

    final total = snapshot.records.length;
    final heartDiseaseCount = snapshot.records
        .where((record) => record.predictedClass == HeartDiseaseClass.heartDisease)
        .length;
    final noHeartDiseaseCount = total - heartDiseaseCount;

    return PageBody(
      maxWidth: 880,
      spacing: 20,
      children: [
        const SectionHeader(
          title: 'Personal assessment insights',
          subtitle:
              'A summary of results you chose to save on this device. '
              'These are not medical risk estimates.',
          padding: EdgeInsets.zero,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved assessments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InsightTile(
                    icon: Icons.folder_copy_outlined,
                    value: '$total',
                    label: total == 1 ? 'assessment' : 'assessments',
                  ),
                  _InsightTile(
                    icon: Icons.favorite_border_rounded,
                    value: '$heartDiseaseCount',
                    label: 'Heart Disease results',
                  ),
                  _InsightTile(
                    icon: Icons.check_circle_outline_rounded,
                    value: '$noHeartDiseaseCount',
                    label: 'No Heart Disease results',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'The categories above repeat the service output for your saved records. They do not confirm or rule out a medical condition.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Recent saved assessments'),
        for (final record in snapshot.records.take(3))
          HistoryRecordTile(
            key: ValueKey('insight-${record.id}'),
            record: record,
            onTap: () => context.go(AppRoutes.historyDetail(record.id)),
          ),
        const NoticeBanner.educational(),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
