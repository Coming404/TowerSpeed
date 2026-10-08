import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

/// 大号环形速度指示器：渐变进度环 + 中心数字。
class SpeedRing extends StatelessWidget {
  final double mbps;
  final double maxMbps;
  final double size;
  final bool active;
  final String? caption;

  const SpeedRing({
    super.key,
    required this.mbps,
    this.maxMbps = 100,
    this.size = 240,
    this.active = false,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final pct = (mbps / maxMbps).clamp(0.0, 1.0);
    final color = c.speedColor(mbps);
    final trackColor = c.isDark ? c.surfaceGlass : c.borderStrong;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct),
        duration: const Duration(milliseconds: 500),
        curve: AppCurves.enter,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              color: color,
              active: active,
              trackColor: trackColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: AppDurations.med,
                    style: t.monoBig.copyWith(color: color),
                    child: Text(mbps.toStringAsFixed(1)),
                  ),
                  const SizedBox(height: 4),
                  Text('MB/s',
                      style: t.caption.copyWith(fontSize: 13)),
                  if (caption != null) ...[
                    const SizedBox(height: 6),
                    Text(caption!, style: t.caption),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool active;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.active,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 12;
    const stroke = 14.0;
    const gap = math.pi * 0.25;
    const start = math.pi * 0.75 + gap / 2;
    const sweep = math.pi * 2 - gap;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0.002) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle: start + sweep,
            colors: [color.withOpacity(0.4), color],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r))
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter =
              active ? const MaskFilter.blur(BlurStyle.solid, 6) : null,
      );

      final tipAngle = start + sweep * progress;
      final tip = Offset(
        c.dx + r * math.cos(tipAngle),
        c.dy + r * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tip,
        stroke / 2 + 2,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(tip, stroke / 2 - 1, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.active != active ||
      old.trackColor != trackColor;
}
