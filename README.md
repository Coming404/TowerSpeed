# TowerSpeed — 移动双端测速 UI

> 一个只负责视觉/交互/动画的 Flutter 壳子，为 [faceair/clash-speedtest](https://github.com/faceair/clash-speedtest) 的 CLI 工具做的移动端界面。功能（订阅拉取、节点测速、配置导出）后续由平台侧桥接。

**包名**：`tower_speed` · **应用名**：TowerSpeed · **Bundle ID**：`com.towerspeed.app`

## 平台与约束

- **iOS 16.0+**（主力），Android 兜底
- 深色优先；遵循 Swiss/Minimal 设计；避免 AI 感配色（无靛蓝/蓝紫渐变）
- 字体：**Space Grotesk**（标题/数字）+ **IBM Plex Mono**（等宽指标）

## 功能界面

| 页面 | 说明 |
|---|---|
| **Dashboard** | 大圆环实时速率、延迟/丢包读数、当前节点信息、开始/停止按钮 |
| **Nodes** | 订阅源 + 节点列表，延迟/带宽双指标、类型徽章、延迟着色、滑动展开详情 |
| **History** | 历次测速会话，汇总统计卡片，展开看每节点结果 |
| **Settings** | 测速模式（fast/download/full）、并发、超时、阈值、UA、测速服务器等 |

## 构建

### 本地
```bash
flutter pub get
cd ios && pod install && cd ..
flutter run                # 模拟器 / 真机调试
flutter build ios --release --no-codesign   # 出 Payload 打 zip（巨魔可装）
```

### GitHub Actions（无需本地 Mac）
`.github/workflows/ios-build.yml` 两个 job：

| Job | 触发 | 输出 | 用途 |
|---|---|---|---|
| `ios-unsigned` | 推 `main` / PR / 手动 | `TowerSpeed-unsigned.ipa` | **巨魔侧载**（Payload/Runner.app 打包） |
| `ios-signed` | 推 `release/*` tag | 签名 IPA + 可选 TestFlight | 需要开发者证书 secrets |

**巨魔流程**：推任意分支 → Actions 跑完 → 下载 artifact → AirDrop 到手机 → TrollStore 打开。无需证书。

**签名构建**（仅 App Store / TestFlight 才需要）：在 repo Settings → Secrets 配 `IOS_CERTIFICATE_BASE64` `IOS_CERTIFICATE_PASSWORD` `IOS_PROVISIONING_PROFILE_BASE64` `KEYCHAIN_PASSWORD` `EXPORT_OPTIONS_PLIST`（参考 `ios/ExportOptions.plist` 改成 app-store 模式 + 你的 TeamID），然后 `git tag release/v0.1.0 && git push --tags`。

## 代码结构

```
lib/
  main.dart               # ShadApp + GoRouter
  theme/                  # 设计 tokens：颜色 / 字体 / 间距 / 动效
  core/models/            # SpeedTestConfig / ProxyNode / TestResult / HistorySession
  core/mock_data.dart     # 演示数据
  router.dart             # StatefulShellRoute 四分支
  shared/widgets/         # GlassCard / SpeedRing / LatencyBadge / AnimatedGauge ...
  features/
    dashboard/            # 仪表盘（速度环 + 状态面板）
    nodes/                # 节点列表
    history/              # 历史会话
    settings/             # 设置页
```

## 对接真实逻辑

`core/mock_data.dart` 是演示数据源。后续接入时把 `MockNodeRepository` / `MockSpeedTestController` 换成调用 `clash-speedtest` 的 FFI / Platform Channel / 本地服务即可，UI 不需要改。
