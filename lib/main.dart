import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TowerSpeedApp());
}

class TowerSpeedApp extends StatelessWidget {
  const TowerSpeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 监听主题控制器，默认浅色
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final isDark = themeController.mode == ThemeMode.dark ||
            (themeController.mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        _applySystemUi(isDark);
        return ShadApp.router(
          title: 'TowerSpeed',
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
          themeMode: themeController.mode,
          theme: _shadTheme(Brightness.light),
          darkTheme: _shadTheme(Brightness.dark),
          builder: (context, child) => Theme(
            data: Theme.of(context).brightness == Brightness.dark
                ? buildAppTheme(Brightness.dark)
                : buildAppTheme(Brightness.light),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  void _applySystemUi(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));
  }

  ShadThemeData _shadTheme(Brightness b) {
    final p = b == Brightness.dark ? darkPalette : lightPalette;
    return ShadThemeData(
      brightness: b,
      colorScheme: (b == Brightness.dark
              ? const ShadSlateColorScheme.dark()
              : const ShadSlateColorScheme.light())
          .copyWith(
        primary: p.accent,
        secondary: p.surfaceElev,
        destructive: p.danger,
        background: p.bg,
        card: p.surface,
        muted: p.surfaceElev,
        border: p.borderStrong,
        ring: p.accent,
        primaryForeground: p.textInverse,
        secondaryForeground: p.textHi,
        destructiveForeground: Colors.white,
        foreground: p.textHi,
        cardForeground: p.textHi,
        mutedForeground: p.textMid,
      ),
      // shadcn_ui 的 textTheme 走 ShadTextTheme；默认即可，字体在 AppText 层注入
    );
  }
}
