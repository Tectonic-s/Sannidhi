import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../../presentation/views/account/account_screen.dart';
import 'sannidhi_logo.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onToggleLocale;

  const CustomAppBar({super.key, this.onToggleLocale});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: AppTheme.accentColor, width: 2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Centered Sannidhi Logo
              const Center(
                child: SannidhiLogo(
                  height: 38,
                  isDark: true, // App bar is dark maroon or obsidian
                ),
              ),

              // 2. Trailing Actions (Language Switcher + Account)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onToggleLocale != null)
                    TextButton(
                      onPressed: onToggleLocale,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Text(
                        isTamil ? 'ENG' : 'தமிழ்',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AccountScreen(
                          onToggleLocale: onToggleLocale ?? () {},
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    splashRadius: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
