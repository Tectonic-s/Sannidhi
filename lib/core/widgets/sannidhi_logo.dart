import 'package:flutter/material.dart';

/// Reusable Sannidhi Logo Widget with Light / White logo support.
///
/// - When [isDark] is true: uses `assets/images/White_Logo.png` (crisp white text for dark/maroon backgrounds).
/// - When [isDark] is false: uses `assets/images/Light-Logo.png` (black text for light/white backgrounds).
class SannidhiLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final bool? isDark;

  const SannidhiLogo({
    super.key,
    this.height = 38,
    this.fit = BoxFit.contain,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final assetPath = dark
        ? 'assets/images/White_Logo.png'
        : 'assets/images/Light-Logo.png';
    return Image.asset(
      assetPath,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/icons/app_icon.png',
        height: height,
        fit: fit,
      ),
    );
  }
}

/// Sannidhi App Launcher Icon with rounded squircle styling.
class SannidhiAppIcon extends StatelessWidget {
  final double size;
  final bool? isDark;

  const SannidhiAppIcon({
    super.key,
    this.size = 64,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
