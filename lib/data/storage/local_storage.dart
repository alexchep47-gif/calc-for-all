import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/calculation_history.dart';

/// Service de stockage local (préférences + historique)
class LocalStorage extends ChangeNotifier {
  SharedPreferences? _prefs;
  List<CalculationHistory> _history = [];

  List<CalculationHistory> get history => List.unmodifiable(_history);

  Set<String> get favoriteModules =>
      (_prefs?.getStringList(AppConstants.keyFavorites) ?? const <String>[])
          .toSet();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final jsonString = _prefs?.getString(AppConstants.keyHistory);
    if (jsonString != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonString);
        _history = list
            .map((e) => CalculationHistory.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      } catch (_) {
        _history = [];
      }
    }
  }

  Future<void> addToHistory(String expression, String result) async {
    final item = CalculationHistory(
      expression: expression,
      result: result,
      timestamp: DateTime.now(),
    );
    _history.insert(0, item);
    if (_history.length > AppConstants.maxHistoryItems) {
      _history = _history.sublist(0, AppConstants.maxHistoryItems);
    }
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _prefs?.remove(AppConstants.keyHistory);
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final jsonString = jsonEncode(_history.map((e) => e.toJson()).toList());
    await _prefs?.setString(AppConstants.keyHistory, jsonString);
  }

  Future<bool> isOnboardingDone() async {
    return _prefs?.getBool(AppConstants.keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    await _prefs?.setBool(AppConstants.keyOnboardingDone, value);
  }

  Future<String?> getThemeMode() async {
    return _prefs?.getString(AppConstants.keyThemeMode);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(AppConstants.keyThemeMode, mode);
  }

  Future<void> toggleFavorite(String route) async {
    final favorites = favoriteModules;
    if (!favorites.add(route)) favorites.remove(route);
    await _prefs?.setStringList(AppConstants.keyFavorites, favorites.toList());
    notifyListeners();
  }
}
