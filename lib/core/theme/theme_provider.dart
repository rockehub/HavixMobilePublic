import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/storefront_models.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = ThemeData.light(useMaterial3: true);
  ThemeData get themeData => _themeData;

  void applyStorefrontTheme(StorefrontTheme? sf) {
    if (sf == null) return;

    final primary = _parseColor(sf.accentColor) ?? const Color(0xFF6366F1);
    final background = _parseColor(sf.backgroundColor) ?? Colors.white;
    final surface = _parseColor(sf.surfaceColor) ?? const Color(0xFFF8FAFC);
    final onSurface = _parseColor(sf.textColor) ?? const Color(0xFF0F172A);
    final card = _parseColor(sf.cardBackgroundColor) ?? Colors.white;

    final bodyFont = _getTextTheme(sf.fontFamilyBody, onSurface);
    final headingStyle = _getHeadingStyle(sf.fontFamilyHeading, onSurface);

    _themeData = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: _parseColor(sf.borderColor) ?? const Color(0xFFE2E8F0),
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: _parseColor(sf.accentContrastColor) ?? Colors.white,
        surface: surface,
        onSurface: onSurface,
        secondary: primary.withOpacity(0.8),
        error: _parseColor(sf.errorColor) ?? const Color(0xFFEF4444),
      ),
      textTheme: bodyFont,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: headingStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: _parseColor(sf.accentContrastColor) ?? Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    notifyListeners();
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final clean = hex.replaceFirst('#', '');
      return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
    } catch (_) {
      return null;
    }
  }

  TextTheme _getTextTheme(String? fontFamily, Color textColor) {
    try {
      if (fontFamily != null && fontFamily.isNotEmpty) {
        return GoogleFonts.getTextTheme(
          fontFamily,
          ThemeData.light().textTheme.apply(bodyColor: textColor, displayColor: textColor),
        );
      }
    } catch (_) {}
    return ThemeData.light().textTheme.apply(bodyColor: textColor, displayColor: textColor);
  }

  TextStyle _getHeadingStyle(String? fontFamily, Color textColor) {
    try {
      if (fontFamily != null && fontFamily.isNotEmpty) {
        return GoogleFonts.getFont(fontFamily, color: textColor, fontSize: 18, fontWeight: FontWeight.w600);
      }
    } catch (_) {}
    return TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600);
  }
}
