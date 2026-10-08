import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/mock_data.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/chips.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/sparkline.dart';
import '../../shared/widgets/speed_ring.dart';
import '../../theme/tokens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
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
  String _currentNode = 'JP-01  IIJ';
  String _currentRegion = '🇯🇵 日本 · NTT';
  ProxyType _currentType = ProxyType.trojan;

  final Queue<double> _speedHistory = Queue();
  static const _historyWindow = 90;

  StreamSubscription<double>? _speedSub;
  StreamSubscription<int>? _latSub;
  Timer? _progressTimer;

  final SpeedTestConfig _config = SpeedTestConfig(
    subscriptionUrl: 'https://sub.example.com/api/v1/client/subscribe?token=***',
  );

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
      _speedHistory.clear();
    });
    _speedSub = MockData.simulatedSpeedStream(mode: _config.mode).listen((v) {
      if (!mounted || _paused) return;
      setState(() {
        _speed = v;
        _speedHistory.addLast(v);
        if (_speedHistory.length > _historyWindow) _speedHistory.removeFirst();
      });
    });
    _latSub = MockData.simulatedLatencyStream().listen((v) {
      if (!mounted || _paused) return;
      setState(() => _latency = max(0, v));
    });
    var tick = 0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted || _paused) return;
      tick++;
      setState(() {
        _progress = (tick / 45).clamp(0.0, 1.0);
        if (tick % 9 == 0 && _testedCount < 12) {
          _testedCount++;
          final fail = tick % 27 == 0;
          fail ? _failedCount++ : _passedCount++;
          const samples = [
            ('JP-01  IIJ', '🇯🇵 日本 · NTT', ProxyType.trojan),
            ('HK-02  BGP', '🇭🇰 香港 · Premium', ProxyType.vmess),
            ('SG-01  Premium', '🇸🇬 新加坡 · IEPL', ProxyType.trojan),
            ('TW-01  HiNet', '🇹🇼 台湾 · HiNet', ProxyType.vmess),
          ];
          final s = samples[tick ~/ 9 % samples.length];
          _currentNode = s.$1;
          _currentRegion = s.$2;
          _currentType = s.$3;
        }
        if (_progress >= 1.0) _stop(finished: true);
      });
    });
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
    final top = MediaQuery.of(context).viewPadding.top;
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.xl, top + AppSpace.md, AppSpace.xl, 0),
              child: _Header(running: _running, tested: _testedCount, total: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.xl),
              child: Center(
                child: SpeedRing(
                  mbps: _speed,
                  maxMbps: 80,
                  size: 260,
                  active: _running && !_paused,
                  caption: _running
                      ? (_paused
                          ? '已暂停'
                          : '测速中 · ${(_progress * 100).toInt()}%')
                      : (_progress >= 1.0 ? '已完成' : '点击开始'),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: AppCurves.enter)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: AppCurves.enter,
                    ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.md, AppSpace.xl, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.activity, size: 14),
                        const SizedBox(width: 6),
                        _Caption('实时速率'),
                        const Spacer(),
                        if (_running && !_paused)
                          _PulsingDot(color: c.accent)
                        else
                          _Caption('—'),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    SpeedSparkline(
                        points: _speedHistory.toList(), height: 56),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 420.ms).slideY(
                  begin: 0.06, end: 0, curve: AppCurves.enter),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.md, AppSpace.xl, 0),
              child: _MetricGrid(
                latency: _latency,
                passed: _passedCount,
                failed: _failedCount,
                progress: _progress,
              ).animate().fadeIn(delay: 180.ms, duration: 420.ms).slideY(
                  begin: 0.08, end: 0, curve: AppCurves.enter),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.md, AppSpace.xl, 0),
              child: GlassCard(
                onTap: () => HapticFeedback.selectionClick(),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(LucideIcons.server,
                          color: c.accent, size: 20),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _H2(_currentNode),
                          const SizedBox(height: 2),
                          _BodySm(_currentRegion),
                        ],
                      ),
                    ),
                    TypeBadge(type: _currentType),
                    const SizedBox(width: AppSpace.sm),
                    const Icon(LucideIcons.chevronRight, size: 18),
                  ],
                ),
              ).animate().fadeIn(delay: 260.ms, duration: 420.ms).slideY(
                  begin: 0.08, end: 0, curve: AppCurves.enter),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.xl, AppSpace.xl, 96 + bottom),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _running || _progress >= 1 ? _progress : 0,
                      minHeight: 6,
                      backgroundColor: c.isDark
                          ? c.surfaceGlass
                          : c.surfaceElev,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progress >= 1.0 ? c.accent : c.info,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MonoSm(
                        _running
                            ? '$_testedCount / 16 · ${(_progress * 100).toStringAsFixed(0)}%'
                            : (_progress >= 1
                                ? '16 / 16 · 完成'
                                : '尚未开始'),
                      ),
                      if (_running || _progress >= 1)
                        _MonoSm('已通过 $_passedCount · 失败 $_failedCount'),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
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
        ],
      ),
    );
  }
}

// —— 文字便捷件（主题感知） ——
class _Caption extends StatelessWidget {
  final String s;
  const _Caption(this.s);
  @override
  Widget build(BuildContext context) =>
      Text(s, style: AppText.of(context).caption);
}

class _BodySm extends StatelessWidget {
  final String s;
  const _BodySm(this.s);
  @override
  Widget build(BuildContext context) =>
      Text(s, style: AppText.of(context).bodySm);
}

class _H2 extends StatelessWidget {
  final String s;
  const _H2(this.s);
  @override
  Widget build(BuildContext context) =>
      Text(s, style: AppText.of(context).h2);
}

class _MonoSm extends StatelessWidget {
  final String s;
  const _MonoSm(this.s);
  @override
  Widget build(BuildContext context) =>
      Text(s, style: AppText.of(context).monoSm);
}

class _Header extends StatelessWidget {
  final bool running;
  final int tested;
  final int total;
  const _Header(
      {required this.running, required this.tested, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TowerSpeed', style: t.display.copyWith(fontSize: 26)),
            const SizedBox(height: 2),
            Text(
              running ? '正在测速 $tested/$total' : '准备就绪',
              style: t.bodySm.copyWith(
                color: running ? c.accent : c.textLo,
              ),
            ),
          ],
        ),
        const Spacer(),
        _IconGlass(
          icon: LucideIcons.cloudDownload,
          tooltip: '更新订阅',
          onTap: () {
            HapticFeedback.selectionClick();
            ShadSonner.of(context)?.show(
              const ShadToast(
                title: Text('更新订阅'),
                description: Text('正在从远端拉取最新节点列表…'),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpace.sm),
        _IconGlass(
          icon: LucideIcons.bell,
          tooltip: '通知',
          onTap: () => HapticFeedback.selectionClick(),
        ),
      ],
    );
  }
}

class _IconGlass extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconGlass(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: AppRadius.sm,
        onTap: onTap,
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final int latency;
  final int passed;
  final int failed;
  final double progress;
  const _MetricGrid({
    required this.latency,
    required this.passed,
    required this.failed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = [
      _Metric(
        icon: LucideIcons.zap,
        label: '延迟',
        value: latency == 0 ? '—' : '$latency',
        unit: 'ms',
        color: c.latencyColor(latency == 0 ? null : latency),
      ),
      _Metric(
        icon: LucideIcons.arrowDownToLine,
        label: '已测试',
        value: '${progress > 0 ? (progress * 16).round() : 0}',
        unit: '/ 16',
        color: c.info,
      ),
      _Metric(
        icon: LucideIcons.badgeCheck,
        label: '通过',
        value: '$passed',
        unit: '',
        color: c.accent,
      ),
      _Metric(
        icon: LucideIcons.circleAlert,
        label: '失败',
        value: '$failed',
        unit: '',
        color: c.danger,
      ),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpace.sm,
      crossAxisSpacing: AppSpace.sm,
      childAspectRatio: 0.92,
      children: [
        for (var i = 0; i < items.length; i++)
          items[i]
              .animate()
              .fadeIn(delay: (i * 55).ms, duration: 320.ms)
              .slideY(begin: 0.12, end: 0, curve: AppCurves.enter),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm, vertical: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: AppSpace.xs),
          Text(label, style: t.caption),
          const SizedBox(height: 2),
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
                    style: t.monoSm.copyWith(color: c.textLo),
                  ),
              ],
            ),
          ),
        ],
      ),
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
      duration: AppDurations.med,
      switchInCurve: AppCurves.enter,
      switchOutCurve: AppCurves.exit,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: AppCurves.overshoot),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: running
          ? Row(
              key: const ValueKey('running'),
              children: [
                Expanded(
                  child: _BigButton(
                    label: paused ? '继续' : '暂停',
                    icon: paused ? LucideIcons.play : LucideIcons.pause,
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
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 1.0,
    value: 1.0,
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
            duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
      },
      onTapUp: (_) {
        _c.animateTo(1.0,
            duration: const Duration(milliseconds: 300),
            curve: AppCurves.overshoot);
        widget.onTap();
      },
      onTapCancel: () => _c.animateTo(1.0,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 0.96 + 0.04 * _c.value, child: child),
        child: Container(
          height: 54,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: widget.outlined
                ? widget.color.withOpacity(0.08)
                : widget.color,
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
                      color: widget.color.withOpacity(0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon,
                  size: 18,
                  color:
                      widget.outlined ? widget.color : c.textInverse),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: t.h2.copyWith(
                  color:
                      widget.outlined ? widget.color : c.textInverse,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.4 + 0.6 * t),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * t),
                blurRadius: 10 + 4 * t,
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
