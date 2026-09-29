import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_theme.dart';

class DevoteeAvatarData {
  final String id;
  final String titleEn;
  final String titleTa;
  final IconData icon;
  final List<Color> gradient;
  final String? emoji;

  const DevoteeAvatarData({
    required this.id,
    required this.titleEn,
    required this.titleTa,
    required this.icon,
    required this.gradient,
    this.emoji,
  });
}

const List<DevoteeAvatarData> kDevoteeAvatars = [
  DevoteeAvatarData(
    id: 'vel',
    titleEn: 'Sacred Vel',
    titleTa: 'ஞான வேல்',
    icon: Icons.bolt_rounded,
    gradient: [Color(0xFFD97706), Color(0xFFEA580C)],
    emoji: '🔱',
  ),
  DevoteeAvatarData(
    id: 'om',
    titleEn: 'Pranava Om',
    titleTa: 'ஓம்',
    icon: Icons.brightness_high_rounded,
    gradient: [Color(0xFF991B1B), Color(0xFFDC2626)],
    emoji: '🕉️',
  ),
  DevoteeAvatarData(
    id: 'gopuram',
    titleEn: 'Gopuram',
    titleTa: 'கோபுரம்',
    icon: Icons.temple_hindu_rounded,
    gradient: [Color(0xFFB45309), Color(0xFF78350F)],
    emoji: '🛕',
  ),
  DevoteeAvatarData(
    id: 'lotus',
    titleEn: 'Divine Lotus',
    titleTa: 'தாமரை மலர்',
    icon: Icons.spa_rounded,
    gradient: [Color(0xFFDB2777), Color(0xFF9D174D)],
    emoji: '🪷',
  ),
  DevoteeAvatarData(
    id: 'peacock',
    titleEn: 'Mayil Vahanam',
    titleTa: 'மயில் வாகனம்',
    icon: Icons.star_rounded,
    gradient: [Color(0xFF0284C7), Color(0xFF0F766E)],
    emoji: '🦚',
  ),
  DevoteeAvatarData(
    id: 'devotee',
    titleEn: 'Devotee',
    titleTa: 'பக்தர்',
    icon: Icons.person_rounded,
    gradient: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    emoji: '🙏',
  ),
];

class DevoteeAvatar extends StatelessWidget {
  final double size;
  final String? photoPath;
  final String? avatarId;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const DevoteeAvatar({
    super.key,
    this.size = 56,
    this.photoPath,
    this.avatarId,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    // 1. Check custom uploaded/captured photo
    if (photoPath != null && photoPath!.isNotEmpty) {
      final file = File(photoPath!);
      if (file.existsSync()) {
        content = ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
          ),
        );
      } else {
        content = _fallbackAvatar();
      }
    } else {
      content = _fallbackAvatar();
    }

    final border = showBorder
        ? Border.all(
            color: borderColor ?? AppColors.goldAccent.withValues(alpha: 0.8),
            width: 2.0,
          )
        : null;

    final widget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }

  Widget _fallbackAvatar() {
    final avatar = kDevoteeAvatars.firstWhere(
      (a) => a.id == avatarId,
      orElse: () => kDevoteeAvatars.first,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: avatar.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: avatar.emoji != null
            ? Text(
                avatar.emoji!,
                style: TextStyle(fontSize: size * 0.46),
              )
            : Icon(
                avatar.icon,
                color: Colors.white,
                size: size * 0.52,
              ),
      ),
    );
  }

  /// Helper to get profile preferences asynchronously
  static Future<Map<String, String?>> getSavedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'photoPath': prefs.getString('user_profile_photo_path'),
      'avatarId': prefs.getString('user_profile_avatar_id'),
    };
  }

  /// Helper to save profile preferences
  static Future<void> saveProfile({String? photoPath, String? avatarId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (photoPath != null) {
      await prefs.setString('user_profile_photo_path', photoPath);
    }
    if (avatarId != null) {
      await prefs.setString('user_profile_avatar_id', avatarId);
    }
  }
}
