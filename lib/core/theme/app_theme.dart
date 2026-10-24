import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Gestionnaire de thème clair / sombre / OLED + taille de police.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _oled = false;
  double _fontScale = 1.0;
  bool _hasLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isOled => _oled;
  double get fontScale => _fontScale;
  bool get hasLoaded => _hasLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeMode);
    _oled = saved == 'oled';
    if (!_oled) {
      _themeMode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }
    _fontScale = prefs.getDouble(AppConstants.keyFontScale) ?? 1.0;
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _oled = false;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setOled(bool enabled) async {
    _oled = enabled;
    if (enabled) _themeMode = ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, enabled ? 'oled' : 'dark');
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale.clamp(0.85, 1.35);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyFontScale, _fontScale);
    notifyListeners();
  }
}

class AppTheme {
  static const Color primaryColor = Color(0xFF5B7CFF);
  static const Color accentColor = Color(0xFF8D5CF6);
  static const Color primarySoft = Color(0xFF7CC7FF);
  static const Color successColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFE53935);

  static const Color lightBackground = Color(0xFFF3F6FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0B1020);
  static const Color darkCard = Color(0xFF121A2B);
  static const Color darkCardAlt = Color(0xFF182335);

  static ThemeData get lightTheme =>
      _theme(Brightness.light, lightBackground, lightCard);
  static ThemeData get darkTheme =>
      _theme(Brightness.dark, darkBackground, darkCard);
  static ThemeData get oledTheme =>
      _theme(Brightness.dark, Colors.black, const Color(0xFF070B12));

  static ThemeData _theme(Brightness brightness, Color background, Color card) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? darkCardAlt : const Color(0xFFEAF0FF);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: accentColor,
        surface: card,
        surfaceContainerHighest: surface,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF101828),
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF101828),
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: card,
        shadowColor: isDark ? Colors.black.withOpacity(0.25) : Colors.blue.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.blueGrey.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.blueGrey.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: card,
      ),
      dividerColor: isDark ? Colors.white12 : Colors.blueGrey.withOpacity(0.08),
      iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1F2937)),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: isDark ? Colors.white : const Color(0xFF101828),
        displayColor: isDark ? Colors.white : const Color(0xFF101828),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
    );
  }
}

