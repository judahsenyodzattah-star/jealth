import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../classification/models/patient_field.dart';
import '../../classification/models/prediction_result.dart';
import '../models/history_record.dart';
import '../providers/history_controller.dart';
import '../repositories/history_repository.dart';
import '../widgets/history_record_tile.dart';
import '../widgets/storage_notice.dart';

/// Asks for confirmation and deletes every saved record.
/// Shared by the History screen and Settings.
Future<void> confirmAndClearHistory(BuildContext context, WidgetRef ref) async {
  final confirmed = await confirmDestructiveAction(
    context,
      title: 'Clear assessment history?',
    message:
          'Every assessment saved on this device, including the submitted '
        'measurements, will be permanently deleted. This cannot be undone.',
    confirmLabel: 'Delete all',
    icon: Icons.delete_sweep_outlined,
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(historyControllerProvider.notifier).clearAll();
    if (!context.mounted) return;
      showAppSnackBar(context, 'Assessment history cleared.');
  } on StorageException catch (error) {
    if (!context.mounted) return;
    showAppSnackBar(context, error.message, isError: true);
  }
}

/// Asks for confirmation and deletes one saved record. Returns whether the
/// record was deleted.
Future<bool> confirmAndDeleteRecord(
  BuildContext context,
  WidgetRef ref,
  HistoryRecord record,
) async {
  final confirmed = await confirmDestructiveAction(
    context,
    title: 'Delete this record?',
    message:
          'The saved assessment from '
        '${formatDateTime(context, record.timestamp)} and its measurements '
        'will be permanently deleted from this device.',
    confirmLabel: 'Delete',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(historyControllerProvider.notifier).delete(record.id);
    if (!context.mounted) return true;
    showAppSnackBar(context, 'Record deleted.');
    return true;
  } on StorageException catch (error) {
    if (!context.mounted) return false;
    showAppSnackBar(context, error.message, isError: true);
    return false;
  }
}

/// Locally saved assessment history with search, filtering and deletion.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  HeartDiseaseClass? _classFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Text a record can be found by: class, date and every measurement.
  String _searchText(BuildContext context, HistoryRecord record) {
    return [
      record.predictedClass.label,
      'class ${record.predictedClass.value}',
      formatDateTime(context, record.timestamp),
      formatTimestampPlain(record.timestamp),
      for (final field in PatientField.values)
        '${field.label} ${field.displayValue(record.input)}',
    ].join(' ').toLowerCase();
  }

  List<HistoryRecord> _visible(
    BuildContext context,
    List<HistoryRecord> records,
    bool newestFirst,
  ) {
    final terms = _query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((t) => t.isEmpty);
    final filtered = records.where((record) {
      if (_classFilter != null && record.predictedClass != _classFilter) {
        return false;
      }
      if (terms.isEmpty) return true;
      final haystack = _searchText(context, record);
      return terms.every(haystack.contains);
    }).toList();
    // Records arrive newest first.
    return newestFirst ? filtered : filtered.reversed.toList();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _classFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyControllerProvider);
    final hasRecords = history.value?.records.isNotEmpty ?? false;

    return Scaffold(
      appBar: JealthAppBar(
        title: 'History',
        actions: [
          if (hasRecords)
            IconButton(
              key: const ValueKey('history-clear-all'),
              onPressed: () => confirmAndClearHistory(context, ref),
              tooltip: 'Clear all history',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: switch (history) {
        AsyncValue(:final value?) => _buildContent(context, value),
        AsyncValue(hasError: true) => PageBody(
          children: [
            StateView(
              icon: Icons.sd_card_alert_outlined,
              iconBackground: Theme.of(context).colorScheme.errorContainer,
              iconColor: Theme.of(context).colorScheme.onErrorContainer,
              title: "History couldn't be loaded",
              message:
        "Saved assessments couldn't be read from this device's "
                  'storage. Your records have not been changed.',
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
      _ => const LoadingView(label: 'Loading saved assessments…'),
      },
    );
  }

  Widget _buildContent(BuildContext context, HistorySnapshot snapshot) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final unreadableBanner = snapshot.unreadableCount == 0
        ? null
        : NoticeBanner(
            tone: NoticeTone.warning,
            message:
                '${snapshot.unreadableCount} saved '
                '${snapshot.unreadableCount == 1 ? 'record' : 'records'} '
                "couldn't be read and ${snapshot.unreadableCount == 1 ? 'was' : 'were'} "
                'skipped. Clearing history removes unreadable records too.',
            action: TextButton(
              onPressed: () => confirmAndClearHistory(context, ref),
              child: const Text('Clear history'),
            ),
          );

    if (snapshot.isEmpty) {
      return PageBody(
        maxWidth: 880,
        children: [
          ?unreadableBanner,
          StateView(
            icon: Icons.history_toggle_off_rounded,
          title: 'No saved assessments yet',
            message:
          'When the assessment service returns a result, you can choose '
                '"Save Result" to keep it here. Nothing is saved automatically '
                'and no sample records are created.',
            actions: [
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.classify),
                icon: const Icon(Icons.monitor_heart_rounded),
          label: const Text('Start assessment'),
              ),
            ],
          ),
          const StorageNotice(),
        ],
      );
    }

    final newestFirst = ref.watch(historySortControllerProvider);
    final visible = _visible(context, snapshot.records, newestFirst);
    final filtering = _query.trim().isNotEmpty || _classFilter != null;

    return PageBody(
      maxWidth: 880,
      children: [
        ?unreadableBanner,
        TextField(
          key: const ValueKey('history-search'),
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by class, date or measurement',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _classFilter == null,
              onSelected: (_) => setState(() => _classFilter = null),
            ),
            for (final c in HeartDiseaseClass.values.reversed)
              FilterChip(
                label: Text(c.label),
                selected: _classFilter == c,
                onSelected: (selected) =>
                    setState(() => _classFilter = selected ? c : null),
              ),
            TextButton.icon(
              key: const ValueKey('history-sort'),
              onPressed: () => ref
                  .read(historySortControllerProvider.notifier)
                  .setNewestFirst(!newestFirst),
              icon: Icon(
                newestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 20,
              ),
              label: Text(newestFirst ? 'Newest first' : 'Oldest first'),
            ),
          ],
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            filtering
                ? 'Showing ${visible.length} of ${snapshot.records.length} saved '
                      'assessments'
                : '${snapshot.records.length} saved '
                      '${snapshot.records.length == 1 ? 'assessment' : 'assessments'}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (visible.isEmpty)
          StateView(
            icon: Icons.search_off_rounded,
            title: 'No matching records',
            message:
                'No saved assessment matches the current search and '
                'filter.',
            actions: [
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear search and filter'),
              ),
            ],
          )
        else
          for (final record in visible)
            HistoryRecordTile(
              key: ValueKey('history-${record.id}'),
              record: record,
              onTap: () => context.go(AppRoutes.historyDetail(record.id)),
              onDelete: () => confirmAndDeleteRecord(context, ref, record),
            ),
        const StorageNotice(),
      ],
    );
  }
}
