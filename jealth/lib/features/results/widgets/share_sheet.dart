import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/feedback.dart';
import '../../history/models/history_record.dart';
import '../services/share_service.dart';

/// Opens the share confirmation sheet for [record].
///
/// Nothing leaves the app until the user presses "Share" inside the sheet,
/// and patient measurements are left out unless the user switches them on.
Future<void> showShareSheet(BuildContext context, HistoryRecord record) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ShareSheet(record: record),
  );
}

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet({required this.record});

  final HistoryRecord record;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  bool _includeMeasurements = false;
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final messengerContext = Navigator.of(context, rootNavigator: true).context;

    final outcome = await ref
        .read(shareServiceProvider)
        .shareText(
          buildShareText(
            widget.record,
            includeMeasurements: _includeMeasurements,
          ),
          subject: "J'ealth - experimental assessment result",
          sharePositionOrigin: origin,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!messengerContext.mounted) return;
    switch (outcome) {
      case ShareOutcome.shared:
      case ShareOutcome.dismissed:
        // The platform share sheet gives its own feedback.
        break;
      case ShareOutcome.copiedToClipboard:
        showAppSnackBar(
          messengerContext,
          "Sharing isn't available here, so the summary was copied to the "
          'clipboard.',
        );
      case ShareOutcome.failed:
        showAppSnackBar(
          messengerContext,
          "The summary couldn't be shared on this device.",
          isError: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = buildShareText(
      widget.record,
      includeMeasurements: _includeMeasurements,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Share result',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review exactly what will be shared. Nothing is sent until '
                  'you press Share.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  key: const ValueKey('share-include-measurements'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include patient measurements'),
                  subtitle: const Text(
                    'Off by default. Health measurements are only shared if '
                    'you turn this on.',
                  ),
                  value: _includeMeasurements,
                  onChanged: _sharing
                      ? null
                      : (value) => setState(() => _includeMeasurements = value),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Semantics(
                      label: 'Preview of the text that will be shared',
                      child: Text(
                        preview,
                        key: const ValueKey('share-preview'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _sharing
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('share-confirm'),
                      onPressed: _sharing ? null : _share,
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
