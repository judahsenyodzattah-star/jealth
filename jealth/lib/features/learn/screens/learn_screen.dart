import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/jealth_app_bar.dart';
import '../../../core/widgets/notice_banner.dart';
import '../../../core/widgets/page_body.dart';
import '../../../core/widgets/section_header.dart';
import '../data/learn_topics.dart';

/// Beginner-friendly explanations of the ideas behind the assessment.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JealthAppBar(title: 'Health education'),
      body: PageBody(
        maxWidth: 880,
        spacing: 12,
        children: [
          const SectionHeader(
            title: 'Understand your health insights',
            subtitle:
                "Short, plain-language health education and guidance for using "
                "J'ealth safely. Tap a topic to open it.",
            padding: EdgeInsets.only(bottom: 4),
          ),
          for (final section in LearnContent.sections) ...[
            SectionHeader(title: section.title),
            for (final topic in section.topics) _TopicCard(topic: topic),
          ],
          const SectionHeader(title: 'How an assessment works'),
          const _WorkflowCard(),
          const SizedBox(height: 4),
          AppCard(
            onTap: () => context.go(AppRoutes.analytics),
            semanticLabel: 'Review saved assessment insights',
            child: Row(
              children: [
                const IconBadge(icon: Icons.insights_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review saved assessments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Open Insights to review results you chose to save.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const ExcludeSemantics(
                  child: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const NoticeBanner.educational(),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic});

  final LearnTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: PageStorageKey('learn-${topic.id}'),
        leading: IconBadge(icon: topic.icon, size: 40),
        title: Text(topic.title),
        subtitle: Text(topic.summary),
        children: [
          for (final paragraph in topic.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(paragraph, style: theme.textTheme.bodyMedium),
            ),
          for (final point in topic.keyPoints)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: scheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(point, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          if (topic.inThisProject != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In J\'ealth',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.inThisProject!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const steps = LearnContent.workflow;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            Semantics(
              label:
                  'Step ${i + 1} of ${steps.length}: ${steps[i].title}. '
                  '${steps[i].description}',
              excludeSemantics: true,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${i + 1}',
                            textScaler: TextScaler.noScaling,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: scheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 4,
                          bottom: i < steps.length - 1 ? 18 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].title,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              steps[i].description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
