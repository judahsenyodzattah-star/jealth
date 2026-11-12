import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/jealth_logo.dart';
import '../providers/onboarding_controller.dart';
import '../widgets/onboarding_illustration.dart';

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.art,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.points,
  });

  final OnboardingArt art;
  final String eyebrow;
  final String title;
  final String body;
  final List<(IconData, String)> points;
}

const List<_OnboardingPageData> _pages = [
  _OnboardingPageData(
    art: OnboardingArt.welcome,
    eyebrow: 'Welcome',
    title: "Welcome to J'ealth",
    body:
        "J'ealth helps you organise a small set of health measurements and "
        'review a clear assessment result.',
    points: [
      (Icons.insights_outlined, 'Clear, focused health insights'),
      (Icons.block_outlined, 'Not a medical or diagnostic tool'),
    ],
  ),
  _OnboardingPageData(
    art: OnboardingArt.patientInformation,
    eyebrow: 'Your information',
    title: 'Enter health measurements',
    body:
        'Fill in ten measurements and health characteristics, such as age, '
        'blood pressure, cholesterol, BMI and lifestyle factors, and submit '
        'them for an assessment.',
    points: [
      (Icons.verified_user_outlined, 'No names, addresses or ID numbers'),
      (Icons.phone_iphone_outlined, 'Saved results stay on this device'),
    ],
  ),
  _OnboardingPageData(
    art: OnboardingArt.understandingPredictions,
    eyebrow: 'Use with care',
    title: 'Results are experimental',
    body:
        'Results are provided for educational information only. They are not '
        'clinically validated diagnoses or risk estimates.',
    points: [
      (Icons.info_outline_rounded, 'Read the safety information before use'),
      (
        Icons.health_and_safety_outlined,
        'Always consult a health professional',
      ),
    ],
  ),
];

/// Three-page introduction shown on first launch (and on demand from
/// Settings). Completion is persisted so it only appears once.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  bool get _isLast => _page == _pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (page < 0 || page >= _pages.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await ref.read(onboardingControllerProvider.notifier).complete();
    if (!mounted) return;
    // Reopened from Settings: return there. First launch: continue to Home.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                _goTo(_page + 1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                _goTo(_page - 1),
          },
          child: FocusScope(
            autofocus: true,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(child: JealthWordmark(logoSize: 32)),
                      const SizedBox(width: 8),
                      // Kept in the layout on the last page so nothing jumps.
                      Visibility(
                        visible: !_isLast,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: TextButton(
                          onPressed: _finishing ? null : _finish,
                          child: const Text('Skip'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (page) => setState(() => _page = page),
                      itemBuilder: (context, index) =>
                          _OnboardingPage(data: _pages[index]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      // Wraps onto two lines when large text or a narrow
                      // screen leaves no room for one.
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Semantics(
                              label: 'Page ${_page + 1} of ${_pages.length}',
                              child: ExcludeSemantics(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var i = 0; i < _pages.length; i++)
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        width: i == _page ? 28 : 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: i == _page
                                              ? scheme.primary
                                              : scheme.outlineVariant,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (_page > 0)
                                  TextButton(
                                    onPressed: () => _goTo(_page - 1),
                                    child: const Text('Back'),
                                  ),
                                _isLast
                                    ? FilledButton.icon(
                                        key: const ValueKey(
                                          'onboarding-get-started',
                                        ),
                                        onPressed: _finishing ? null : _finish,
                                        icon: const Icon(Icons.check_rounded),
                                        label: const Text('Get Started'),
                                      )
                                    : FilledButton.icon(
                                        key: const ValueKey('onboarding-next'),
                                        onPressed: () => _goTo(_page + 1),
                                        iconAlignment: IconAlignment.end,
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                        ),
                                        label: const Text('Next'),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.eyebrow.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.secondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(data.title, style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(height: 12),
        Text(
          data.body,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        for (final (icon, label) in data.points)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, size: 22, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              ],
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final illustration = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wide ? 420 : 320,
            maxHeight: wide
                ? 380
                : (constraints.maxHeight * 0.42).clamp(140, 280),
          ),
          child: OnboardingIllustration(art: data.art),
        );

        final content = wide
            ? Row(
                children: [
                  Expanded(child: Center(child: illustration)),
                  const SizedBox(width: 40),
                  Expanded(child: text),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [illustration, const SizedBox(height: 24), text],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 24).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 960 : 520),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}
