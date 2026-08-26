import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../../../presentation/views/account/account_screen.dart';

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
          Image.asset('assets/icons/app_icon.png', width: 36, height: 36),
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
        TextButton(
          onPressed: onToggleLocale,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 56),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: Text(
            isTamil
                ? l10n.translate('languageEnglish') ?? 'Eng'
                : l10n.translate('languageTamil') ?? 'தமிழ்',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AccountScreen(onToggleLocale: onToggleLocale),
            ),
          ),
          icon: const Icon(Icons.person_outline, color: Colors.white, size: 26),
          padding: const EdgeInsets.only(right: 12),
        ),
      ],
    );
  }
}


