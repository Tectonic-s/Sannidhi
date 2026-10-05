import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BulletinItem {
  final String id;
  final IconData icon;
  final String categoryEn;
  final String categoryTa;
  final String textEn;
  final String textTa;
  final Color accentColor;
  final bool isCustom;
  final DateTime createdAt;

  const BulletinItem({
    required this.id,
    required this.icon,
    required this.categoryEn,
    required this.categoryTa,
    required this.textEn,
    required this.textTa,
    required this.accentColor,
    this.isCustom = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'categoryEn': categoryEn,
        'categoryTa': categoryTa,
        'textEn': textEn,
        'textTa': textTa,
        'accentColorValue': accentColor.toARGB32(),
        'isCustom': isCustom,
        'createdAt': createdAt.toIso8601String(),
      };

  static IconData _resolveIcon(int? codePoint) {
    if (codePoint == null) return Icons.campaign_rounded;
    if (codePoint == Icons.two_wheeler_rounded.codePoint) return Icons.two_wheeler_rounded;
    if (codePoint == Icons.auto_stories_rounded.codePoint) return Icons.auto_stories_rounded;
    if (codePoint == Icons.restaurant_rounded.codePoint) return Icons.restaurant_rounded;
    if (codePoint == Icons.warning_rounded.codePoint) return Icons.warning_rounded;
    if (codePoint == Icons.directions_bus_rounded.codePoint) return Icons.directions_bus_rounded;
    if (codePoint == Icons.water_drop_rounded.codePoint) return Icons.water_drop_rounded;
    if (codePoint == Icons.info_rounded.codePoint) return Icons.info_rounded;
    return Icons.campaign_rounded;
  }

  factory BulletinItem.fromJson(Map<String, dynamic> json) {
    return BulletinItem(
      id: json['id'] as String? ?? UniqueKey().toString(),
      icon: _resolveIcon(json['iconCodePoint'] as int?),
      categoryEn: json['categoryEn'] as String? ?? 'ANNOUNCEMENT',
      categoryTa: json['categoryTa'] as String? ?? 'அறிவிப்பு',
      textEn: json['textEn'] as String? ?? '',
      textTa: json['textTa'] as String? ?? (json['textEn'] as String? ?? ''),
      accentColor: Color(json['accentColorValue'] as int? ?? 0xFFF59E0B),
      isCustom: json['isCustom'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class BulletinProvider extends ChangeNotifier {
  static const String _kCustomBulletinsPrefKey = 'admin_custom_bulletins';

  // Core base bulletins specified by temple administration
  static final List<BulletinItem> _defaultCoreBulletins = [
    BulletinItem(
      id: 'core_safety_twowheeler',
      icon: Icons.two_wheeler_rounded,
      categoryEn: 'SAFETY ADVISORY',
      categoryTa: 'பாதுகாப்பு எச்சரிக்கை',
      textEn: 'Two-wheelers are not allowed for travel to the hilltop after 5:00 PM for safety purposes.',
      textTa: 'பாதுகாப்பு காரணங்களுக்காக மாலை 5:00 மணிக்கு மேல் இருசக்கர வாகனங்கள் மலைப்பாதையில் செல்ல அனுமதி இல்லை.',
      accentColor: const Color(0xFFEF4444),
      isCustom: false,
      createdAt: DateTime(2026, 1, 1),
    ),
    BulletinItem(
      id: 'core_daily_recitations',
      icon: Icons.auto_stories_rounded,
      categoryEn: 'DAILY RECITATION',
      categoryTa: 'தினசரி பாராயணம்',
      textEn: 'Special recitations everyday at 6:00 PM at the temple.',
      textTa: 'திருக்கோயிலில் தினமும் மாலை 6:00 மணிக்கு சிறப்பு கூட்டுப் பாராயணம் நடைபெறும்.',
      accentColor: const Color(0xFFF59E0B),
      isCustom: false,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  final List<BulletinItem> _customBulletins = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Combined active bulletins: Core bulletins followed by custom Admin-added bulletins
  List<BulletinItem> get items => [
        ..._defaultCoreBulletins,
        ..._customBulletins,
      ];

  List<BulletinItem> get coreBulletins => List.unmodifiable(_defaultCoreBulletins);
  List<BulletinItem> get customBulletins => List.unmodifiable(_customBulletins);

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_kCustomBulletinsPrefKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        _customBulletins.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _customBulletins.add(BulletinItem.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('[BulletinProvider] Load error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  /// Add a new live bulletin created by the Admin
  Future<void> addBulletin({
    required String categoryEn,
    required String categoryTa,
    required String textEn,
    required String textTa,
    IconData icon = Icons.campaign_rounded,
    Color accentColor = const Color(0xFFD97706),
  }) async {
    final newItem = BulletinItem(
      id: 'bulletin_${DateTime.now().millisecondsSinceEpoch}',
      icon: icon,
      categoryEn: categoryEn.trim().toUpperCase(),
      categoryTa: categoryTa.trim().isNotEmpty ? categoryTa.trim() : categoryEn.trim(),
      textEn: textEn.trim(),
      textTa: textTa.trim().isNotEmpty ? textTa.trim() : textEn.trim(),
      accentColor: accentColor,
      isCustom: true,
      createdAt: DateTime.now(),
    );

    _customBulletins.insert(0, newItem);
    await _persist();
    notifyListeners();
  }

  /// Remove a custom bulletin by its ID
  Future<void> removeBulletin(String id) async {
    _customBulletins.removeWhere((item) => item.id == id);
    await _persist();
    notifyListeners();
  }

  /// Reset all custom bulletins back to the 2 core bulletins
  Future<void> resetToDefaults() async {
    _customBulletins.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(_customBulletins.map((b) => b.toJson()).toList());
      await prefs.setString(_kCustomBulletinsPrefKey, rawJson);
    } catch (e) {
      debugPrint('[BulletinProvider] Persist error: $e');
    }
  }
}
