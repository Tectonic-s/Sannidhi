import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_theme.dart';
import '../services/geofence_service.dart';
import '../../presentation/views/home/family_visitor_prompt_bottom_sheet.dart';

class NotificationDemoBanner extends StatelessWidget {
  final bool isTamil;

  const NotificationDemoBanner({
    super.key,
    required this.isTamil,
  });

  static Future<void> triggerDemo(BuildContext context, {required bool isTamil}) async {
    HapticFeedback.heavyImpact();
    // 1. Simulate crossing into temple 500m geofence radius
    await GeofenceService.instance.simulateHardwareTrigger(true);

    if (context.mounted) {
      // 2. Present the in-app Family Visitor Prompt Bottom Sheet
      FamilyVisitorPromptBottomSheet.show(context, isTamil: isTamil);

      // 3. Confirm with floating SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF0F766E),
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTamil
                      ? '🔔 அறிவிப்பு அனுப்பப்பட்டது! Notification Bar-ல் உள்ள 1-Tap பட்டன்களை சோதிக்கவும்.'
                      : '🔔 Push notification fired! Check phone notification tray / lock-screen for 1-tap buttons.',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  static Future<void> triggerExitDemo(BuildContext context, {required bool isTamil}) async {
    HapticFeedback.mediumImpact();
    await GeofenceService.instance.simulateHardwareTrigger(false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          backgroundColor: const Color(0xFF334155),
          content: Row(
            children: [
              const Icon(Icons.exit_to_app_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTamil
                      ? '🚪 வெளியேறுதல் பதிவு செய்யப்பட்டது! நெரிசல் எண்ணிக்கை தானாக குறைக்கப்பட்டது.'
                      : '🚪 Temple exit simulated! Crowd tally deducted and goodbye notification sent.',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final geofence = GeofenceService.instance;
    final isInside = geofence.isInsideTemple;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.55) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInside
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0)),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with live demo badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil
                          ? 'ஜியோபென்ஸ் & அறிவிப்பு மாதிரி (Demo)'
                          : 'Geofence & Footfall Notification Demo',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      isInside
                          ? (isTamil ? 'தற்போது: கோயில் எல்லைக்குள் உள்ளீர்கள்' : 'Status: Inside Temple Perimeter')
                          : (isTamil ? 'தற்போது: எல்லைக்கு வெளியே' : 'Status: Outside Perimeter'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isInside ? const Color(0xFF10B981) : AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isInside
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFD97706).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isInside ? 'ACTIVE' : 'DEMO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isInside ? const Color(0xFF10B981) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Subtitle
          Text(
            isTamil
                ? 'மருதமலை கோயில் 500மீ சுற்றளவுக்குள் பக்தர்கள் நுழையும்போது வரும் அறிவிப்பு மற்றும் குடும்ப உறுப்பினர் பதிவு திரையை உடனே சோதிக்கவும்:'
                : 'Simulate entering the 500m temple geofence to test lock-screen action notifications & the family member visitor popup:',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  onPressed: () => triggerDemo(context, isTamil: isTamil),
                  icon: const Icon(Icons.touch_app_rounded, size: 16),
                  label: Text(
                    isTamil ? 'அறிவிப்பை சோதி (Enter)' : 'Test Arrival Notification',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onPressed: () => triggerExitDemo(context, isTamil: isTamil),
                  icon: Icon(
                    Icons.exit_to_app_rounded,
                    size: 15,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                  label: Text(
                    isTamil ? 'வெளியேறு (Exit)' : 'Test Exit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
