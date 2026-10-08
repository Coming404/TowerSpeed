import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/models.dart';
import '../../shared/widgets/floating_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../theme/tokens.dart';

/// 节点库：聚合管理所有节点来源（多个订阅地址 + 本地 YAML 导入），
/// 合并去重后交给测速核心。对应 clash-speedtest 的 `-c` 多路径参数。
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  // 演示数据：真实实现时持久化到本地存储
  final List<SubscriptionSource> _sources = [
    SubscriptionSource(
      id: 's1',
      label: '机场 A · 主力',
      location:
          'https://sub.example.com/api/v1/client/subscribe?token=a1b2&flag=meta',
      isRemote: true,
      nodeCount: 48,
      lastFetchedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    SubscriptionSource(
      id: 's2',
      label: '机场 B · 备用',
      location:
          'https://sub2.example.com/api/v1/client/subscribe?token=c3d4&flag=meta',
      isRemote: true,
      nodeCount: 36,
      lastFetchedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SubscriptionSource(
      id: 's3',
      label: '自建节点.yaml',
      location: '/Documents/towerspeed/self-hosted.yaml',
      isRemote: false,
      nodeCount: 6,
      lastFetchedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  int get _totalNodes =>
      _sources.where((s) => s.enabled).fold(0, (sum, s) => sum + (s.nodeCount ?? 0));

  /// 去重后预计节点数（演示：按 server:port 去重，mock 约 -15% 重叠）
  int get _dedupedNodes => (_totalNodes * 0.87).round();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          FloatingAppBar(
            title: '节点库',
            subtitle: '聚合订阅与本地配置',
            trailing: _AddButton(onTap: () => _showAddSheet(context)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.sm, AppSpace.xl, 0),
              child: _SummaryCard(
                total: _totalNodes,
                deduped: _dedupedNodes,
                enabledSources: _sources.where((s) => s.enabled).length,
                totalSources: _sources.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.sm),
              child: Row(
                children: [
                  Text('订阅来源',
                      style: t.caption.copyWith(
                          fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const Spacer(),
                  Text('${_sources.length} 个',
                      style: t.monoSm.copyWith(color: c.textLo)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding:
                EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.xl, 120 + bottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final s = _sources[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    child: _SourceTile(
                      source: s,
                      onToggle: (v) =>
                          setState(() => s.enabled = v),
                      onRefresh: () => _refreshSource(s),
                      onDelete: () => setState(() => _sources.remove(s)),
                    ).animate().fadeIn(
                        delay: (i * 40).ms, duration: 240.ms),
                  );
                },
                childCount: _sources.length,
              ),
            ),
          ),
        ],
      ),
      // 底部固定操作条：合并结果 + 送入测速
      bottomNavigationBar: _BottomBar(
        deduped: _dedupedNodes,
        onSendToTest: _sendToTest,
      ),
    );
  }

  void _refreshSource(SubscriptionSource s) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('正在拉取 ${s.label}…'),
      duration: const Duration(seconds: 2),
    ));
    // TODO: 调核心 fetchHTTPConfig，回填 nodeCount / lastFetchedAt / lastError
  }

  void _sendToTest() {
    final paths = SubscriptionSource.toConfigPaths(_sources);
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('请先启用至少一个订阅来源'),
      ));
      return;
    }
    HapticFeedback.mediumImpact();
    // TODO: 把 paths 写入共享状态（core 的 -c 参数），再跳转到测速页
    context.go('/dashboard');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('已载入 $_dedupedNodes 个节点（去重后），点击开始测速'),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showAddSheet(BuildContext context) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddSourceSheet(
        onAdd: (s) => setState(() => _sources.add(s)),
        bg: c.surface,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int deduped;
  final int enabledSources;
  final int totalSources;

  const _SummaryCard({
    required this.total,
    required this.deduped,
    required this.enabledSources,
    required this.totalSources,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          _Stat(label: '启用来源', value: '$enabledSources/$totalSources'),
          _Divider(),
          _Stat(label: '合并节点', value: '$total'),
          _Divider(),
          _Stat(label: '去重后', value: '$deduped', highlight: true),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Stat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: t.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: t.monoMetric.copyWith(
              color: highlight ? c.accent : c.textHi,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.of(context).border,
      );
}

class _SourceTile extends StatelessWidget {
  final SubscriptionSource source;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const _SourceTile({
    required this.source,
    required this.onToggle,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        children: [
          Row(
            children: [
              ColoredIcon(
                icon: source.isRemote
                    ? LucideIcons.globe
                    : LucideIcons.fileText,
                color: source.isRemote ? c.info : c.warn,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.label, style: t.h2.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      source.location,
                      style: t.monoSm.copyWith(
                          color: c.textLo, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: source.enabled,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onToggle(v);
                },
                activeColor: c.accent,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              _MetaItem(
                icon: LucideIcons.server,
                text: '${source.nodeCount ?? '—'} 节点',
              ),
              const SizedBox(width: AppSpace.md),
              _MetaItem(
                icon: LucideIcons.clock,
                text: source.lastFetchedAt == null
                    ? '未拉取'
                    : _fmtAgo(source.lastFetchedAt!),
              ),
              const Spacer(),
              _IconBtn(
                  icon: LucideIcons.refreshCw,
                  tooltip: '重新拉取',
                  onTap: onRefresh),
              const SizedBox(width: 4),
              _IconBtn(
                  icon: LucideIcons.trash2,
                  tooltip: '删除',
                  color: c.danger,
                  onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
    if (d.inHours < 24) return '${d.inHours}小时前';
    return '${d.inDays}天前';
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c.textLo),
        const SizedBox(width: 4),
        Text(text, style: t.caption),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _IconBtn(
      {required this.icon,
      required this.tooltip,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.surfaceElev,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color ?? c.textMid),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: [
            BoxShadow(
              color: c.accent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(LucideIcons.plus, size: 18, color: c.textInverse),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int deduped;
  final VoidCallback onSendToTest;
  const _BottomBar({required this.deduped, required this.onSendToTest});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpace.xl, AppSpace.md, AppSpace.xl, bottom + AppSpace.md),
      decoration: BoxDecoration(
        color: c.isDark
            ? c.bg.withOpacity(0.85)
            : c.bg.withOpacity(0.92),
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: GestureDetector(
          onTap: onSendToTest,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: c.accent.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.rocket, size: 18, color: c.textInverse),
                const SizedBox(width: 8),
                Text('送入测速 · $deduped 节点',
                    style: t.h2.copyWith(
                        color: c.textInverse,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddSourceSheet extends StatefulWidget {
  final ValueChanged<SubscriptionSource> onAdd;
  final Color bg;
  const _AddSourceSheet({required this.onAdd, required this.bg});

  @override
  State<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends State<_AddSourceSheet> {
  final _labelCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  bool _isRemote = true;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: widget.bg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('添加订阅来源', style: t.title),
          const SizedBox(height: AppSpace.lg),
          // 类型切换
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.surfaceElev,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                _SegBtn(
                    label: '订阅地址',
                    icon: LucideIcons.globe,
                    active: _isRemote,
                    onTap: () => setState(() => _isRemote = true)),
                _SegBtn(
                    label: '本地 YAML',
                    icon: LucideIcons.fileText,
                    active: !_isRemote,
                    onTap: () => setState(() => _isRemote = false)),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _SheetField(
              controller: _labelCtrl,
              label: '名称',
              hint: '例：机场 A · 主力'),
          const SizedBox(height: AppSpace.md),
          _SheetField(
            controller: _locCtrl,
            label: _isRemote ? '订阅地址' : '文件路径',
            hint: _isRemote
                ? 'https://…subscribe?token=…&flag=meta'
                : '/Documents/config.yaml',
            mono: true,
          ),
          const SizedBox(height: AppSpace.xl),
          GestureDetector(
            onTap: _submit,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text('添加',
                    style: t.h2.copyWith(
                        color: c.textInverse,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_locCtrl.text.trim().isEmpty) return;
    widget.onAdd(SubscriptionSource(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelCtrl.text.trim().isEmpty
          ? (_isRemote ? '新订阅' : '本地配置')
          : _labelCtrl.text.trim(),
      location: _locCtrl.text.trim(),
      isRemote: _isRemote,
    ));
    Navigator.pop(context);
  }
}

class _SegBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SegBtn(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 38,
          decoration: BoxDecoration(
            color: active ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14, color: active ? c.accent : c.textLo),
              const SizedBox(width: 6),
              Text(label,
                  style: t.bodySm.copyWith(
                      color: active ? c.textHi : c.textLo,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool mono;
  const _SheetField(
      {required this.controller,
      required this.label,
      required this.hint,
      this.mono = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: t.caption),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceElev,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            style: (mono ? t.monoSm : t.body).copyWith(color: c.textHi),
            cursorColor: c.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  (mono ? t.monoSm : t.body).copyWith(color: c.textLo),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}
