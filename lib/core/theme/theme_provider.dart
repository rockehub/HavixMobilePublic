import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/storefront_models.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = ThemeData.light(useMaterial3: true);
  ThemeData get themeData => _themeData;

  void applyStorefrontTheme(StorefrontTheme? sf) {
    if (kDebugMode) {
      debugPrint('[Theme] applyStorefrontTheme called, sf=${sf == null ? "NULL" : "present"}');
      if (sf != null) {
        debugPrint('[Theme]   backgroundColor=${sf.backgroundColor}');
        debugPrint('[Theme]   accentColor=${sf.accentColor}');
        debugPrint('[Theme]   textColor=${sf.textColor}');
        debugPrint('[Theme]   surfaceColor=${sf.surfaceColor}');
        debugPrint('[Theme]   cardBackgroundColor=${sf.cardBackgroundColor}');
      }
    }
    if (sf == null) return;

    final primary = _parseColor(sf.accentColor) ?? const Color(0xFF6366F1);
    final background = _parseColor(sf.backgroundColor) ?? Colors.white;
    final surface = _parseColor(sf.surfaceColor) ?? const Color(0xFFF8FAFC);
    final onSurface = _parseColor(sf.textColor) ?? const Color(0xFF0F172A);
    final card = _parseColor(sf.cardBackgroundColor) ?? Colors.white;

    if (kDebugMode) {
      debugPrint('[Theme] resolved colors:');
      debugPrint('[Theme]   primary=0x${primary.value.toRadixString(16).toUpperCase()}');
      debugPrint('[Theme]   background=0x${background.value.toRadixString(16).toUpperCase()}');
      debugPrint('[Theme]   surface=0x${surface.value.toRadixString(16).toUpperCase()}');
      debugPrint('[Theme]   onSurface=0x${onSurface.value.toRadixString(16).toUpperCase()}');
      debugPrint('[Theme]   card=0x${card.value.toRadixString(16).toUpperCase()}');
    }

    final bodyFont = _getTextTheme(sf.fontFamilyBody, onSurface);
    final headingStyle = _getHeadingStyle(sf.fontFamilyHeading, onSurface);

    _themeData = ThemeData(
      useMaterial3: true,
      // In M3, Scaffold uses colorScheme.surface — set both to be safe
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: _parseColor(sf.borderColor) ?? const Color(0xFFE2E8F0),
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: _parseColor(sf.accentContrastColor) ?? Colors.white,
        // surface drives Scaffold bg in M3; use background so they match
        surface: background,
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
      var clean = hex.replaceFirst('#', '').trim();
      // Expand CSS shorthand: #fff → #ffffff, #ffff → #ffffffff
      if (clean.length == 3 || clean.length == 4) {
        clean = clean.split('').map((c) => '$c$c').join();
      }
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
