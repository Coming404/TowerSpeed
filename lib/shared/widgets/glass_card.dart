import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens.dart';

/// 玻璃拟态卡片。浅色主题下退化为白卡 + 柔和阴影（玻璃效果不明显时退而求其次）。
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? tint;
  final double blur;
  final VoidCallback? onTap;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.margin,
    this.borderRadius = AppRadius.md,
    this.tint,
    this.blur = 18,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // 浅色模式下不用 backdrop blur（白底上无效果），直接给 surface + 阴影
    final fill = tint ??
        (elevated
            ? c.surfaceElev
            : (c.isDark ? c.surfaceGlass : c.surface));

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: c.isDark
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: _decorate(context, fill),
            )
          : _decorate(context, fill),
    );

    Widget wrapped = card;
    if (onTap != null) wrapped = _Pressable(onTap: onTap!, child: card);
    if (margin != null) wrapped = Padding(padding: margin!, child: wrapped);
    return wrapped;
  }

  Widget _decorate(BuildContext context, Color fill) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: c.borderStrong, width: 0.8),
        gradient: c.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  Colors.white.withOpacity(0.02),
                  Colors.black.withOpacity(0.08),
                ],
                stops: const [0.0, 0.35, 1.0],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withOpacity(0.28)
                : const Color(0xFF1E293B).withOpacity(0.06),
            blurRadius: c.isDark ? 24 : 16,
            offset: Offset(0, c.isDark ? 8 : 4),
          ),
          if (!c.isDark)
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    value: 1.0,
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    HapticFeedback.selectionClick();
    _c.animateTo(0.0,
        duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  void _up({bool fire = false}) {
    _c.animateTo(1.0,
        duration: const Duration(milliseconds: 320), curve: AppCurves.overshoot);
    if (fire) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: (_) => _up(fire: true),
      onTapCancel: () => _up(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 0.97 + 0.03 * _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}
