import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/jealth_logo.dart';

enum OnboardingArt { welcome, patientInformation, understandingPredictions }

/// Original, code-drawn illustrations for the onboarding pages (no external
/// image assets, so nothing can go missing or need attribution).
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.art});

  final OnboardingArt art;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft backdrop shapes shared by all three illustrations.
              Positioned(
                top: 6,
                left: 30,
                child: _Blob(
                  size: 250,
                  color: scheme.primary.withValues(alpha: 0.09),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 14,
                child: _Blob(
                  size: 150,
                  color: AppColors.teal.withValues(alpha: 0.14),
                ),
              ),
              Positioned(
                top: 20,
                right: 46,
                child: _Blob(
                  size: 22,
                  color: AppColors.warning.withValues(alpha: 0.7),
                ),
              ),
              // Fills the canvas so the tags are positioned against its
              // edges, around the centred artwork rather than on top of it.
              Positioned.fill(
                child: switch (art) {
                  OnboardingArt.welcome => const _WelcomeArt(),
                  OnboardingArt.patientInformation => const _FormArt(),
                  OnboardingArt.understandingPredictions =>
                    const _PredictionArt(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _ArtCard extends StatelessWidget {
  const _ArtCard({required this.child, this.width, this.padding});

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, this.color, this.height = 8});

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(height),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ArtCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            textScaler: TextScaler.noScaling,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: AppColors.medicalBlue.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const JealthLogo(size: 150, semanticLabel: null),
        ),
        const Positioned(
          top: 40,
          left: 8,
          child: _Tag(icon: Icons.health_and_safety_rounded, label: 'Private by design'),
        ),
        const Positioned(
          bottom: 40,
          right: 14,
          child: _Tag(icon: Icons.insights_rounded, label: 'Clear insights'),
        ),
      ],
    );
  }
}

class _FormArt extends StatelessWidget {
  const _FormArt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget row(IconData icon, double width, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line(width: width * 0.55, height: 6),
              const SizedBox(height: 6),
              _Line(
                width: width,
                color: scheme.primary.withValues(alpha: 0.35),
              ),
            ],
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );

    Widget toggle(bool on) => Container(
      width: 34,
      height: 20,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.teal : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _ArtCard(
          width: 220,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(Icons.cake_outlined, 70),
              row(Icons.speed_outlined, 92),
              row(Icons.monitor_weight_outlined, 60),
              row(Icons.smoking_rooms_outlined, 48, trailing: toggle(false)),
              row(Icons.directions_run_outlined, 56, trailing: toggle(true)),
              const SizedBox(height: 8),
              Container(
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const _Line(width: 54, height: 6, color: Colors.white),
              ),
            ],
          ),
        ),
        const Positioned(
          top: 18,
          right: 4,
          child: _Tag(icon: Icons.edit_note_rounded, label: '10 inputs'),
        ),
      ],
    );
  }
}

class _PredictionArt extends StatelessWidget {
  const _PredictionArt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget bar(double height, Color color) => Container(
      width: 26,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        _ArtCard(
          width: 210,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights_rounded, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  const _Line(width: 86, height: 7),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 92,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    bar(52, AppColors.medicalBlue),
                    bar(44, AppColors.teal),
                    bar(48, scheme.tertiary),
                    bar(40, AppColors.warning),
                  ],
                ),
              ),
              Container(height: 2, color: scheme.outlineVariant),
              const SizedBox(height: 12),
              const _Line(width: 150, height: 6),
              const SizedBox(height: 7),
              const _Line(width: 110, height: 6),
            ],
          ),
        ),
        const Positioned(
          top: 14,
          left: 0,
          child: _Tag(icon: Icons.science_outlined, label: 'Experimental'),
        ),
        const Positioned(
          bottom: 16,
          right: 0,
          child: _Tag(
            icon: Icons.medical_information_outlined,
            label: 'Not a diagnosis',
          ),
        ),
      ],
    );
  }
}
