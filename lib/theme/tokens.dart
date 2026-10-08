import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 调色板 —— 一组完整的颜色语义（light / dark 各一份）。
/// 用 `AppColors.of(context)` 在 widget 里取当前主题的那一份。
@immutable
class AppPalette {
  // 表面
  final Color bg;
  final Color surface;
  final Color surfaceElev;
  final Color surfaceGlass;   // 玻璃填充（低 alpha）
  final Color border;
  final Color borderStrong;

  // 文本
  final Color textHi;
  final Color textMid;
  final Color textLo;
  final Color textInverse;    // 主色上的文字

  // 语义
  final Color accent;
  final Color accentDim;
  final Color warn;
  final Color danger;
  final Color info;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceElev,
    required this.surfaceGlass,
    required this.border,
    required this.borderStrong,
    required this.textHi,
    required this.textMid,
    required this.textLo,
    required this.textInverse,
    required this.accent,
    required this.accentDim,
    required this.warn,
    required this.danger,
    required this.info,
  });

  /// 延迟热度（两套主题共用——语义色，亮度对比已校验）
  static const latGood = Color(0xFF059669);   // emerald-600, 浅底更醒目
  static const latMid = Color(0xFFD97706);    // amber-600
  static const latBad = Color(0xFFEA580C);    // orange-600
  static const latDead = Color(0xFFDC2626);   // red-600
  static const latGoodDark = Color(0xFF34D399);
  static const latMidDark = Color(0xFFFBBF24);
  static const latBadDark = Color(0xFFF97316);
  static const latDeadDark = Color(0xFFEF4444);

  static const spSlow = latDead;
  static const spMid = latMid;
  static const spFast = latGood;
  static const spUltra = Color(0xFF0D9488);   // teal-600
  static const spUltraDark = Color(0xFF2DD4BF);
}

/// —— 亮色主题 ——
const lightPalette = AppPalette(
  bg: Color(0xFFF6F7FB),
  surface: Color(0xFFFFFFFF),
  surfaceElev: Color(0xFFF0F1F7),
  surfaceGlass: Color(0x0F0B1220),      // 6% 深色 tint
  border: Color(0x0F0B1220),
  borderStrong: Color(0x1A0B1220),
  textHi: Color(0xFF0B1220),
  textMid: Color(0xFF3D4763),
  textLo: Color(0xFF7B85A3),
  textInverse: Color(0xFFF6F7FB),
  accent: Color(0xFF059669),            // emerald-600
  accentDim: Color(0xFF047857),
  warn: Color(0xFFD97706),
  danger: Color(0xFFDC2626),
  info: Color(0xFF0284C7),
);

/// —— 深色主题 ——
const darkPalette = AppPalette(
  bg: Color(0xFF0F172A),
  surface: Color(0xFF141C33),
  surfaceElev: Color(0xFF1A2440),
  surfaceGlass: Color(0x14FFFFFF),      // 8% 白色
  border: Color(0x14FFFFFF),
  borderStrong: Color(0x26FFFFFF),
  textHi: Color(0xFFF4F7FB),
  textMid: Color(0xFFB7C0D6),
  textLo: Color(0xFF6E7B99),
  textInverse: Color(0xFF0F172A),
  accent: Color(0xFF34D399),            // emerald-400
  accentDim: Color(0xFF10B981),
  warn: Color(0xFFFBBF24),
  danger: Color(0xFFEF4444),
  info: Color(0xFF38BDF8),
);

/// 主题感知访问器 —— `AppColors.of(context).xxx`。
class AppColors {
  final AppPalette p;
  final bool isDark;
  const AppColors._(this.p, this.isDark);

  static AppColors of(BuildContext context) {
    final b = Theme.of(context).brightness;
    return AppColors._(b == Brightness.dark ? darkPalette : lightPalette, b == Brightness.dark);
  }

  // 表面
  Color get bg => p.bg;
  Color get surface => p.surface;
  Color get surfaceElev => p.surfaceElev;
  Color get surfaceGlass => p.surfaceGlass;
  Color get border => p.border;
  Color get borderStrong => p.borderStrong;

  // 文本
  Color get textHi => p.textHi;
  Color get textMid => p.textMid;
  Color get textLo => p.textLo;
  Color get textInverse => p.textInverse;

  // 语义
  Color get accent => p.accent;
  Color get accentDim => p.accentDim;
  Color get warn => p.warn;
  Color get danger => p.danger;
  Color get info => p.info;

  // —— 延迟 / 速度热度（按主题微调）——
  Color get latGood => isDark ? AppPalette.latGoodDark : AppPalette.latGood;
  Color get latMid => isDark ? AppPalette.latMidDark : AppPalette.latMid;
  Color get latBad => isDark ? AppPalette.latBadDark : AppPalette.latBad;
  Color get latDead => isDark ? AppPalette.latDeadDark : AppPalette.latDead;
  Color get spUltra => isDark ? AppPalette.spUltraDark : AppPalette.spUltra;

  Color latencyColor(int? ms) {
    if (ms == null) return textLo;
    if (ms <= 200) return latGood;
    if (ms <= 500) return latMid;
    if (ms <= 800) return latBad;
    return latDead;
  }

  Color speedColor(double? mbps) {
    if (mbps == null) return textLo;
    if (mbps < 1) return latDead;
    if (mbps < 5) return latMid;
    if (mbps < 20) return latGood;
    return spUltra;
  }
}

// —— 间距 / 圆角 / 动效（主题无关）——
class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class AppDurations {
  AppDurations._();
  static const fast = Duration(milliseconds: 160);
  static const med = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
}

class AppCurves {
  AppCurves._();
  static const enter = Cubic(0.16, 1, 0.3, 1);
  static const exit = Cubic(0.4, 0, 1, 1);
  static const standard = Cubic(0.4, 0, 0.2, 1);
  static const overshoot = Cubic(0.34, 1.56, 0.64, 1);
}

/// 文字样式 —— Space Grotesk（标题） + IBM Plex Mono（数字）。
/// 颜色需要 `AppText.of(context)` 获取主题感知版本；
/// `AppText.raw` 是无色样式，可在外层再染色。
class AppText {
  final Color hi, mid, lo;
  const AppText._(this.hi, this.mid, this.lo);

  static AppText of(BuildContext context) {
    final c = AppColors.of(context);
    return AppText._(c.textHi, c.textMid, c.textLo);
  }

  TextStyle get display => GoogleFonts.spaceGrotesk(
        fontSize: 34, fontWeight: FontWeight.w700, color: hi,
        letterSpacing: -0.5, height: 1.1,
      );
  TextStyle get title => GoogleFonts.spaceGrotesk(
        fontSize: 22, fontWeight: FontWeight.w600, color: hi,
        letterSpacing: -0.2,
      );
  TextStyle get h2 => GoogleFonts.spaceGrotesk(
        fontSize: 17, fontWeight: FontWeight.w600, color: hi,
      );
  TextStyle get body => GoogleFonts.spaceGrotesk(
        fontSize: 14, fontWeight: FontWeight.w400, color: mid, height: 1.45,
      );
  TextStyle get bodySm => GoogleFonts.spaceGrotesk(
        fontSize: 12, fontWeight: FontWeight.w400, color: mid,
      );
  TextStyle get caption => GoogleFonts.spaceGrotesk(
        fontSize: 11, fontWeight: FontWeight.w500, color: lo,
        letterSpacing: 0.4,
      );
  TextStyle get mono => GoogleFonts.ibmPlexMono(
        fontSize: 14, fontWeight: FontWeight.w500, color: hi,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  TextStyle get monoBig => GoogleFonts.ibmPlexMono(
        fontSize: 48, fontWeight: FontWeight.w700, color: hi, height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  TextStyle get monoMetric => GoogleFonts.ibmPlexMono(
        fontSize: 20, fontWeight: FontWeight.w600, color: hi,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  TextStyle get monoSm => GoogleFonts.ibmPlexMono(
        fontSize: 11, fontWeight: FontWeight.w500, color: mid,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
