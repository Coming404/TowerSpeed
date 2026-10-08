import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/mock_data.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/floating_app_bar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/speed_ring.dart';
import '../../theme/tokens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// 一条正在测/已测完的实时结果（UI 演示模型）
class _LiveResult {
  final String name;
  final String region;
  final ProxyType type;
  NodeStatus status;
  int? latencyMs;
  double? downloadMbps;
  StreamingUnlock streaming;
  _LiveResult(this.name, this.region, this.type,
      {this.status = NodeStatus.queued,
      this.latencyMs,
      this.downloadMbps,
      this.streaming = const StreamingUnlock()});
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _running = false;
  bool _paused = false;
  double _speed = 0;
  int _latency = 0;
  double _progress = 0;
  int _testedCount = 0;
  int _passedCount = 0;
  int _failedCount = 0;

  // 实时结果列表（按下载速度降序）
  final List<_LiveResult> _liveResults = [];

  StreamSubscription<double>? _speedSub;
  StreamSubscription<int>? _latSub;
  Timer? _progressTimer;

  static const _samples = [
    ('JP-01  IIJ', '🇯🇵 日本 · NTT', ProxyType.trojan),
    ('HK-02  BGP', '🇭🇰 香港 · Premium', ProxyType.vmess),
    ('SG-01  Premium', '🇸🇬 新加坡 · IEPL', ProxyType.trojan),
    ('TW-01  HiNet', '🇹🇼 台湾 · HiNet', ProxyType.vmess),
    ('US-02  HE', '🇺🇸 美国 · HE', ProxyType.hysteria2),
    ('KR-01  KT', '🇰🇷 韩国 · KT', ProxyType.trojan),
  ];

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }

  void _stopAll() {
    _speedSub?.cancel();
    _latSub?.cancel();
    _progressTimer?.cancel();
    _speedSub = null;
    _latSub = null;
    _progressTimer = null;
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _paused = false;
      _progress = 0;
      _testedCount = 0;
      _passedCount = 0;
      _failedCount = 0;
      _speed = 0;
      _latency = 0;
      _liveResults.clear();
    });
    _speedSub =
        MockData.simulatedSpeedStream(mode: SpeedMode.download).listen((v) {
      if (!mounted || _paused) return;
      setState(() => _speed = v);
    });
    _latSub = MockData.simulatedLatencyStream().listen((v) {
      if (!mounted || _paused) return;
      setState(() => _latency = max(0, v));
    });
    var tick = 0;
    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted || _paused) return;
      tick++;
      setState(() {
        _progress = (tick / 45).clamp(0.0, 1.0);
        // 每 ~1.2s 完成一个节点
        if (tick % 3 == 0 && _testedCount < 12) {
          _testedCount++;
          final fail = tick % 12 == 0;
          fail ? _failedCount++ : _passedCount++;
          final s = _samples[tick ~/ 3 % _samples.length];
          _insertResult(_LiveResult(
            s.$1, s.$2, s.$3,
            status: fail ? NodeStatus.failed : NodeStatus.done,
            latencyMs: fail ? null : 80 + tick * 4,
            downloadMbps:
                fail ? null : max(0.5, 40 - tick * 1.3 + (tick % 5) * 3),
            streaming: _demoUnlock(tick),
          ));
        }
        if (_progress >= 1.0) _stop(finished: true);
      });
    });
  }

  StreamingUnlock _demoUnlock(int tick) {
    final r = tick % 4;
    return switch (r) {
      0 => const StreamingUnlock(
          netflix: UnlockStatus.unlocked,
          youtube: UnlockStatus.unlocked,
          disneyPlus: UnlockStatus.unlocked,
          openai: UnlockStatus.unlocked),
      1 => const StreamingUnlock(
          netflix: UnlockStatus.unlocked,
          youtube: UnlockStatus.unlocked,
          disneyPlus: UnlockStatus.blocked,
          openai: UnlockStatus.unlocked),
      2 => const StreamingUnlock(
          netflix: UnlockStatus.blocked,
          youtube: UnlockStatus.unlocked,
          disneyPlus: UnlockStatus.blocked,
          openai: UnlockStatus.blocked),
      _ => const StreamingUnlock(),
    };
  }

  /// 按下载速度降序插入（TUI 默认排序：下载带宽越高越靠前）
  void _insertResult(_LiveResult r) {
    var idx = _liveResults.length;
    for (var i = 0; i < _liveResults.length; i++) {
      final cur = _liveResults[i].downloadMbps ?? -1;
      final next = r.downloadMbps ?? -1;
      if (next > cur) {
        idx = i;
        break;
      }
    }
    _liveResults.insert(idx, r);
  }

  void _stop({bool finished = false}) {
    HapticFeedback.lightImpact();
    _stopAll();
    setState(() {
      _running = false;
      _paused = false;
      if (finished) _progress = 1.0;
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _paused = !_paused);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          FloatingAppBar(
            title: 'TowerSpeed',
            subtitle: _running
                ? '测速中 · $_testedCount/12'
                : (_progress >= 1 ? '上次已完成' : '准备就绪'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _IconBtn(
                  icon: LucideIcons.bell,
                  onTap: () =>
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('暂无新通知'),
                          duration: Duration(seconds: 1),
                        ),
                      ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.md, AppSpace.xl, 0),
              child: Column(
                children: [
                  // —— 上行：小仪表盘 + 实时速率 ——
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左：小号仪表盘
                      SpeedRing(
                        mbps: _speed,
                        maxMbps: 80,
                        size: 150,
                        active: _running && !_paused,
                        caption: _running
                            ? (_paused
                                ? '已暂停'
                                : '${(_progress * 100).toInt()}%')
                            : (_progress >= 1.0
                                ? '已完成'
                                : '待开始'),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(width: AppSpace.md),
                      // 右：实时速率 + 延迟
                      Expanded(
                        child: Column(
                          children: [
                            _MiniStat(
                              icon: LucideIcons.activity,
                              label: '实时速率',
                              value: _running && !_paused
                                  ? _speed.toStringAsFixed(1)
                                  : '—',
                              unit: 'MB/s',
                              color: c.speedColor(_speed),
                              live: _running && !_paused,
                            ),
                            const SizedBox(height: AppSpace.sm),
                            _MiniStat(
                              icon: LucideIcons.zap,
                              label: '延迟',
                              value: _latency == 0
                                  ? '—'
                                  : '$_latency',
                              unit: 'ms',
                              color: c.latencyColor(
                                  _latency == 0 ? null : _latency),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            _MiniStat(
                              icon: LucideIcons.badgeCheck,
                              label: '通过 / 失败',
                              value: '$_passedCount/$_failedCount',
                              unit: '',
                              color: _failedCount > 0
                                  ? c.danger
                                  : c.accent,
                            ),
                          ],
                        ).animate().fadeIn(
                            delay: 80.ms, duration: 300.ms),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  // —— 进度条 ——
                  _ProgressBar(
                    progress: _progress,
                    running: _running,
                    tested: _testedCount,
                  ),
                  const SizedBox(height: AppSpace.md),
                  // —— 控制按钮 ——
                  _CtaButton(
                    running: _running,
                    paused: _paused,
                    onStart: _start,
                    onPause: _togglePause,
                    onStop: _stop,
                  ),
                ],
              ),
            ),
          ),
          // —— 实时结果列表 ——
          if (_liveResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xs),
                child: Row(
                  children: [
                    Text('实时结果',
                        style: AppText.of(context).caption.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    const SizedBox(width: 6),
                    _PulsingDot(
                        color: c.accent, size: 6,
                        visible: _running && !_paused),
                    const Spacer(),
                    Text('按速度排序',
                        style: AppText.of(context).monoSm
                            .copyWith(color: c.textLo, fontSize: 10)),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                AppSpace.xl, 0, AppSpace.xl, 110 + bottom),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final r = _liveResults[i];
                  return _ResultTile(result: r)
                      .animate(key: ValueKey(r.name))
                      .fadeIn(duration: 240.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic);
                },
                childCount: _liveResults.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// —— 小组件 ——

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool live;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.sm),
      borderRadius: AppRadius.sm,
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.caption),
                const SizedBox(height: 1),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: value,
                        style: t.monoMetric
                            .copyWith(color: color, fontSize: 18)),
                    if (unit.isNotEmpty)
                      TextSpan(
                          text: ' $unit',
                          style: t.monoSm
                              .copyWith(color: c.textLo, fontSize: 10)),
                  ]),
                ),
              ],
            ),
          ),
          if (live) _PulsingDot(color: color, size: 7, visible: true),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool running;
  final int tested;
  const _ProgressBar(
      {required this.progress, required this.running, required this.tested});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: running || progress >= 1 ? progress : 0,
            minHeight: 5,
            backgroundColor:
                c.isDark ? c.surfaceGlass : c.surfaceElev,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? c.accent : c.info,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              running
                  ? '$tested / 12 · ${(progress * 100).toStringAsFixed(0)}%'
                  : (progress >= 1 ? '12 / 12 · 完成' : '等待开始'),
              style: t.monoSm.copyWith(color: c.textLo, fontSize: 10),
            ),
            if (running || progress >= 1)
              Text(
                '已通过 $tested',
                style:
                    t.monoSm.copyWith(color: c.textLo, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }
}

class _CtaButton extends StatelessWidget {
  final bool running;
  final bool paused;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const _CtaButton({
    required this.running,
    required this.paused,
    required this.onStart,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: running
          ? Row(
              key: const ValueKey('running'),
              children: [
                Expanded(
                  child: _BigButton(
                    label: paused ? '继续' : '暂停',
                    icon: paused
                        ? LucideIcons.play
                        : LucideIcons.pause,
                    color: c.warn,
                    onTap: onPause,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _BigButton(
                    label: '停止',
                    icon: LucideIcons.square,
                    color: c.danger,
                    onTap: onStop,
                    outlined: true,
                  ),
                ),
              ],
            )
          : _BigButton(
              key: const ValueKey('idle'),
              label: '开始测速',
              icon: LucideIcons.play,
              color: c.accent,
              onTap: onStart,
              fullWidth: true,
            ),
    );
  }
}

class _BigButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  final bool fullWidth;

  const _BigButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.fullWidth = false,
  });

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    value: 1.0,
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _c.animateTo(0.0,
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut);
      },
      onTapUp: (_) {
        _c.animateTo(1.0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic);
        widget.onTap();
      },
      onTapCancel: () => _c.animateTo(1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(
            scale: 0.97 + 0.03 * _c.value, child: child),
        child: Container(
          height: 48,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color:
                widget.outlined ? widget.color.withOpacity(0.08) : widget.color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: widget.outlined
                  ? widget.color.withOpacity(0.5)
                  : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 17,
                  color: widget.outlined ? widget.color : c.textInverse),
              const SizedBox(width: 7),
              Text(widget.label,
                  style: t.h2.copyWith(
                      color: widget.outlined
                          ? widget.color
                          : c.textInverse,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final _LiveResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    final r = result;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.sm),
        borderRadius: AppRadius.sm,
        child: Row(
          children: [
            StatusDot(status: r.status),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: t.body.copyWith(
                          color: c.textHi, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r.region, style: t.caption),
                ],
              ),
            ),
            // 流媒体标志
            _UnlockDots(unlock: r.streaming),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LatencyBadge(ms: r.latencyMs, compact: true),
                const SizedBox(height: 3),
                SpeedBadge(mbps: r.downloadMbps),
              ],
            ),
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
    if (unlock.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot('N', unlock.netflix),
        const SizedBox(width: 3),
        _dot('Y', unlock.youtube),
        const SizedBox(width: 3),
        _dot('D', unlock.disneyPlus),
        const SizedBox(width: 3),
        _dot('A', unlock.openai),
      ],
    );
  }

  Widget _dot(String label, UnlockStatus s) {
    return Builder(builder: (context) {
      final c = AppColors.of(context);
      final (col, txt) = switch (s) {
        UnlockStatus.unlocked => (c.accent, c.accent),
        UnlockStatus.blocked => (c.danger, c.danger),
        UnlockStatus.checking => (c.warn, c.warn),
        UnlockStatus.unknown => (c.textLo.withOpacity(0.3), c.textLo),
      };
      return Container(
        width: 16,
        height: 16,
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
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: txt)),
      );
    });
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

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
          color: c.surfaceGlass,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.borderStrong, width: 0.8),
        ),
        child: Icon(icon, size: 17, color: c.textMid),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool visible;
  const _PulsingDot(
      {required this.color, this.size = 8, this.visible = true});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.3),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.5 + 0.5 * t),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 * t),
                blurRadius: 6 + 4 * t,
                spreadRadius: t,
              ),
            ],
          ),
        );
      },
    );
  }
}
