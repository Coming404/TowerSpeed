import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens.dart';

/// iOS 26 风格悬浮导航栏：滚动时模糊背景渐变显现，标题紧凑居左，
/// 下拉滑动时始终悬浮显示。
///
/// 用法：直接放进 CustomScrollView 的 slivers 里。
/// ```dart
/// slivers: [
///   FloatingAppBar(title: '测速', subtitle: '准备就绪'),
///   ...
/// ]
/// ```
class FloatingAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const FloatingAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).viewPadding.top;
    final collapsedH = top + 56.0;

    return SliverPersistentHeader(
      pinned: true,
      floating: true,
      delegate: _FloatingBarDelegate(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        minH: collapsedH,
        maxH: collapsedH,
      ),
    );
  }
}

class _FloatingBarDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final double minH;
  final double maxH;

  _FloatingBarDelegate({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.minH,
    required this.maxH,
  });

  @override
  double get minExtent => minH;
  @override
  double get maxExtent => maxH;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final top = MediaQuery.of(context).viewPadding.top;
    // 滚动超过一点后显示模糊底
    final progress = (shrinkOffset / 20.0).clamp(0.0, 1.0);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: c.isDark
                ? c.bg.withOpacity(0.35 + 0.35 * progress)
                : c.bg.withOpacity(0.5 + 0.3 * progress),
            border: Border(
              bottom: BorderSide(
                color: c.border.withOpacity(0.9 * progress),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(AppSpace.xl, top + 6, AppSpace.xl, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: t.title.copyWith(
                              fontSize: 22, letterSpacing: -0.5)),
                      const SizedBox(height: 1),
                      Text(subtitle,
                          style:
                              t.bodySm.copyWith(color: c.textLo, fontSize: 11)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_FloatingBarDelegate old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.trailing != trailing;
}

/// iOS 风格分组列表容器（替代一堆嵌套 GlassCard 的设置页）
class InsetGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const InsetGroup({super.key, required this.children, this.margin});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.borderStrong, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.black.withOpacity(0.2)
                : const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 0,
                  color: c.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// InsetGroup 内的行：左侧图标（可选）+ 标题 + 副标题 + 右侧控件。
class InsetRow extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const InsetRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        splashColor: c.accent.withOpacity(0.08),
        highlightColor: c.accent.withOpacity(0.04),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppSpace.md, vertical: AppSpace.md),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: t.body.copyWith(color: c.textHi),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: t.caption,
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpace.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 彩色 SF Symbol 风格图标（iOS 设置页那种彩色圆角方块）
class ColoredIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const ColoredIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size * 0.56, color: color),
    );
  }
}
