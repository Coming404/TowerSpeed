import 'dart:async';
import 'dart:math';
import 'models/models.dart';

/// 演示数据源。接真实实现时把这里的 mock 换成 Platform Channel / FFI / 本地服务即可。
class MockData {
  MockData._();

  static final _rng = Random(42);

  static List<ProxyNode> nodes() {
    final unlocks = [
      // 全开
      const StreamingUnlock(
          netflix: UnlockStatus.unlocked,
          youtube: UnlockStatus.unlocked,
          disneyPlus: UnlockStatus.unlocked,
          openai: UnlockStatus.unlocked),
      // 部分解锁
      const StreamingUnlock(
          netflix: UnlockStatus.unlocked,
          youtube: UnlockStatus.unlocked,
          disneyPlus: UnlockStatus.blocked,
          openai: UnlockStatus.unlocked),
      // 大部分封
      const StreamingUnlock(
          netflix: UnlockStatus.blocked,
          youtube: UnlockStatus.unlocked,
          disneyPlus: UnlockStatus.blocked,
          openai: UnlockStatus.blocked),
      // 未检测
      const StreamingUnlock(),
    ];
    final raw = [
        _n('🇭🇰 香港 HK-01', 'HK-01  IPLC', ProxyType.trojan, '🇭🇰 香港', 'hk01.tower.dev', 443, 142, 28.4),
        _n('🇭🇰 香港 HK-02', 'HK-02  BGP', ProxyType.vmess, '🇭🇰 香港', 'hk02.tower.dev', 443, 158, 22.1),
        _n('🇯🇵 日本 JP-01', 'JP-01  IIJ', ProxyType.trojan, '🇯🇵 日本', 'jp01.tower.dev', 443, 96, 41.7),
        _n('🇯🇵 日本 JP-02', 'JP-02  NTT', ProxyType.vless, '🇯🇵 日本', 'jp02.tower.dev', 443, 118, 38.2),
        _n('🇺🇸 美国 US-01', 'US-01  CN2', ProxyType.ss, '🇺🇸 美国', 'us01.tower.dev', 443, 178, 15.6),
        _n('🇺🇸 美国 US-02', 'US-02  HE', ProxyType.hysteria2, '🇺🇸 美国', 'us02.tower.dev', 443, 245, 32.8),
        _n('🇸🇬 新加坡 SG-01', 'SG-01  Premium', ProxyType.trojan, '🇸🇬 新加坡', 'sg01.tower.dev', 443, 132, 52.3),
        _n('🇸🇬 新加坡 SG-02', 'SG-02  Standard', ProxyType.ssr, '🇸🇬 新加坡', 'sg02.tower.dev', 443, 210, 8.4),
        _n('🇹🇼 台湾 TW-01', 'TW-01  HiNet', ProxyType.vmess, '🇹🇼 台湾', 'tw01.tower.dev', 443, 88, 61.2),
        _n('🇬🇧 英国 UK-01', 'UK-01  Cogent', ProxyType.tuic, '🇬🇧 英国', 'uk01.tower.dev', 443, 312, 19.7),
        _n('🇩🇪 德国 DE-01', 'DE-01  Hetzner', ProxyType.vless, '🇩🇪 德国', 'de01.tower.dev', 443, 268, 24.5),
        _n('🇰🇷 韩国 KR-01', 'KR-01  KT', ProxyType.trojan, '🇰🇷 韩国', 'kr01.tower.dev', 443, 156, 44.9),
        _n('🇦🇺 澳洲 AU-01', 'AU-01  Telstra', ProxyType.ss, '🇦🇺 澳洲', 'au01.tower.dev', 443, 385, 5.2),
        _n('🇮🇳 印度 IN-01', 'IN-01  Jio', ProxyType.vmess, '🇮🇳 印度', 'in01.tower.dev', 443, null, null, err: 'timeout'),
        _n('🇫🇷 法国 FR-01', 'FR-01  OVH', ProxyType.hysteria2, '🇫🇷 法国', 'fr01.tower.dev', 443, 298, 18.6),
        _n('🇨🇦 加拿大 CA-01', 'CA-01  Bell', ProxyType.vless, '🇨🇦 加拿大', 'ca01.tower.dev', 443, 226, 21.3),
      ];
    for (var i = 0; i < raw.length; i++) {
      raw[i].streaming = unlocks[i % unlocks.length];
    }
    return raw;
  }

  static ProxyNode _n(
    String name,
    String sub,
    ProxyType type,
    String region,
    String server,
    int port,
    int? lat,
    double? mbps, {
    String? err,
  }) {
    final node = ProxyNode(
      id: sub.replaceAll(RegExp(r'\s+'), '-').toLowerCase(),
      name: sub,
      type: type,
      region: region,
      server: server,
      port: port,
      latencyMs: lat,
      downloadMbps: mbps,
      status: err != null
          ? NodeStatus.failed
          : (lat != null ? NodeStatus.done : NodeStatus.idle),
      errorMessage: err,
    );
    return node;
  }

  static List<HistorySession> history() {
    final now = DateTime.now();
    return [
      HistorySession(
        id: 'h1',
        startedAt: now.subtract(const Duration(hours: 2)),
        duration: const Duration(seconds: 47),
        totalNodes: 16,
        passed: 14,
        failed: 2,
        bestMbps: 61.2,
        bestLatencyMs: 88,
        bestNodeName: 'TW-01  HiNet',
        results: nodes().take(6).toList(),
      ),
      HistorySession(
        id: 'h2',
        startedAt: now.subtract(const Duration(days: 1, hours: 3)),
        duration: const Duration(minutes: 1, seconds: 23),
        totalNodes: 16,
        passed: 12,
        failed: 4,
        bestMbps: 52.3,
        bestLatencyMs: 96,
        bestNodeName: 'JP-01  IIJ',
        results: nodes().skip(4).take(5).toList(),
      ),
      HistorySession(
        id: 'h3',
        startedAt: now.subtract(const Duration(days: 3)),
        duration: const Duration(minutes: 2, seconds: 5),
        totalNodes: 16,
        passed: 15,
        failed: 1,
        bestMbps: 58.8,
        bestLatencyMs: 102,
        bestNodeName: 'SG-01  Premium',
        results: nodes().take(4).toList(),
      ),
    ];
  }

  /// 模拟一次测速，产生实时上行速率数据流（给仪表盘动画用）。
  static Stream<double> simulatedSpeedStream({SpeedMode mode = SpeedMode.download}) async* {
    var t = 0.0;
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      t += 0.12;
      // 混合正弦 + 噪声 → 看起来"真"的速率曲线
      final wave = sin(t * 1.4) * 12 + sin(t * 3.7) * 6 + 28;
      final noise = (_rng.nextDouble() - 0.5) * 8;
      yield max(0, wave + noise);
    }
  }

  /// 模拟实时延迟（TTFB）采样流。
  static Stream<int> simulatedLatencyStream() async* {
    var t = 0;
    while (true) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      t++;
      yield 120 + (sin(t / 2.4) * 40).round() + _rng.nextInt(30) - 15;
    }
  }
}
