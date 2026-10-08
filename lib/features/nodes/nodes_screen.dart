import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/mock_data.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/floating_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../theme/tokens.dart';

enum _Sort { latency, speed, name, region }

class NodesScreen extends StatefulWidget {
  const NodesScreen({super.key});

  @override
  State<NodesScreen> createState() => _NodesScreenState();
}

class _NodesScreenState extends State<NodesScreen> {
  late List<ProxyNode> _nodes = MockData.nodes();
  _Sort _sort = _Sort.latency;
  String _regionFilter = '全部';
  String _search = '';
  bool _asc = true;

  List<String> get _regions =>
      ['全部', ..._nodes.map((n) => n.region).toSet().toList()..sort()];

  List<ProxyNode> get _visible {
    Iterable<ProxyNode> v = _nodes;
    if (_regionFilter != '全部') v = v.where((n) => n.region == _regionFilter);
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      v = v.where((n) =>
          n.name.toLowerCase().contains(q) ||
          n.region.toLowerCase().contains(q) ||
          n.server.toLowerCase().contains(q));
    }
    final list = v.toList();
    list.sort((a, b) {
      final cmp = switch (_sort) {
        _Sort.latency =>
          (a.latencyMs ?? 99999).compareTo(b.latencyMs ?? 99999),
        _Sort.speed =>
          (b.downloadMbps ?? -1).compareTo(a.downloadMbps ?? -1),
        _Sort.name => a.name.compareTo(b.name),
        _Sort.region => a.region.compareTo(b.region),
      };
      return _asc ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final visible = _visible;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          FloatingAppBar(
            title: '节点',
            subtitle: '${_nodes.length} 个节点 · 按$_sortLabel排序',
          ),
          // —— 搜索 + 筛选 ——
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.sm, AppSpace.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索框
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md, vertical: 2),
                    borderRadius: AppRadius.md,
                    child: Row(
                      children: [
                        Icon(LucideIcons.search, size: 18, color: c.textLo),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _search = v),
                            style: t.body.copyWith(color: c.textHi),
                            cursorColor: c.accent,
                            decoration: InputDecoration(
                              hintText: '搜索节点 / 地区 / 服务器',
                              hintStyle:
                                  t.body.copyWith(color: c.textLo),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                          ),
                        ),
                        if (_search.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(() => _search = ''),
                            child: Icon(LucideIcons.x,
                                size: 16, color: c.textLo),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  // 排序 + 筛选 行
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _regions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final r = _regions[i];
                              final active = r == _regionFilter;
                              return _PillChip(
                                label: r,
                                active: active,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _regionFilter = r);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // —— 排序工具栏 ——
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.sm),
              child: Row(
                children: [
                  _SortButton(
                    label: '延迟',
                    active: _sort == _Sort.latency,
                    asc: _asc,
                    onTap: () => _setSort(_Sort.latency),
                  ),
                  const SizedBox(width: 6),
                  _SortButton(
                    label: '速度',
                    active: _sort == _Sort.speed,
                    asc: _asc,
                    onTap: () => _setSort(_Sort.speed),
                  ),
                  const SizedBox(width: 6),
                  _SortButton(
                    label: '名称',
                    active: _sort == _Sort.name,
                    asc: _asc,
                    onTap: () => _setSort(_Sort.name),
                  ),
                  const Spacer(),
                  Text('${visible.length} 项', style: t.monoSm.copyWith(color: c.textLo)),
                ],
              ),
            ),
          ),
          // —— 节点列表 ——
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpace.xl, 0, AppSpace.xl, 96 + bottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final n = visible[i];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpace.sm),
                    child: _NodeTile(node: n, index: i),
                  );
                },
                childCount: visible.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _sortLabel => switch (_sort) {
        _Sort.latency => '延迟',
        _Sort.speed => '速度',
        _Sort.name => '名称',
        _Sort.region => '地区',
      };

  void _setSort(_Sort s) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sort == s) {
        _asc = !_asc;
      } else {
        _sort = s;
        _asc = s == _Sort.latency || s == _Sort.name || s == _Sort.region;
      }
    });
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PillChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.enter,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? c.accent : c.borderStrong,
            width: 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: c.accent.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: t.bodySm.copyWith(
            color: active ? c.textInverse : c.textMid,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool asc;
  final VoidCallback onTap;
  const _SortButton({
    required this.label,
    required this.active,
    required this.asc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? c.accent.withOpacity(0.4) : c.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: t.bodySm.copyWith(
                color: active ? c.accent : c.textMid,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(
                asc ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                size: 12,
                color: c.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NodeTile extends StatefulWidget {
  final ProxyNode node;
  final int index;
  const _NodeTile({required this.node, required this.index});

  @override
  State<_NodeTile> createState() => _NodeTileState();
}

class _NodeTileState extends State<_NodeTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final n = widget.node;
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
              child: Row(
                children: [
                  StatusDot(status: n.status),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.displayName, style: t.h2),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(n.region, style: t.bodySm),
                            const SizedBox(width: 6),
                            TypeBadge(type: n.type),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      LatencyBadge(ms: n.latencyMs),
                      const SizedBox(height: 4),
                      SpeedBadge(mbps: n.downloadMbps),
                      const SizedBox(height: 4),
                      _UnlockDots(unlock: n.streaming),
                    ],
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppDurations.fast,
                    child: Icon(LucideIcons.chevronDown,
                        size: 16, color: c.textLo),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.md, 0, AppSpace.md, AppSpace.md),
                child: Column(
                  children: [
                    Divider(color: c.border, height: 16),
                    _InfoRow('服务器', '${n.server}:${n.port}'),
                    if (n.uploadMbps != null)
                      _InfoRow('上传', '${n.uploadMbps} MB/s'),
                    if (n.packetLoss != null)
                      _InfoRow('丢包', '${n.packetLoss}%'),
                    if (n.errorMessage != null)
                      _InfoRow('错误', n.errorMessage!, isError: true),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniAction(
                            icon: LucideIcons.play,
                            label: '重测',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniAction(
                            icon: LucideIcons.copy,
                            label: '复制',
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MiniAction(
                            icon: LucideIcons.externalLink,
                            label: '详情',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(
                  begin: -0.05, end: 0, curve: AppCurves.enter),
          ],
        ),
      ),
    ).animate().fadeIn(
        delay: (widget.index * 35).clamp(0, 400).ms,
        duration: 320.ms,
      ).slideY(begin: 0.04, end: 0, curve: AppCurves.enter);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;
  const _InfoRow(this.label, this.value, {this.isError = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: t.bodySm),
          Text(
            value,
            style: t.monoSm.copyWith(
              color: isError ? c.danger : c.textHi,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: c.surfaceElev,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: c.textMid),
            const SizedBox(width: 5),
            Text(label, style: t.caption.copyWith(color: c.textMid)),
          ],
        ),
      ),
    );
  }
}

/// 流媒体解锁状态点：N=Netflix Y=YouTube D=Disney+ A=OpenAI
class _UnlockDots extends StatelessWidget {
  final StreamingUnlock unlock;
  const _UnlockDots({required this.unlock});

  @override
  Widget build(BuildContext context) {
    if (unlock.isEmpty) {
      return Text('流媒体未知',
          style: AppText.of(context)
              .caption
              .copyWith(fontSize: 9, color: AppColors.of(context).textLo));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(context, 'N', unlock.netflix),
        const SizedBox(width: 3),
        _dot(context, 'Y', unlock.youtube),
        const SizedBox(width: 3),
        _dot(context, 'D', unlock.disneyPlus),
        const SizedBox(width: 3),
        _dot(context, 'A', unlock.openai),
      ],
    );
  }

  Widget _dot(BuildContext context, String label, UnlockStatus s) {
    final c = AppColors.of(context);
    final (col, txt) = switch (s) {
      UnlockStatus.unlocked => (c.accent, c.accent),
      UnlockStatus.blocked => (c.danger, c.danger),
      UnlockStatus.checking => (c.warn, c.warn),
      UnlockStatus.unknown => (c.textLo.withOpacity(0.3), c.textLo),
    };
    return Container(
      width: 15,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: col.withOpacity(s == UnlockStatus.unlocked ? 0.18 : 0.1),
        border: Border.all(
            color: col.withOpacity(
                s == UnlockStatus.unknown ? 0.4 : 0.6),
            width: 0.8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: txt)),
    );
  }
}
