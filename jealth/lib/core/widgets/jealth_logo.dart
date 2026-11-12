import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

/// The J'ealth mark: a white heart with a pulse line on the brand gradient.
///
/// Drawn in code so it stays sharp at every size. The geometry mirrors
/// `tool/generate_icons.py`, which renders the platform launcher icons.
class JealthLogo extends StatelessWidget {
  const JealthLogo({
    super.key,
    this.size = 48,
    this.pulseProgress = 1,
    this.showTile = true,
    this.semanticLabel = "J'ealth logo",
  });

  final double size;

  /// How much of the pulse line is drawn (0..1). Used by the splash animation.
  final double pulseProgress;

  /// When false only the heart is drawn (for use on coloured backgrounds).
  final bool showTile;

  /// Pass `null` when the logo is purely decorative.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: _JealthLogoPainter(
        pulseProgress: pulseProgress.clamp(0.0, 1.0),
        showTile: showTile,
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(label: semanticLabel, image: true, child: paint);
  }
}

class _JealthLogoPainter extends CustomPainter {
  const _JealthLogoPainter({
    required this.pulseProgress,
    required this.showTile,
  });

  final double pulseProgress;
  final bool showTile;

  static const List<Offset> _pulse = [
    Offset(0.255, 0.470),
    Offset(0.385, 0.470),
    Offset(0.435, 0.365),
    Offset(0.505, 0.610),
    Offset(0.570, 0.400),
    Offset(0.610, 0.470),
    Offset(0.745, 0.470),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size.square(s);

    if (showTile) {
      final tile = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.225));
      canvas.drawRRect(
        tile,
        Paint()..shader = AppColors.brandGradient.createShader(rect),
      );
    }

    final heart = Path()
      ..moveTo(0.500 * s, 0.335 * s)
      ..cubicTo(
        0.500 * s,
        0.262 * s,
        0.436 * s,
        0.205 * s,
        0.352 * s,
        0.205 * s,
      )
      ..cubicTo(
        0.250 * s,
        0.205 * s,
        0.180 * s,
        0.287 * s,
        0.180 * s,
        0.392 * s,
      )
      ..cubicTo(
        0.180 * s,
        0.560 * s,
        0.345 * s,
        0.672 * s,
        0.500 * s,
        0.812 * s,
      )
      ..cubicTo(
        0.655 * s,
        0.672 * s,
        0.820 * s,
        0.560 * s,
        0.820 * s,
        0.392 * s,
      )
      ..cubicTo(
        0.820 * s,
        0.287 * s,
        0.750 * s,
        0.205 * s,
        0.648 * s,
        0.205 * s,
      )
      ..cubicTo(
        0.564 * s,
        0.205 * s,
        0.500 * s,
        0.262 * s,
        0.500 * s,
        0.335 * s,
      )
      ..close();
    canvas.drawPath(heart, Paint()..color = Colors.white);

    if (pulseProgress <= 0) return;
    final pulse = Path()..moveTo(_pulse.first.dx * s, _pulse.first.dy * s);
    for (final point in _pulse.skip(1)) {
      pulse.lineTo(point.dx * s, point.dy * s);
    }
    final stroke = Paint()
      ..color = AppColors.medicalBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.042
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (pulseProgress >= 1) {
      canvas.drawPath(pulse, stroke);
      return;
    }
    for (final metric in pulse.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * pulseProgress),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_JealthLogoPainter oldDelegate) =>
      oldDelegate.pulseProgress != pulseProgress ||
      oldDelegate.showTile != showTile;
}

/// Logo next to the application name, used in headers and the navigation rail.
class JealthWordmark extends StatelessWidget {
  const JealthWordmark({super.key, this.logoSize = 32, this.showName = true});

  final double logoSize;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: "J'ealth",
      header: false,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            JealthLogo(size: logoSize, semanticLabel: null),
            if (showName) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "J'ealth",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
