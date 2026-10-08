import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/tokens.dart';

/// 应用主壳：底部玻璃导航栏 + 四个独立 tab 栈。
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  static const _tabs = [
    _Tab(LucideIcons.library, '节点库'),
    _Tab(LucideIcons.gauge, '测速'),
    _Tab(LucideIcons.network, '节点'),
    _Tab(LucideIcons.history, '历史'),
    _Tab(LucideIcons.settings2, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      extendBody: true,
      body: shell,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
        tabs: _tabs,
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  const _Tab(this.icon, this.label);
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_Tab> tabs;

  const _GlassNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, bottom + AppSpace.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: c.isDark
                  ? c.surface.withOpacity(0.72)
                  : Colors.white.withOpacity(0.86),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: c.borderStrong, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: c.isDark
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xFF1E293B).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final t = tabs[i];
                return Expanded(
                  child: _NavItem(
                    icon: t.icon,
                    label: t.label,
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final color = active ? c.accent : c.textLo;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: AppDurations.med,
            curve: AppCurves.enter,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active ? c.accent.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: AppDurations.med,
            style: t.caption.copyWith(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
