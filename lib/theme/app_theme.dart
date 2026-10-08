import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'tokens.dart';

/// 主题控制器 —— ChangeNotifier，由 main.dart 持有，Settings 页写。
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;   // 默认浅色
  ThemeMode get mode => _mode;

  void setMode(ThemeMode m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
  }
}

/// 全局单例（简单 app 够用；大项目换 Provider/Riverpod）。
final themeController = ThemeController();

/// 由亮度构建 ThemeData。
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final p = isDark ? darkPalette : lightPalette;
  final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    dividerColor: p.border,
    splashColor: p.accent.withOpacity(0.10),
    highlightColor: Colors.transparent,
    hoverColor: p.accent.withOpacity(0.04),
    brightness: brightness,
    colorScheme: base.colorScheme.copyWith(
      brightness: brightness,
      primary: p.accent,
      secondary: p.accentDim,
      surface: p.surface,
      surfaceContainerHighest: p.surfaceElev,
      error: p.danger,
      onPrimary: p.textInverse,
      onSurface: p.textHi,
      onSecondary: p.textHi,
      outline: p.borderStrong,
      outlineVariant: p.border,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: p.textHi, fontSize: 22, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: p.textHi),
    ),
    textTheme: base.textTheme.apply(bodyColor: p.textMid, displayColor: p.textHi),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: p.textMid, size: 20),
    cardColor: p.surface,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
