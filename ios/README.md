# iOS 配置

本目录的 `Runner/Info.plist` 已为 TowerSpeed 定制，但 Xcode 工程文件（`.xcodeproj` / `.xcworkspace` / `Runner.xcconfig` 等）由 Flutter 工具链生成，**不应入库**。

## 首次构建

```bash
flutter create --org com.towerspeed --project-name tower_speed --platforms ios .
cd ios && pod install
flutter build ios --release
```

`flutter create` 会自动生成缺失的 `AppDelegate.swift` / `Main.storyboard` / `Assets.xcassets` 等文件。已存在的 `Info.plist` 会保留你的自定义字段（`MinimumOSVersion=16`、`CFBundleDisplayName=TowerSpeed`、浅色默认 `UIUserInterfaceStyle=Light`）。

## 关键字段

| 字段 | 值 | 说明 |
|---|---|---|
| `MinimumOSVersion` | `16.0` | 最低支持 iOS 16 |
| `CFBundleDisplayName` | `TowerSpeed` | 主屏显示名 |
| `CFBundleIdentifier` | `com.towerspeed.app` | Bundle ID（在 Xcode 里改 `PRODUCT_BUNDLE_IDENTIFIER`） |
| `UIUserInterfaceStyle` | `Light` | 默认浅色 |
