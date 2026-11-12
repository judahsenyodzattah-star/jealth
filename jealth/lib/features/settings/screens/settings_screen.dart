import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/jealth_logo.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../history/providers/history_controller.dart';
import '../../history/screens/history_screen.dart';
import '../providers/theme_controller.dart';
import '../widgets/service_settings_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeMode = ref.watch(themeControllerProvider);
    final persistent = ref.watch(preferencesProvider).isPersistent;
    final history = ref.watch(historyControllerProvider).value;
    final savedCount = history?.records.length ?? 0;
    final hasStoredData = savedCount > 0 || (history?.unreadableCount ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: AppRoutes.home),
        title: const Text('Settings'),
      ),
      body: PageBody(
        maxWidth: 760,
        spacing: 12,
        children: [
          if (!persistent)
            const NoticeBanner(
              tone: NoticeTone.warning,
              title: "Settings can't be saved on this device",
              message:
                  "This device's storage isn't available, so your choices "
                  'will last only until the app is closed.',
            ),
          const SectionHeader(title: 'Appearance'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Theme', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Choose light or dark, or follow the device setting.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  key: const ValueKey('theme-mode'),
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(themeControllerProvider.notifier)
                      .setThemeMode(selection.first),
                ),
              ],
            ),
          ),
        const SectionHeader(title: 'Assessment service'),
          const ServiceSettingsCard(),
          const SectionHeader(title: 'Privacy and data'),
          _SettingsGroup(
            children: [
              ListTile(
                key: const ValueKey('settings-clear-history'),
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: hasStoredData ? scheme.error : null,
                ),
        title: const Text('Clear assessment history'),
                subtitle: Text(
                  hasStoredData
                      ? '$savedCount saved '
                            '${savedCount == 1 ? 'record' : 'records'} on this '
                            'device. Deletes all saved health data.'
            : 'No assessments are saved on this device.',
                ),
                enabled: hasStoredData,
                onTap: () => confirmAndClearHistory(context, ref),
              ),
              ListTile(
                key: const ValueKey('settings-privacy'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy information'),
                subtitle: const Text('What the app stores and sends'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.privacy),
              ),
            ],
          ),
          const SectionHeader(title: 'General'),
          _SettingsGroup(
            children: [
              ListTile(
                key: const ValueKey('settings-replay-onboarding'),
                leading: const Icon(Icons.slideshow_outlined),
                title: const Text('Replay onboarding'),
                subtitle: const Text('See the introduction again'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.onboarding),
              ),
              ListTile(
                key: const ValueKey('settings-about'),
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text("About J'ealth"),
                subtitle: const Text('Purpose, scope and transparency'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.about),
              ),
              ListTile(
                key: const ValueKey('settings-licenses'),
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licenses and acknowledgements'),
                subtitle: const Text('Open-source software and fonts'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion:
                      'Version ${AppConstants.version} '
                      '(${AppConstants.buildNumber})',
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: JealthLogo(size: 64),
                  ),
                  applicationLegalese:
                      'Digital health assessment tool. Not a medical device.',
                ),
              ),
              const ListTile(
                key: ValueKey('settings-version'),
                leading: Icon(Icons.tag_rounded),
                title: Text('App version'),
                subtitle: Text(
                  '${AppConstants.version} (build ${AppConstants.buildNumber})',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const NoticeBanner.educational(),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 56,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
