import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アプリ全体のテーマ定義
class AppTheme {
  AppTheme._();

  // カラーパレット - 宇宙をイメージしたダークテーマ
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color accentColor = Color(0xFF22D3EE); // Cyan

  // 背景色
  static const Color backgroundColor = Color(0xFF0F0F23);
  static const Color surfaceColor = Color(0xFF1A1A2E);
  static const Color cardColor = Color(0xFF16213E);

  // リスクレベルカラー（信号機カラー）
  static const Color safeColor = Color(0xFF10B981); // 安全 - Green
  static const Color cautionColor = Color(0xFFF59E0B); // 注意 - Amber
  static const Color warningColor = Color(0xFFF97316); // 警告 - Orange
  static const Color dangerColor = Color(0xFFEF4444); // 危険 - Red

  // テキストカラー
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color.fromARGB(255, 255, 255, 255);
  static const Color textMuted = Color.fromARGB(255, 255, 255, 255);

  /// ダークテーマ
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceColor,
        error: dangerColor,
      ),
      textTheme: GoogleFonts.notoSansJpTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(color: cardColor, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.3);
          }
          return surfaceColor;
        }),
      ),
    );
  }
}

/// リスクレベルに応じた色を取得
Color getRiskColor(int level) {
  switch (level) {
    case 1:
    case 2:
      return AppTheme.safeColor;
    case 3:
      return AppTheme.cautionColor;
    case 4:
    case 5:
      return AppTheme.dangerColor;
    default:
      return AppTheme.textMuted;
  }
}

/// リスクレベルに応じたラベルを取得
String getRiskLabel(int level) {
  switch (level) {
    case 1:
      return '良好';
    case 2:
      return '安定';
    case 3:
      return '注意';
    case 4:
      return '警戒';
    case 5:
      return '厳重警戒';
    default:
      return '不明';
  }
}
