import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import '../../core/models/models.dart';

class LatencyBadge extends StatelessWidget {
  final int? ms;
  final bool compact;
  const LatencyBadge({super.key, required this.ms, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final col = c.latencyColor(ms);
    final label = ms == null ? '—' : '${ms}ms';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: t.monoSm.copyWith(color: col, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class SpeedBadge extends StatelessWidget {
  final double? mbps;
  const SpeedBadge({super.key, required this.mbps});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final col = c.speedColor(mbps);
    final label = mbps == null ? '—' : '${mbps!.toStringAsFixed(1)} MB/s';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: t.monoSm.copyWith(color: col, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class TypeBadge extends StatelessWidget {
  final ProxyType type;
  const TypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.textLo.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.borderStrong, width: 0.6),
      ),
      child: Text(
        type.tag,
        style: t.caption.copyWith(
          color: c.textMid,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  final NodeStatus status;
  const StatusDot({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (color, glow) = switch (status) {
      NodeStatus.done => (c.accent, false),
      NodeStatus.testing => (c.info, true),
      NodeStatus.failed => (c.danger, false),
      NodeStatus.queued => (c.warn, false),
      NodeStatus.skipped => (c.textLo, false),
      NodeStatus.idle => (c.textLo, false),
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
    );
  }
}
