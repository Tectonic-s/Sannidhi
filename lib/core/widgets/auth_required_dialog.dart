import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../providers/auth_provider.dart';

/// Displays a sleek pop-up dialog stating "Sign in to access"
/// with a direct action to open the Login screen.
Future<void> showAuthRequiredDialog({
  required BuildContext context,
  String? featureName,
  VoidCallback? onToggleLocale,
}) async {
  final l10n = AppLocalizations.of(context);
  final isTamil = l10n.currentLocale == 'ta';

  final title = isTamil ? 'அணுக உள்நுழைக' : 'Sign In to Access';
  final subtitle = featureName != null
      ? (isTamil
          ? '$featureName வசதியைப் பயன்படுத்த உங்கள் கணக்கில் உள்நுழையவும்.'
          : 'Please sign in to access $featureName.')
      : (isTamil
          ? 'டிக்கெட் முன்பதிவு மற்றும் நன்கொடைகள் செய்ய தயவுசெய்து உள்நுழையவும்.'
          : 'Ticket booking and donations are exclusively available for signed-in devotees to ensure secure pass issuance and tax receipt records.');

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.lock_person_rounded,
                size: 32,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    isTamil ? 'பின்னர்' : 'Cancel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(onToggleLocale: onToggleLocale),
                      ),
                    );
                  },
                  child: Text(
                    isTamil ? 'உள்நுழைக' : 'Sign In',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A wrapper widget that greys out child content and shows a lock badge
/// when the user is not authenticated. Tapping it triggers the "Sign In to Access" popup.
class AuthGuardedWrapper extends StatelessWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onToggleLocale;

  const AuthGuardedWrapper({
    super.key,
    required this.child,
    required this.featureName,
    this.onToggleLocale,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAuthenticated = auth.isAuthenticated;

    if (isAuthenticated) {
      return child;
    }

    // Greyed out state with Lock Overlay
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showAuthRequiredDialog(
        context: context,
        featureName: featureName,
        onToggleLocale: onToggleLocale,
      ),
      child: Stack(
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.grey,
              BlendMode.saturation,
            ),
            child: Opacity(
              opacity: 0.55,
              child: IgnorePointer(child: child),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Color(0xFFFDE68A), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Sign In',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A persistent lock banner to place at the top of restricted screens like Bookings and Donation
class AuthLockBanner extends StatelessWidget {
  final String featureName;
  final VoidCallback? onToggleLocale;

  const AuthLockBanner({
    super.key,
    required this.featureName,
    this.onToggleLocale,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil ? 'அணுக உள்நுழைக' : 'Sign In Required',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  isTamil
                      ? '$featureName முன்பதிவு செய்ய கணக்கில் உள்நுழையவும்.'
                      : 'Please sign in to book passes or make donations.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => showAuthRequiredDialog(
              context: context,
              featureName: featureName,
              onToggleLocale: onToggleLocale,
            ),
            child: Text(
              isTamil ? 'உள்நுழைக' : 'Sign In',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
