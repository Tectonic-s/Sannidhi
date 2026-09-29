import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/footfall_service.dart';

class CrowdForecasterChart extends StatelessWidget {
  const CrowdForecasterChart({super.key});

  // Temple open: 05:30–13:00 and 14:00–20:30
  static bool _isOpen(int hour) {
    return (hour >= 6 && hour < 13) || (hour >= 14 && hour <= 20);
  }

  // Fixed 12 slots: 6 AM to 8 PM (every hour, skipping 13 = lunch)
  static const _slots = [6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20];

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final points = _slots.map((h) {
      final dt = today.add(Duration(hours: h));
      final open = _isOpen(h);
      final result = open ? FootfallService.instance.estimate(dt) : null;
      return (h, dt, open, result);
    }).toList();

    // Best open slot = lowest density
    int bestIdx = -1;
    int bestDensity = 101;
    for (int i = 0; i < points.length; i++) {
      final r = points[i].$4;
      if (r != null && r.crowdDensityPercent < bestDensity) {
        bestDensity = r.crowdDensityPercent;
        bestIdx = i;
      }
    }

    final bestHour = bestIdx >= 0 ? points[bestIdx].$2 : null;

    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(Icons.people, color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTamil ? 'கோயிலில் எத்தனை கூட்டம் உள்ளது?' : 'How Busy is the Temple?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isTamil ? 'திறப்பு: காலை 5:30 – பகல் 1:00 & மாலை 2:00 – 8:30' : 'Open: 5:30 AM–1 PM & 2–8:30 PM',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 14),

          // Best time banner
          if (bestHour != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F2913) : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'இன்று வருவதற்கு சிறந்த நேரம்' : 'Best time to visit today',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          isTamil
                              ? '${_fmtFull(bestHour)} — மிகவும் குறைவான கூட்டம்! 😊'
                              : '${_fmtFull(bestHour)} — Very few people! 😊',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Bar chart
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              height: 220,
              width: _slots.length * 56.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: points.asMap().entries.map((e) {
                  final idx = e.key;
                  final hour = e.value.$1;
                  final dt = e.value.$2;
                  final open = e.value.$3;
                  final result = e.value.$4;
                  final isBest = idx == bestIdx;
                  final isPast = dt.isBefore(DateTime.now());

                  final double frac = open && result != null
                      ? result.crowdDensityPercent / 100.0
                      : 0.0;

                  final Color barColor = !open
                      ? (isDark ? const Color(0xFF27272A) : Colors.grey.shade300)
                      : isPast
                          ? (isBest
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                              : result!.color.withValues(alpha: 0.4))
                          : isBest
                              ? const Color(0xFF4CAF50)
                              : result!.color;

                  return SizedBox(
                    width: 56,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          if (isBest && open)
                            const Text('🙏', style: TextStyle(fontSize: 14))
                          else
                            const SizedBox(height: 18),
                          const SizedBox(height: 4),
                          if (open && result != null)
                            Text(
                              '${result.crowdDensityPercent}%',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isBest
                                      ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32))
                                      : AppTheme.textSecondaryOf(context)),
                            )
                          else
                            const SizedBox(height: 12),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: open
                                ? (frac * 120).clamp(8.0, 120.0)
                                : 8.0,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fmt(hour),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: isBest
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: !open
                                    ? (isDark ? const Color(0xFF52525B) : Colors.grey.shade400)
                                    : isBest
                                        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32))
                                        : AppTheme.textSecondaryOf(context)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Closed label
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(isTamil ? 'மூட்டப்பட்டது (மதிய இடைவேளை)' : 'Closed (lunch break)',
                    style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF71717A) : Colors.grey.shade500)),
                const SizedBox(width: 16),
                _legend(context, const Color(0xFF4CAF50), isTamil ? 'குறைவு' : 'Few'),
                const SizedBox(width: 12),
                _legend(context, const Color(0xFFFF9800), isTamil ? 'சராசரி' : 'Moderate'),
                const SizedBox(width: 12),
                _legend(context, const Color(0xFFF44336), isTamil ? 'அதிகம்' : 'Crowded'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label) => Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
        ],
      );

  String _fmt(int hour) {
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$display$suffix';
  }

  String _fmtFull(DateTime dt) {
    final h = dt.hour;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final display = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final m = dt.minute == 0 ? '' : ':${dt.minute.toString().padLeft(2, '0')}';
    return '$display$m $suffix';
  }
}
