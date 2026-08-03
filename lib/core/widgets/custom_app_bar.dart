import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onToggleLocale;

  const CustomAppBar({super.key, required this.onToggleLocale});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    return AppBar(
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.temple_hindu,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Text(
            isTamil ? AppTheme.appNameTamil : AppTheme.appName,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ],
      ),
      actions: [
        // Language toggle
        TextButton.icon(
          onPressed: onToggleLocale,
          icon: const Icon(Icons.language, color: Colors.white, size: 18),
          label: Text(
            isTamil
                ? l10n.translate('languageEnglish') ?? 'Eng'
                : l10n.translate('languageTamil') ?? 'தமிழ்',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        // Profile button
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _AccountPlaceholderScreen()),
            ),
            icon: const Icon(Icons.person, size: 20, color: Colors.white),
            label: Text(
              l10n.translate('account') ?? 'Account',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountPlaceholderScreen extends StatelessWidget {
  const _AccountPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: const Center(child: Text('Account screen coming soon')),
    );
  }
}
