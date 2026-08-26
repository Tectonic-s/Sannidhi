import 'package:flutter/material.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _isElderlyMode = false;

  bool get isElderlyMode => _isElderlyMode;

  void toggle() {
    _isElderlyMode = !_isElderlyMode;
    notifyListeners();
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
