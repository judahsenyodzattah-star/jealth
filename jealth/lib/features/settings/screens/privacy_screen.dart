import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/history_store.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/page_body.dart';
import '../../history/providers/history_controller.dart';
import '../../history/screens/history_screen.dart';
import '../../history/widgets/storage_notice.dart';
import '../widgets/info_section.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider).value;
    final hasStoredData =
        (history?.records.isNotEmpty ?? false) ||
        (history?.unreadableCount ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: AppRoutes.settings),
        title: const Text('Privacy information'),
      ),
      body: PageBody(
        maxWidth: 760,
        children: [
          const InfoSection(
            icon: Icons.shield_outlined,
            title: 'Privacy at a glance',
            bullets: [
              'No account, sign-in, advertising or analytics tracking.',
              'No names, addresses, phone numbers or identification numbers '
                  'are requested.',
              'Results are saved only when you press "Save Result", and only '
                  'on this device.',
              'Nothing is shared unless you press Share and confirm.',
            ],
          ),
          InfoSection(
            icon: Icons.sd_storage_outlined,
            title: 'What is stored on this device',
            paragraphs: ['Each saved assessment contains:'],
            bullets: StorageNotice.storedItems,
            child: Builder(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    historyStorageDescription(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'At most ${AppConstants.maxHistoryRecords} records are '
                    'kept; once history is full, older records must be '
                    'deleted before new ones can be saved. The app also '
                    'stores your theme choice, whether onboarding was '
      'completed, the history sort order and the assessment '
      'service address.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const InfoSection(
            icon: Icons.cloud_upload_outlined,
            title: 'What is sent over the network',
            paragraphs: [
              'When you press Predict, the ten measurements from the form '
      'are sent to the assessment service address set in '
                  'Settings, and nowhere else. If no address is set, nothing '
                  'is sent.',
      'Whoever operates that service can see the measurements it '
                  'receives. Use https for any service that is not on your '
                  'own computer or network.',
              "Unsaved form entries and unsaved results are held only in the "
                  "app's memory and disappear when the app is closed.",
            ],
          ),
          InfoSection(
            icon: Icons.delete_forever_outlined,
            title: 'Deleting your data',
            paragraphs: const [
              'You can delete a single record from History, or delete every '
                  'saved assessment at once. Deletion is permanent.',
            ],
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton.tonalIcon(
                  key: const ValueKey('privacy-delete-all'),
                  onPressed: hasStoredData
                      ? () => confirmAndClearHistory(context, ref)
                      : null,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(
                    hasStoredData
                        ? 'Delete all saved health data'
                        : 'No saved health data',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
