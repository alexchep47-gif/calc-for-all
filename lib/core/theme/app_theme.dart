import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Gestionnaire de thème clair, sombre et OLED avec persistance locale.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _oled = false;
  bool _hasLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isOled => _oled;
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
}

/// Thèmes modernes de l'application.
class AppTheme {
  static const Color primaryColor = Color(0xFF1565C0);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color errorColor = Color(0xFFE53935);

  static ThemeData get lightTheme =>
      _theme(Brightness.light, const Color(0xFFF0F4F8), Colors.white);
  static ThemeData get darkTheme =>
      _theme(Brightness.dark, const Color(0xFF0D0D0D), const Color(0xFF1E1E1E));
  static ThemeData get oledTheme =>
      _theme(Brightness.dark, Colors.black, const Color(0xFF080808));

  static ThemeData _theme(Brightness brightness, Color background, Color card) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: isDark ? const Color(0xFF42A5F5) : primaryColor,
        secondary: accentColor,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDark ? card : primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
      ),
      cardTheme: CardTheme(
        elevation: 1.5,
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: card,
      ),
    );
  }
}
