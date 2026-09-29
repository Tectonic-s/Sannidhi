import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _isElderlyMode = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get isElderlyMode => _isElderlyMode;
  ThemeMode get themeMode => _themeMode;
  ThemeMode get currentThemeMode => _themeMode;

  AccessibilityProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isElderlyMode = prefs.getBool('preferred_elderly_mode') ?? false;
    final savedMode = prefs.getString('theme_mode');
    if (savedMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  void toggle() {
    _isElderlyMode = !_isElderlyMode;
    SharedPreferences.getInstance().then((p) {
      p.setBool('preferred_elderly_mode', _isElderlyMode);
    });
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.light) {
      await prefs.setString('theme_mode', 'light');
    } else if (mode == ThemeMode.dark) {
      await prefs.setString('theme_mode', 'dark');
    } else {
      await prefs.setString('theme_mode', 'system');
    }
  }

  // ── Colour overrides ───────────────────────────────────────────────────────
  Color get primaryColor =>
      _isElderlyMode ? const Color(0xFFD97706) : const Color(0xFF800000);

  Color get textColor =>
      _isElderlyMode ? const Color(0xFF1F2937) : const Color(0xFF333333);

  Color get backgroundColor =>
      _isElderlyMode ? const Color(0xFFFFFBEB) : const Color(0xFFF5F5F5);

  Color get cardColor =>
      _isElderlyMode ? Colors.white : Colors.white;

  BorderSide get cardBorder => _isElderlyMode
      ? const BorderSide(color: Color(0xFFD97706), width: 2)
      : BorderSide.none;

  // ── Typography ─────────────────────────────────────────────────────────────
  double get textScaleFactor => _isElderlyMode ? 1.35 : 1.0;

  double get minTouchTarget => _isElderlyMode ? 64.0 : 56.0;

  TextStyle headline(TextStyle base) => base.copyWith(
        color: textColor,
        fontSize: (base.fontSize ?? 16) * (_isElderlyMode ? 1.35 : 1.0),
        fontWeight: _isElderlyMode ? FontWeight.w800 : base.fontWeight,
      );

  TextStyle body(TextStyle base) => base.copyWith(
        color: textColor,
        fontSize: (base.fontSize ?? 14) * (_isElderlyMode ? 1.35 : 1.0),
      );
}
