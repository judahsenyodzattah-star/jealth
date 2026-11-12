import 'package:material_ui/material_ui.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/history_store.dart';
import '../../../core/widgets/app_card.dart';

/// Explains what the history keeps on the device and how it is protected.
class StorageNotice extends StatelessWidget {
  const StorageNotice({super.key, this.initiallyExpanded = false});

  final bool initiallyExpanded;

  static const List<String> storedItems = [
    'The ten measurements you submitted',
    'The assessment result, date and time',
    'Additional information needed to keep saved records working, when supplied',
    'A random record identifier',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(Icons.lock_outline_rounded, color: scheme.primary),
        title: const Text('What is stored on this device?'),
        subtitle: const Text('Only results you choose to save'),
        children: [
          Text(
            'A result is stored only when you press "Save Result". Each saved '
            'record contains:',
            style: body,
          ),
          const SizedBox(height: 8),
          for (final item in storedItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: body)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'No names, addresses, identification numbers or accounts are '
            'collected, and saved records are never uploaded by the app. Up to '
            '${AppConstants.maxHistoryRecords} records are kept.',
            style: body,
          ),
          const SizedBox(height: 8),
          Text(historyStorageDescription(), style: body),
          const SizedBox(height: 8),
          Text(
            'You can delete single records here, or everything at once with '
            '"Clear all" or from Settings.',
            style: body,
          ),
        ],
      ),
    );
  }
}
