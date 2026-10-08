import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/mock_data.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/glass_card.dart';
import '../../theme/tokens.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final history = MockData.history();

    // 汇总
    final totalRuns = history.length;
    final bestMbps = history.map((h) => h.bestMbps ?? 0).fold(0.0, (a, b) => a > b ? a : b);
    final avgLatency = history
            .where((h) => h.bestLatencyMs != null)
            .map((h) => h.bestLatencyMs!)
            .fold(0, (a, b) => a + b) ~/
        history.where((h) => h.bestLatencyMs != null).length;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.xl, top + AppSpace.md, AppSpace.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('历史', style: t.display.copyWith(fontSize: 26)),
                  const SizedBox(height: 2),
                  Text('$totalRuns 次测速 · 最近 3 天',
                      style: t.bodySm.copyWith(color: c.textLo)),
                  const SizedBox(height: AppSpace.lg),
                  // 汇总三联
                  Row(
                    children: [
                      _StatTile(
                        icon: LucideIcons.activity,
                        label: '最佳速度',
                        value: bestMbps.toStringAsFixed(1),
                        unit: 'MB/s',
                        color: c.accent,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _StatTile(
                        icon: LucideIcons.zap,
                        label: '平均延迟',
                        value: '$avgLatency',
                        unit: 'ms',
                        color: c.info,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _StatTile(
                        icon: LucideIcons.history,
                        label: '测速次数',
                        value: '$totalRuns',
                        unit: '',
                        color: c.warn,
                      ),
                    ],
                  ).animate().fadeIn(delay: 80.ms, duration: 420.ms).slideY(
                      begin: 0.06, end: 0, curve: AppCurves.enter),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.sm),
              child: Text('测速记录', style: t.h2),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpace.xl, 0, AppSpace.xl, 96 + bottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: _SessionCard(
                      session: history[i], index: i),
                ),
                childCount: history.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm, vertical: AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: AppSpace.sm),
            Text(label, style: t.caption),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: t.monoMetric.copyWith(color: color),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: t.monoSm.copyWith(color: AppColors.of(context).textLo),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final HistorySession session;
  final int index;
  const _SessionCard({required this.session, required this.index});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final s = widget.session;
    final fmt = DateFormat('MM-dd HH:mm');
    final rate = s.totalNodes == 0 ? 0.0 : s.passed / s.totalNodes;
    final rateColor = rate >= 0.9
        ? c.accent
        : (rate >= 0.6 ? c.warn : c.danger);

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: AnimatedSize(
        duration: AppDurations.med,
        curve: AppCurves.enter,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              fmt.format(s.startedAt),
                              style: t.h2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s.totalNodes} 节点 · ${s.duration.inSeconds}s',
                              style: t.bodySm,
                            ),
                          ],
                        ),
                      ),
                      // 通过率圈
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: rate,
                              strokeWidth: 4,
                              backgroundColor:
                                  c.isDark ? c.surfaceGlass : c.surfaceElev,
                              valueColor:
                                  AlwaysStoppedAnimation(rateColor),
                            ),
                            Text(
                              '${(rate * 100).toInt()}',
                              style: t.monoSm.copyWith(
                                color: rateColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  // 最佳节点条
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.sm),
                    decoration: BoxDecoration(
                      color: c.surfaceElev,
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.trophy,
                            size: 14, color: c.warn),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.bestNodeName ?? '—',
                            style: t.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        LatencyBadge(
                            ms: s.bestLatencyMs, compact: true),
                        const SizedBox(width: 6),
                        SpeedBadge(mbps: s.bestMbps),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded && s.results.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: c.border, width: 1)),
                ),
                child: Column(
                  children: [
                    for (var i = 0;
                        i < s.results.length;
                        i++)
                      _ResultRow(
                          node: s.results[i], last: i == s.results.length - 1),
                  ],
                ),
              ).animate().fadeIn(duration: 220.ms).slideY(
                  begin: -0.03, end: 0, curve: AppCurves.enter),
          ],
        ),
      ),
    ).animate().fadeIn(
        delay: (widget.index * 50).clamp(0, 300).ms,
        duration: 380.ms,
      ).slideY(begin: 0.05, end: 0, curve: AppCurves.enter);
  }
}

class _ResultRow extends StatelessWidget {
  final ProxyNode node;
  final bool last;
  const _ResultRow({required this.node, this.last = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: c.border, width: 0.6)),
      ),
      child: Row(
        children: [
          StatusDot(status: node.status),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(node.displayName,
                style: t.bodySm.copyWith(
                    fontWeight: FontWeight.w500)),
          ),
          LatencyBadge(ms: node.latencyMs, compact: true),
          const SizedBox(width: 6),
          SizedBox(
            width: 76,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                node.downloadMbps == null
                    ? '—'
                    : '${node.downloadMbps!.toStringAsFixed(1)} MB/s',
                style: t.monoSm.copyWith(
                  color: c.speedColor(node.downloadMbps),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
