import 'package:material_ui/material_ui.dart';

/// One plain-language health lesson shown in the education area.
class LearnTopic {
  const LearnTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
    required this.paragraphs,
    this.keyPoints = const [],
    this.inThisProject,
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;
  final List<String> paragraphs;
  final List<String> keyPoints;
  final String? inThisProject;
}

class LearnSection {
  const LearnSection({required this.title, required this.topics});

  final String title;
  final List<LearnTopic> topics;
}

class WorkflowStep {
  const WorkflowStep(this.title, this.description);

  final String title;
  final String description;
}

abstract final class LearnContent {
  static const List<LearnSection> sections = [
    LearnSection(
      title: 'Everyday heart health',
      topics: [
        LearnTopic(
          id: 'blood-pressure',
          title: 'Blood pressure',
          icon: Icons.monitor_heart_outlined,
          summary: 'What the two blood pressure numbers represent.',
          paragraphs: [
            'Blood pressure describes the force of blood moving through your '
                'blood vessels. It changes throughout the day and can be '
                'affected by activity, stress, sleep and medication.',
            'A single reading is only a snapshot. A healthcare professional '
                'can help interpret readings over time and in context.',
          ],
          keyPoints: [
            'Rest quietly before taking a reading when possible.',
            'Use a validated monitor and follow its instructions.',
            'Seek professional advice for repeated or concerning readings.',
          ],
        ),
        LearnTopic(
          id: 'cholesterol',
          title: 'Cholesterol',
          icon: Icons.water_drop_outlined,
          summary: 'Why cholesterol results need context.',
          paragraphs: [
            'Cholesterol is a substance your body needs, but different types '
                'and levels can affect cardiovascular health in different ways.',
            'A lipid result is interpreted alongside age, medical history, '
                'medications and other factors. J\'ealth does not interpret '
                'laboratory results or recommend treatment.',
          ],
        ),
      ],
    ),
    LearnSection(
      title: 'Healthy routines',
      topics: [
        LearnTopic(
          id: 'movement',
          title: 'Movement and activity',
          icon: Icons.directions_walk_outlined,
          summary: 'How regular movement can support overall wellbeing.',
          paragraphs: [
            'Regular movement can support heart health, mood, sleep and '
                'energy. The right activity depends on your abilities and '
                'health circumstances.',
            'Start gradually if you have been inactive and choose activities '
                'that feel sustainable. Ask a professional for guidance when '
                'you have symptoms or health concerns.',
          ],
        ),
        LearnTopic(
          id: 'smoking',
          title: 'Smoking and tobacco',
          icon: Icons.smoke_free_outlined,
          summary: 'Support is available when you want to reduce or stop.',
          paragraphs: [
            'Smoking and tobacco exposure can affect the heart, blood vessels '
                'and lungs. Stopping can improve health at any age.',
            'If you want to quit, a healthcare professional or local support '
                'service can help you choose a plan and manage withdrawal.',
          ],
        ),
        LearnTopic(
          id: 'stress',
          title: 'Stress and recovery',
          icon: Icons.self_improvement_outlined,
          summary: 'Small recovery habits can support wellbeing.',
          paragraphs: [
            'Long periods of stress can affect sleep, activity and daily '
                'habits. Short breaks, connection with others and regular '
                'sleep can help support recovery.',
            'If stress feels overwhelming or affects daily life, consider '
                'speaking with a qualified professional.',
          ],
        ),
      ],
    ),
    LearnSection(
      title: 'Using J\'ealth safely',
      topics: [
        LearnTopic(
          id: 'results',
          title: 'Understanding an assessment result',
          icon: Icons.info_outline_rounded,
          summary: 'Results are information to discuss, not a diagnosis.',
          paragraphs: [
            'J\'ealth returns an experimental assessment based on the '
                'measurements submitted to its assessment service.',
            'The result can be incomplete or wrong. It must not be used to '
                'make decisions about diagnosis, treatment or urgent care.',
          ],
          keyPoints: [
            'Do not treat a “No Heart Disease” result as a clean bill of health.',
            'Do not treat a “Heart Disease” result as a diagnosis.',
            'Contact a healthcare professional about personal concerns.',
          ],
        ),
        LearnTopic(
          id: 'privacy',
          title: 'Your information',
          icon: Icons.lock_outline_rounded,
          summary: 'What J\'ealth stores and sends.',
          paragraphs: [
            'J\'ealth does not ask for names, addresses or identification '
                'numbers in the assessment form.',
            'Results are saved only when you explicitly choose Save Result. '
                'Review Privacy information in Settings for the full detail.',
          ],
        ),
      ],
    ),
  ];

  static const List<WorkflowStep> workflow = [
    WorkflowStep(
      'Enter measurements',
      'Complete the ten required health measurements and characteristics.',
    ),
    WorkflowStep(
      'Review your entries',
      'Check the values before sending them to the assessment service.',
    ),
    WorkflowStep(
      'Review the result',
      'Read the result and its safety information carefully.',
    ),
    WorkflowStep(
      'Save if useful',
      'Choose whether to keep the result in your private, device-local history.',
    ),
  ];
}
