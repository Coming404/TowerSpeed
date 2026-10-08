import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/models.dart';
import '../../shared/widgets/floating_app_bar.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// 设置页：iOS 风格分组列表 + 顶部分段控件切换分类。
/// 订阅地址/本地配置入口已移到「节点库」页，这里只保留 UA 和测速参数。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

enum _Tab { general, speed, output, about }

class _SettingsScreenState extends State<SettingsScreen> {
  _Tab _tab = _Tab.general;

  final _config = SpeedTestConfig();

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
    _uaCtrl.dispose();
    _filterCtrl.dispose();
    _blockCtrl.dispose();
    _serverCtrl.dispose();
    super.dispose();
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
          FloatingAppBar(title: '设置', subtitle: '测速参数与界面外观'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.md),
              child: _SegmentedTabs(
                current: _tab,
                onChanged: (t) {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = t);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Padding(
                key: ValueKey(_tab),
                padding: EdgeInsets.fromLTRB(
                    AppSpace.xl, 0, AppSpace.xl, 110 + bottom),
                child: _buildTab(c),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(AppColors c) {
    return switch (_tab) {
      _Tab.general => _general(c),
      _Tab.speed => _speed(c),
      _Tab.output => _output(c),
      _Tab.about => _about(c),
    };
  }

  // —— 通用：外观 + 订阅 UA + 过滤 ——
  Widget _general(AppColors c) {
    final t = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('外观'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Row(children: [
              _ThemeOption('浅色', LucideIcons.sun,
                  themeController.mode == ThemeMode.light,
                  () => themeController.setMode(ThemeMode.light)),
              _ThemeOption('深色', LucideIcons.moon,
                  themeController.mode == ThemeMode.dark,
                  () => themeController.setMode(ThemeMode.dark)),
              _ThemeOption('跟随系统', LucideIcons.smartphone,
                  themeController.mode == ThemeMode.system,
                  () => themeController.setMode(ThemeMode.system)),
            ]),
          ),
        ]),
        _Label('订阅请求'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User-Agent', style: t.bodySm),
                const SizedBox(height: 6),
                _Field(
                  controller: _uaCtrl,
                  hint: 'mihomo/1.10.0',
                  icon: LucideIcons.fingerprint,
                  mono: true,
                ),
                const SizedBox(height: 6),
                Text('拉取订阅时携带的 UA（-ua 参数）', style: t.caption),
              ],
            ),
          ),
        ]),
        _Label('节点过滤'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('包含正则（-f）', style: t.bodySm),
                const SizedBox(height: 6),
                _Field(
                  controller: _filterCtrl,
                  hint: 'HK|港|JP|日',
                  icon: LucideIcons.filter,
                  mono: true,
                ),
                const SizedBox(height: AppSpace.md),
                Text('屏蔽关键字（-b，| 分隔）', style: t.bodySm),
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
        ]),
      ],
    );
  }

  // —— 测速：模式 + 并发/超时 + 阈值 ——
  Widget _speed(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('测速模式'),
        InsetGroup(children: [
          for (final m in SpeedMode.values)
            _ModeRow(mode: m, selected: _config.mode == m, onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _config.mode = m);
            }),
        ]),
        _Label('测速参数'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(children: [
              _SliderRow('并发数', _config.concurrent.toDouble(), 1, 16,
                  15, (v) => '${v.toInt()}',
                  (v) => setState(() => _config.concurrent = v.toInt())),
              _SliderRow('超时', _config.timeout.inMilliseconds / 1000,
                  1, 30, 29, (v) => '${v.toStringAsFixed(0)}s',
                  (v) => setState(() => _config.timeout =
                      Duration(milliseconds: (v * 1000).toInt()))),
              _SliderRow('下载大小', _config.downloadSizeMb.toDouble(),
                  5, 200, 39, (v) => '${v.toInt()} MB',
                  (v) => setState(() => _config.downloadSizeMb = v.toInt())),
              _SliderRow('上传大小', _config.uploadSizeMb.toDouble(),
                  5, 100, 19, (v) => '${v.toInt()} MB',
                  (v) => setState(() => _config.uploadSizeMb = v.toInt())),
            ]),
          ),
        ]),
        _Label('通过阈值'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(children: [
              _SliderRow('最大延迟', _config.maxLatencyMs.toDouble(),
                  50, 2000, 39, (v) => '${v.toInt()} ms',
                  (v) => setState(() => _config.maxLatencyMs = v.toInt())),
              _SliderRow('最小下载', _config.minDownloadMbps,
                  0, 50, 50, (v) => '${v.toStringAsFixed(1)} MB/s',
                  (v) => setState(() => _config.minDownloadMbps = v)),
              _SliderRow('最小上传', _config.minUploadMbps,
                  0, 20, 40, (v) => '${v.toStringAsFixed(1)} MB/s',
                  (v) => setState(() => _config.minUploadMbps = v)),
              _SliderRow('最大丢包', _config.maxPacketLoss,
                  0, 100, 20, (v) => '${v.toInt()}%',
                  (v) => setState(() => _config.maxPacketLoss = v)),
              _SliderRow('达标即停（0=不限）', _config.earlyStop.toDouble(),
                  0, 50, 50, (v) => '${v.toInt()}',
                  (v) => setState(() => _config.earlyStop = v.toInt())),
            ]),
          ),
        ]),
      ],
    );
  }

  // —— 输出：重命名 + 服务器 + Gist/Repo 上传 ——
  Widget _output(AppColors c) {
    final t = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('输出'),
        InsetGroup(children: [
          InsetRow(
            leading: ColoredIcon(
                icon: LucideIcons.badgeCheck, color: c.accent),
            title: const Text('重命名节点'),
            subtitle:
                const Text('🇺🇸 US 001 | ⬇️ 15.67MB/s'),
            trailing: Switch.adaptive(
              value: _config.renameNodes,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _config.renameNodes = v);
              },
              activeColor: c.accent,
            ),
          ),
        ]),
        _Label('测速服务器'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(
                  controller: _serverCtrl,
                  hint: 'https://dl.google.com/…/googlechrome.dmg',
                  icon: LucideIcons.globe,
                  mono: true,
                ),
                const SizedBox(height: 6),
                Text('带 path 视为直接下载地址；不带则尝试 /__down /__up',
                    style: t.caption),
              ],
            ),
          ),
        ]),
        _Label('结果上传（可选）'),
        InsetGroup(children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(LucideIcons.gitBranch, size: 15, color: c.textMid),
                  const SizedBox(width: 6),
                  Text('GitHub Gist', style: t.h2.copyWith(fontSize: 15)),
                ]),
                const SizedBox(height: AppSpace.md),
                _Field(
                  controller: TextEditingController(),
                  hint: 'Token（-gist-token）',
                  icon: LucideIcons.keyRound,
                  mono: true,
                ),
                const SizedBox(height: AppSpace.sm),
                _Field(
                  controller: TextEditingController(),
                  hint: 'Gist 地址 / ID（-gist-address）',
                  icon: LucideIcons.link,
                  mono: true,
                ),
                const SizedBox(height: 6),
                Text('Token 需 gist scope；地址支持完整 URL 或 Gist ID',
                    style: t.caption),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(LucideIcons.folderGit,
                      size: 15, color: c.textMid),
                  const SizedBox(width: 6),
                  Text('GitHub 仓库', style: t.h2.copyWith(fontSize: 15)),
                ]),
                const SizedBox(height: AppSpace.md),
                _Field(
                  controller: TextEditingController(),
                  hint: 'Token（-repo-token）',
                  icon: LucideIcons.keyRound,
                  mono: true,
                ),
                const SizedBox(height: AppSpace.sm),
                _Field(
                  controller: TextEditingController(),
                  hint: '仓库（-repo-address）',
                  icon: LucideIcons.gitBranch,
                  mono: true,
                ),
                const SizedBox(height: AppSpace.sm),
                _Field(
                  controller: TextEditingController(),
                  hint: '文件路径（-repo-file-path）',
                  icon: LucideIcons.fileText,
                  mono: true,
                ),
                const SizedBox(height: AppSpace.sm),
                _Field(
                  controller: TextEditingController(),
                  hint: '分支（-repo-branch，留空走默认）',
                  icon: LucideIcons.gitBranchPlus,
                  mono: true,
                ),
                const SizedBox(height: 6),
                Text('Fine-grained PAT 需 Contents: Read and write',
                    style: t.caption),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  // —— 关于 ——
  Widget _about(AppColors c) {
    final t = AppText.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsetGroup(children: [
          InsetRow(
            leading: ColoredIcon(
                icon: LucideIcons.gauge, color: c.accent, size: 34),
            title: Text('TowerSpeed',
                style: t.h2.copyWith(fontSize: 16)),
            subtitle: const Text('v0.1.0 · 基于 clash-speedtest'),
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: c.textLo),
            onTap: () {},
          ),
          InsetRow(
            leading: ColoredIcon(
                icon: LucideIcons.github, color: c.textMid),
            title: const Text('开源核心'),
            subtitle:
                const Text('github.com/faceair/clash-speedtest'),
            trailing: Icon(LucideIcons.arrowUpRight,
                size: 16, color: c.textLo),
            onTap: () {},
          ),
          InsetRow(
            leading: ColoredIcon(
                icon: LucideIcons.shieldCheck, color: c.info),
            title: const Text('隐私'),
            subtitle: const Text('所有数据仅存在本地'),
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: c.textLo),
            onTap: () {},
          ),
        ]),
      ],
    );
  }
}

// —— 分段控件 ——

class _SegmentedTabs extends StatelessWidget {
  final _Tab current;
  final ValueChanged<_Tab> onChanged;
  const _SegmentedTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const tabs = [
      (_Tab.general, '通用'),
      (_Tab.speed, '测速'),
      (_Tab.output, '输出'),
      (_Tab.about, '关于'),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceElev,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final (t, label) in tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        t == current ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: t == current
                        ? [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppText.of(context).bodySm.copyWith(
                            color: t == current
                                ? c.textHi
                                : c.textLo,
                            fontWeight: t == current
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// —— 辅助组件 ——

class _Label extends StatelessWidget {
  final String s;
  const _Label(this.s);
  @override
  Widget build(BuildContext context) => Padding(
        padding:
            const EdgeInsets.fromLTRB(4, AppSpace.lg, 0, AppSpace.sm),
        child: Text(
          s.toUpperCase(),
          style: AppText.of(context).caption.copyWith(
              fontWeight: FontWeight.w600, letterSpacing: 0.8),
        ),
      );
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption(this.label, this.icon, this.selected, this.onTap);

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
          duration: const Duration(milliseconds: 180),
          height: 52,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color:
                selected ? c.accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  selected ? c.accent : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? c.accent : c.textMid),
              const SizedBox(height: 3),
              Text(label,
                  style: t.caption.copyWith(
                      color: selected ? c.accent : c.textMid,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
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
      ),
      child: TextField(
        controller: controller,
        style: (mono ? t.monoSm : t.body).copyWith(color: c.textHi),
        cursorColor: c.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              (mono ? t.monoSm : t.body).copyWith(color: c.textLo),
          prefixIcon: Icon(icon, size: 15, color: c.textLo),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 4),
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final SpeedMode mode;
  final bool selected;
  final VoidCallback onTap;
  const _ModeRow(
      {required this.mode, required this.selected, required this.onTap});

  String? get _cliHint => switch (mode) {
        SpeedMode.fast => '--fast / --speed-mode fast',
        SpeedMode.download => '--speed-mode download（默认）',
        SpeedMode.full => '--speed-mode full（含上传）',
      };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppText.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: c.accent.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.md),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      selected ? c.accent : Colors.transparent,
                  border: Border.all(
                    color:
                        selected ? c.accent : c.borderStrong,
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
                        style: t.body
                            .copyWith(color: c.textHi)),
                    const SizedBox(height: 1),
                    Text(mode.description, style: t.caption),
                    if (_cliHint != null) ...[
                      const SizedBox(height: 2),
                      Text(_cliHint!,
                          style: t.monoSm.copyWith(
                              color: c.textLo, fontSize: 9.5)),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
  const _SliderRow(this.label, this.value, this.min, this.max,
      this.divisions, this.format, this.onChanged);

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
              Text(format(value),
                  style: t.monoSm.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14),
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
