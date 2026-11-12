import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/jealth_logo.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/service_status.dart';
import '../../history/providers/history_controller.dart';
import '../../history/widgets/history_record_tile.dart';

/// Home dashboard: entry point to every part of the application.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const JealthAppBar(title: AppConstants.appName),
      body: PageBody(
        spacing: 20,
        children: [
          const _HeroCard(),
          const _ServiceStatusCard(),
          const SectionHeader(title: 'Quick access'),
          ResponsiveGrid(
            minItemWidth: 220,
            children: [
              _QuickAccessCard(
                icon: Icons.history_rounded,
                title: 'Saved assessments',
                description: 'Review results you chose to save on this device.',
                onTap: () => context.go(AppRoutes.history),
              ),
              _QuickAccessCard(
                icon: Icons.insights_rounded,
                title: 'Personal insights',
                description: 'Review patterns in assessments you saved.',
                onTap: () => context.go(AppRoutes.analytics),
              ),
              _QuickAccessCard(
                icon: Icons.health_and_safety_rounded,
                title: 'Health education',
                description: 'Explore plain-language health concepts.',
                onTap: () => context.go(AppRoutes.learn),
              ),
            ],
          ),
          const _HowItWorksCard(),
          const NoticeBanner.educational(),
          const _RecentAssessments(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onHero = Colors.white;

    return AppCard(
      gradient: AppColors.heroGradient,
      padding: EdgeInsets.zero,
      radius: 28,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppConstants.subtitle.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: onHero.withValues(alpha: 0.86),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  AppConstants.tagline,
                  style:
                      (wide
                              ? theme.textTheme.headlineMedium
                              : theme.textTheme.headlineSmall)
                          ?.copyWith(color: onHero),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Complete ten health measurements to receive a clear assessment '
                'result. Your information stays focused on the '
                'assessment—no names or identification numbers are collected.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onHero.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('home-start-classification'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.medicalBlue,
                    ),
                    onPressed: () => context.go(AppRoutes.classify),
                    icon: const Icon(Icons.monitor_heart_rounded),
                  label: const Text('Start assessment'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    onPressed: () => context.go(AppRoutes.history),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('View saved results'),
                  ),
                ],
              ),
            ],
          );

          return Stack(
            children: [
              // Decorative rings.
              Positioned(
                right: -70,
                top: -90,
                child: _Ring(size: 260, alpha: wide ? 0.10 : 0.07),
              ),
              Positioned(
                right: 40,
                bottom: -120,
                child: _Ring(size: 220, alpha: wide ? 0.08 : 0.05),
              ),
              Padding(
                padding: EdgeInsets.all(wide ? 32 : 22),
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 3, child: text),
                          const SizedBox(width: 24),
                          const Expanded(
                            flex: 2,
                            child: Center(
                              child: JealthLogo(
                                size: 150,
                                showTile: false,
                                semanticLabel: null,
                              ),
                            ),
                          ),
                        ],
                      )
                    : text,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    ),
  );
}

class _ServiceStatusCard extends ConsumerWidget {
  const _ServiceStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final status = ref.watch(serviceStatusProvider);
    final message = switch (status) {
      ServiceStatus.notConnected =>
        'The assessment service is not configured yet. No results are '
            'simulated.',
      ServiceStatus.checking => 'Checking the assessment service…',
      ServiceStatus.connected =>
        'The assessment service is available.',
      ServiceStatus.unreachable =>
        'The assessment service is unavailable. Check Settings and try again.',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Assessment service', style: theme.textTheme.titleMedium),
              const ServiceStatusPill(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => context.push(AppRoutes.settings),
              icon: const Icon(Icons.tune_rounded, size: 20),
              label: const Text('Service settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      semanticLabel: '$title. $description',
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          IconBadge(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A simple way to check in', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            'Complete the guided assessment, review the result, and decide '
            'whether to save it for later. J\'ealth keeps the experience '
            'focused and transparent.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: const [
              _HomeStep(icon: Icons.edit_note_rounded, label: 'Enter measurements'),
              _HomeStep(icon: Icons.insights_rounded, label: 'Review the output'),
              _HomeStep(icon: Icons.bookmark_add_outlined, label: 'Save if useful'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeStep extends StatelessWidget {
  const _HomeStep({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}

class _RecentAssessments extends ConsumerWidget {
  const _RecentAssessments();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final history = ref.watch(historyControllerProvider);
    final records = history.value?.records ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent assessments',
          trailing: records.isEmpty
              ? null
              : TextButton(
                  onPressed: () => context.go(AppRoutes.history),
                  child: const Text('See all'),
                ),
        ),
        const SizedBox(height: 12),
        if (records.isNotEmpty)
          for (final record in records.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HistoryRecordTile(
                record: record,
                onTap: () => context.go(AppRoutes.historyDetail(record.id)),
              ),
            )
        else
          AppCard(
            child: Row(
              children: [
                IconBadge(
                  icon: history.hasError
                      ? Icons.error_outline_rounded
                      : Icons.inbox_outlined,
                  background: scheme.surfaceContainerHigh,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    history.isLoading
                        ? 'Loading saved classifications…'
                        : history.hasError
                        ? "Saved assessments couldn't be read. Open "
                              'History to try again.'
                        : 'No saved assessments yet. Results you choose '
                              'to save will appear here.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
