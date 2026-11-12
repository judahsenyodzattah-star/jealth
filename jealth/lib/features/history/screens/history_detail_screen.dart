import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../results/widgets/result_summary.dart';
import '../../results/widgets/share_sheet.dart';
import '../models/history_record.dart';
import '../providers/history_controller.dart';
import 'history_screen.dart';

/// Full details of one saved classification.
class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.recordId});

  final String recordId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    HistoryRecord record,
  ) async {
    final deleted = await confirmAndDeleteRecord(context, ref, record);
    if (deleted && context.mounted) context.go(AppRoutes.history);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);
    final record = history.value?.byId(recordId);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: AppRoutes.history),
        title: const Text('Saved classification'),
        actions: [
          if (record != null) ...[
            IconButton(
              onPressed: () => showShareSheet(context, record),
              tooltip: 'Share result',
              icon: const Icon(Icons.ios_share_rounded),
            ),
            IconButton(
              onPressed: () => _delete(context, ref, record),
              tooltip: 'Delete record',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: record != null
          ? PageBody(
              maxWidth: 880,
              children: [
                ResultSummary(record: record),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => showShareSheet(context, record),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share Result'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _delete(context, ref, record),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete Record'),
                    ),
                  ],
                ),
              ],
            )
          : history.isLoading
          ? const LoadingView(label: 'Loading saved classification…')
          : PageBody(
              children: [
                StateView(
                  icon: Icons.find_in_page_outlined,
                  title: 'Record not found',
                  message:
                      'This saved classification no longer exists on this '
                      'device. It may have been deleted.',
                  actions: [
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.history),
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Back to History'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
