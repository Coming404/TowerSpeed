/// 数据模型：仅作 UI 演示的数据结构，与 clash-speedtest 对齐。

enum SpeedMode { fast, download, full }

extension SpeedModeX on SpeedMode {
  String get label => switch (this) {
        SpeedMode.fast => '快速测延迟',
        SpeedMode.download => '下载测速',
        SpeedMode.full => '完整测速',
      };
  String get description => switch (this) {
        SpeedMode.fast => '仅测试延迟，最快出结果',
        SpeedMode.download => 'TTFB + 下载速率',
        SpeedMode.full => 'TTFB + 上下行速率',
      };
}

enum ProxyType { ss, ssr, vmess, vless, trojan, hysteria2, tuic, wireguard, http, socks5, unknown }

extension ProxyTypeX on ProxyType {
  String get tag => switch (this) {
        ProxyType.ss => 'SS',
        ProxyType.ssr => 'SSR',
        ProxyType.vmess => 'VMess',
        ProxyType.vless => 'VLESS',
        ProxyType.trojan => 'Trojan',
        ProxyType.hysteria2 => 'Hysteria2',
        ProxyType.tuic => 'TUIC',
        ProxyType.wireguard => 'WG',
        ProxyType.http => 'HTTP',
        ProxyType.socks5 => 'SOCKS5',
        ProxyType.unknown => '—',
      };
}

enum NodeStatus { idle, queued, testing, done, failed, skipped }

/// 流媒体解锁检测结果（clash-speedtest 本身不检测，需后端联动外部检测库后回填）。
enum UnlockStatus { unknown, unlocked, blocked, checking }

class StreamingUnlock {
  final UnlockStatus netflix;
  final UnlockStatus youtube;
  final UnlockStatus disneyPlus;
  final UnlockStatus openai;

  const StreamingUnlock({
    this.netflix = UnlockStatus.unknown,
    this.youtube = UnlockStatus.unknown,
    this.disneyPlus = UnlockStatus.unknown,
    this.openai = UnlockStatus.unknown,
  });

  bool get isEmpty =>
      netflix == UnlockStatus.unknown &&
      youtube == UnlockStatus.unknown &&
      disneyPlus == UnlockStatus.unknown &&
      openai == UnlockStatus.unknown;
}

/// 订阅源：一个远程订阅地址或本地导入的 YAML 文件。
/// clash-speedtest 的 -c 参数接受逗号分隔的多路径混合，这里一项对应一个路径。
class SubscriptionSource {
  final String id;
  final String label;         // 用户起的名字，如 "机场 A"
  final String location;      // https://… 或本地文件路径
  final bool isRemote;        // true=订阅 URL，false=本地 YAML
  bool enabled;               // 本次测速是否使用
  int? nodeCount;             // 上次拉取/解析到的节点数
  DateTime? lastFetchedAt;
  String? lastError;

  SubscriptionSource({
    required this.id,
    required this.label,
    required this.location,
    required this.isRemote,
    this.enabled = true,
    this.nodeCount,
    this.lastFetchedAt,
    this.lastError,
  });

  /// 拼接成 clash-speedtest -c 参数（逗号分隔）。
  static String toConfigPaths(Iterable<SubscriptionSource> sources) =>
      sources.where((s) => s.enabled).map((s) => s.location).join(',');
}

class ProxyNode {
  final String id;
  final String name;
  final ProxyType type;
  final String region;      // e.g. "🇭🇰 香港"
  final String server;      // e.g. "hk01.example.com"
  final int port;
  NodeStatus status;
  int? latencyMs;
  double? downloadMbps;
  double? uploadMbps;
  double? packetLoss;       // 0-100
  String? errorMessage;

  ProxyNode({
    required this.id,
    required this.name,
    required this.type,
    required this.region,
    required this.server,
    required this.port,
    this.status = NodeStatus.idle,
    this.latencyMs,
    this.downloadMbps,
    this.uploadMbps,
    this.packetLoss,
    this.jitterMs,
    this.streaming = const StreamingUnlock(),
    this.errorMessage,
  });

  String get displayName {
    if (name.isEmpty) return '$region · ${type.tag}';
    return name;
  }

  /// clash-speedtest `-rename` 后的格式：`🇺🇸 US 001 | ⬇️ 15.67MB/s`
  String get renamedDisplay {
    final emoji = region.split(' ').first;
    final code = region.split(' ').last;
    final dl = downloadMbps != null ? '${downloadMbps!.toStringAsFixed(2)}MB/s' : '—';
    return '$emoji $code | ⬇️ $dl';
  }
}

class SpeedTestConfig {
  String subscriptionUrl;
  String userAgent;
  String filterRegex;
  String blockKeywords;
  String serverUrl;
  SpeedMode mode;
  int concurrent;
  Duration timeout;
  int downloadSizeMb;
  int uploadSizeMb;
  int maxLatencyMs;
  double minDownloadMbps;
  double minUploadMbps;
  double maxPacketLoss;
  int earlyStop;
  bool renameNodes;
  String outputPath;

  SpeedTestConfig({
    this.subscriptionUrl = '',
    this.userAgent = 'mihomo/1.10.0',
    this.filterRegex = '.*',
    this.blockKeywords = '',
    this.serverUrl = 'https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg',
    this.mode = SpeedMode.download,
    this.concurrent = 4,
    this.timeout = const Duration(seconds: 5),
    this.downloadSizeMb = 50,
    this.uploadSizeMb = 20,
    this.maxLatencyMs = 800,
    this.minDownloadMbps = 5,
    this.minUploadMbps = 2,
    this.maxPacketLoss = 100,
    this.earlyStop = 0,
    this.renameNodes = false,
    this.outputPath = '',
  });

  SpeedTestConfig copy() => SpeedTestConfig(
        subscriptionUrl: subscriptionUrl,
        userAgent: userAgent,
        filterRegex: filterRegex,
        blockKeywords: blockKeywords,
        serverUrl: serverUrl,
        mode: mode,
        concurrent: concurrent,
        timeout: timeout,
        downloadSizeMb: downloadSizeMb,
        uploadSizeMb: uploadSizeMb,
        maxLatencyMs: maxLatencyMs,
        minDownloadMbps: minDownloadMbps,
        minUploadMbps: minUploadMbps,
        maxPacketLoss: maxPacketLoss,
        earlyStop: earlyStop,
        renameNodes: renameNodes,
        outputPath: outputPath,
      );
}

class HistorySession {
  final String id;
  final DateTime startedAt;
  final Duration duration;
  final int totalNodes;
  final int passed;
  final int failed;
  final double? bestMbps;
  final int? bestLatencyMs;
  final String? bestNodeName;
  final List<ProxyNode> results;

  const HistorySession({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.totalNodes,
    required this.passed,
    required this.failed,
    required this.results,
    this.bestMbps,
    this.bestLatencyMs,
    this.bestNodeName,
  });
}
