import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/jealth_logo.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../widgets/info_section.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: AppRoutes.settings),
        title: const Text("About J'ealth"),
      ),
      body: PageBody(
        maxWidth: 760,
        children: [
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const JealthLogo(size: 84),
                const SizedBox(height: 14),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version ${AppConstants.version} '
                  '(build ${AppConstants.buildNumber})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const InfoSection(
            icon: Icons.health_and_safety_outlined,
            title: 'A transparent health tool',
            paragraphs: [
              AppConstants.projectDescription,
              'The experience is designed to make each step understandable: '
                  'what you enter, what the assessment returns, and where its '
                  'limitations begin.',
            ],
          ),
          const InfoSection(
            icon: Icons.checklist_rounded,
            title: 'What the app does',
            bullets: [
              'Collects ten health measurements and sends them to the '
                  'configured assessment service.',
              'Displays the assessment result returned by the service.',
              'Keeps an optional, local history of results you save.',
              'Summarises assessments you choose to save.',
              'Offers plain-language health education.',
            ],
          ),
          const InfoSection(
            icon: Icons.block_outlined,
            title: 'What the app does not do',
            bullets: [
              'It does not diagnose, screen for or rule out heart disease.',
              'It does not estimate clinical risk.',
              'It does not give medical or treatment advice.',
              'It does not provide a diagnosis or replace professional care.',
            ],
          ),
          const NoticeBanner.educational(),
        ],
      ),
    );
  }
}
