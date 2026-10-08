import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/models.dart';
import '../../shared/widgets/glass_card.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _config = SpeedTestConfig(
    subscriptionUrl:
        'https://sub.example.com/api/v1/client/subscribe?token=***&flag=meta',
  );

  late final TextEditingController _subCtrl =
      TextEditingController(text: _config.subscriptionUrl);
  late final TextEditingController _uaCtrl =
      TextEditingController(text: _config.userAgent);
  late final TextEditingController _filterCtrl =
      TextEditingController(text: _config.filterRegex);
  late final TextEditingController _blockCtrl =
      TextEditingController(text: _config.blockKeywords);
  late final TextEditingController _serverCtrl =
      TextEditingController(text: _config.serverUrl);

  @override
  void dispose() {
    _subCtrl.dispose();
    _uaCtrl.dispose();
    _filterCtrl.dispose();
    _blockCtrl.dispose();
    _serverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('设置', style: t.display.copyWith(fontSize: 26)),
                  const SizedBox(height: 2),
                  Text('测速参数与界面外观',
                      style: t.bodySm.copyWith(color: c.textLo)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.lg, AppSpace.xl, 96 + bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // —— 外观 ——
                  _SectionLabel('外观'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    child: Row(
                      children: [
                        _ThemeOption(
                          label: '浅色',
                          icon: LucideIcons.sun,
                          selected:
                              themeController.mode == ThemeMode.light,
                          onTap: () => themeController
                              .setMode(ThemeMode.light),
                        ),
                        _ThemeOption(
                          label: '深色',
                          icon: LucideIcons.moon,
                          selected:
                              themeController.mode == ThemeMode.dark,
                          onTap: () => themeController
                              .setMode(ThemeMode.dark),
                        ),
                        _ThemeOption(
                          label: '跟随系统',
                          icon: LucideIcons.smartphone,
                          selected: themeController.mode ==
                              ThemeMode.system,
                          onTap: () => themeController
                              .setMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 订阅 ——
                  _SectionLabel('订阅'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('订阅地址 / 本地配置'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _subCtrl,
                          hint: 'https://…subscribe?token=…&flag=meta',
                          icon: LucideIcons.link,
                          mono: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '支持 http(s) 订阅地址或本地 YAML 路径',
                          style: t.caption,
                        ),
                        const SizedBox(height: AppSpace.md),
                        _FieldLabel('User-Agent'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _uaCtrl,
                          hint: 'mihomo/1.10.0',
                          icon: LucideIcons.fingerprint,
                          mono: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 过滤 ——
                  _SectionLabel('节点过滤'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      children: [
                        _FieldLabel('包含正则（-f）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _filterCtrl,
                          hint: 'HK|港|JP|日',
                          icon: LucideIcons.filter,
                          mono: true,
                        ),
                        const SizedBox(height: AppSpace.md),
                        _FieldLabel('屏蔽关键字（-b，| 分隔）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _blockCtrl,
                          hint: 'rate|x1|1x|试用',
                          icon: LucideIcons.ban,
                          mono: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 测速模式 ——
                  _SectionLabel('测速模式'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.sm),
                    child: Column(
                      children: [
                        for (final m in SpeedMode.values)
                          _ModeRow(
                            mode: m,
                            selected: _config.mode == m,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _config.mode = m);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 测速参数 ——
                  _SectionLabel('测速参数'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      children: [
                        _SliderRow(
                          label: '并发数',
                          value: _config.concurrent.toDouble(),
                          min: 1,
                          max: 16,
                          divisions: 15,
                          format: (v) => '${v.toInt()}',
                          onChanged: (v) =>
                              setState(() => _config.concurrent = v.toInt()),
                        ),
                        _SliderRow(
                          label: '超时',
                          value: _config.timeout.inMilliseconds / 1000,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          format: (v) => '${v.toStringAsFixed(0)}s',
                          onChanged: (v) => setState(() => _config
                              .timeout = Duration(
                                  milliseconds: (v * 1000).toInt())),
                        ),
                        _SliderRow(
                          label: '下载测试大小',
                          value: _config.downloadSizeMb.toDouble(),
                          min: 5,
                          max: 200,
                          divisions: 39,
                          format: (v) => '${v.toInt()} MB',
                          onChanged: (v) => setState(
                              () => _config.downloadSizeMb = v.toInt()),
                        ),
                        _SliderRow(
                          label: '上传测试大小',
                          value: _config.uploadSizeMb.toDouble(),
                          min: 5,
                          max: 100,
                          divisions: 19,
                          format: (v) => '${v.toInt()} MB',
                          onChanged: (v) => setState(
                              () => _config.uploadSizeMb = v.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 阈值 ——
                  _SectionLabel('通过阈值'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      children: [
                        _SliderRow(
                          label: '最大延迟',
                          value: _config.maxLatencyMs.toDouble(),
                          min: 50,
                          max: 2000,
                          divisions: 39,
                          format: (v) => '${v.toInt()} ms',
                          onChanged: (v) => setState(
                              () => _config.maxLatencyMs = v.toInt()),
                        ),
                        _SliderRow(
                          label: '最小下载速度',
                          value: _config.minDownloadMbps,
                          min: 0,
                          max: 50,
                          divisions: 50,
                          format: (v) => '${v.toStringAsFixed(1)} MB/s',
                          onChanged: (v) => setState(
                              () => _config.minDownloadMbps = v),
                        ),
                        _SliderRow(
                          label: '最小上传速度',
                          value: _config.minUploadMbps,
                          min: 0,
                          max: 20,
                          divisions: 40,
                          format: (v) => '${v.toStringAsFixed(1)} MB/s',
                          onChanged: (v) => setState(
                              () => _config.minUploadMbps = v),
                        ),
                        _SliderRow(
                          label: '最大丢包率',
                          value: _config.maxPacketLoss,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          format: (v) => '${v.toInt()}%',
                          onChanged: (v) => setState(
                              () => _config.maxPacketLoss = v),
                        ),
                        _SliderRow(
                          label: '达标即停（0=不限）',
                          value: _config.earlyStop.toDouble(),
                          min: 0,
                          max: 50,
                          divisions: 50,
                          format: (v) => '${v.toInt()}',
                          onChanged: (v) => setState(
                              () => _config.earlyStop = v.toInt()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 输出 ——
                  _SectionLabel('输出'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon: LucideIcons.badgeCheck,
                          title: '重命名节点',
                          subtitle: '🇺🇸 US 001 | ⬇️ 15.67MB/s',
                          value: _config.renameNodes,
                          onChanged: (v) =>
                              setState(() => _config.renameNodes = v),
                        ),
                        Divider(color: c.border, height: 24),
                        _FieldLabel('测速服务器 URL'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: _serverCtrl,
                          hint: 'https://dl.google.com/…/googlechrome.dmg',
                          icon: LucideIcons.globe,
                          mono: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '带 path 视为直接下载地址；不带则尝试 /__down /__up',
                          style: t.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 输出上传 ——
                  _SectionLabel('输出上传（可选）'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.gitBranch,
                                size: 16, color: c.textMid),
                            const SizedBox(width: 6),
                            Text('GitHub Gist', style: t.h2),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Token 需 gist scope；地址支持完整 URL 或 Gist ID',
                          style: t.caption,
                        ),
                        const SizedBox(height: AppSpace.md),
                        _FieldLabel('Token（-gist-token）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: TextEditingController(),
                          hint: 'ghp_…',
                          icon: LucideIcons.keyRound,
                          mono: true,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _FieldLabel('Gist 地址 / ID（-gist-address）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: TextEditingController(),
                          hint: 'https://gist.github.com/user/abc123',
                          icon: LucideIcons.link,
                          mono: true,
                        ),
                        Divider(color: c.border, height: 32),
                        Row(
                          children: [
                            Icon(LucideIcons.folderGit,
                                size: 16, color: c.textMid),
                            const SizedBox(width: 6),
                            Text('GitHub 仓库', style: t.h2),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fine-grained PAT 需 Contents: Read and write',
                          style: t.caption,
                        ),
                        const SizedBox(height: AppSpace.md),
                        _FieldLabel('Token（-repo-token）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: TextEditingController(),
                          hint: 'ghp_… / github_pat_…',
                          icon: LucideIcons.keyRound,
                          mono: true,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _FieldLabel('仓库（-repo-address）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: TextEditingController(),
                          hint: 'user/repo 或完整 URL',
                          icon: LucideIcons.gitBranch,
                          mono: true,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _FieldLabel('文件路径（-repo-file-path）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: TextEditingController(),
                          hint: 'configs/subscriptions/result.yaml',
                          icon: LucideIcons.fileText,
                          mono: true,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _FieldLabel('分支（-repo-branch，留空走默认）'),
                        const SizedBox(height: 6),
                        _Field(
                          controller: TextEditingController(),
                          hint: 'main',
                          icon: LucideIcons.gitBranchPlus,
                          mono: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  // —— 关于 ——
                  _SectionLabel('关于'),
                  const SizedBox(height: AppSpace.sm),
                  GlassCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: c.accent.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(LucideIcons.gauge,
                              color: c.accent, size: 22),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('TowerSpeed', style: t.h2),
                              const SizedBox(height: 2),
                              Text('v0.1.0 · 基于 clash-speedtest',
                                  style: t.bodySm),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, size: 18),
                      ],
                    ),
                  ),
                ].animate(interval: 30.ms).fadeIn(
                    duration: 320.ms, curve: AppCurves.enter),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String s;
  const _SectionLabel(this.s);
  @override
  Widget build(BuildContext context) => Text(
        s.toUpperCase(),
        style: AppText.of(context).caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String s;
  const _FieldLabel(this.s);
  @override
  Widget build(BuildContext context) =>
      Text(s, style: AppText.of(context).bodySm);
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool mono;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElev,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: (mono ? t.monoSm : t.body).copyWith(color: c.textHi),
        cursorColor: c.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: (mono ? t.monoSm : t.body)
              .copyWith(color: c.textLo),
          prefixIcon: Icon(icon, size: 16, color: c.textLo),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 4),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

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
          curve: AppCurves.enter,
          height: 56,
          decoration: BoxDecoration(
            color: selected ? c.accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? c.accent : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? c.accent : c.textMid),
              const SizedBox(height: 4),
              Text(
                label,
                style: t.caption.copyWith(
                  color: selected ? c.accent : c.textMid,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final SpeedMode mode;
  final bool selected;
  final VoidCallback onTap;
  const _ModeRow({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  // CLI 标志提示（README: -fast 是 --speed-mode fast 的别名）
  String? get _cliHint => switch (mode) {
        SpeedMode.fast => '等效 --fast / --speed-mode fast',
        SpeedMode.download => '--speed-mode download（默认）',
        SpeedMode.full => '--speed-mode full（含上传）',
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md, vertical: AppSpace.md),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withOpacity(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected
                ? c.accent.withOpacity(0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? c.accent : Colors.transparent,
                border: Border.all(
                  color: selected ? c.accent : c.borderStrong,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.label,
                      style: t.h2.copyWith(fontSize: 14)),
                  const SizedBox(height: 1),
                  Text(mode.description, style: t.caption),
                  if (_cliHint != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _cliHint!,
                      style: t.monoSm.copyWith(
                        color: c.textLo,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: t.bodySm),
              Text(
                format(value),
                style: t.monoSm.copyWith(
                  color: c.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 16),
              activeTrackColor: c.accent,
              inactiveTrackColor: c.surfaceElev,
              thumbColor: c.accent,
              overlayColor: c.accent.withOpacity(0.18),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: c.accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: c.accent),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.h2.copyWith(fontSize: 14)),
              Text(subtitle, style: t.caption),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          activeColor: c.accent,
        ),
      ],
    );
  }
}
