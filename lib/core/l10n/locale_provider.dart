import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Langue de l'application : Français / English
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  bool _loaded = false;

  Locale get locale => _locale;
  bool get isFrench => _locale.languageCode == 'fr';
  bool get hasLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(AppConstants.keyLocale) ?? 'fr';
    _locale = Locale(code);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLocale, locale.languageCode);
  }

  String t(String fr, String en) => isFrench ? fr : en;
}
