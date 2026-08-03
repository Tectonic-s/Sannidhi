import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/high_contrast_widgets.dart';

class ServicesScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const ServicesScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    final services = [
      (
        Icons.auto_awesome,
        l10n.translate('specialPooja') ?? 'Special Pooja',
        isTamil ? 'சிறப்பு பூஜை' : 'Special Pooja',
        'Book special poojas with priest',
        AppColors.deepSaffron,
      ),
      (
        Icons.volunteer_activism,
        l10n.translate('archanai') ?? 'Archanai',
        isTamil ? 'அர்ச்சனை' : 'Archanai',
        l10n.translate('archanaiDesc') ?? 'Personalized deity worship',
        AppColors.templeMaroon,
      ),
      (
        Icons.restaurant,
        l10n.translate('prasadam') ?? 'Prasadam',
        isTamil ? 'பிரசாதம்' : 'Prasadam',
        l10n.translate('prasadamDesc') ?? 'Order prasadam for delivery',
        AppColors.success,
      ),
      (
        Icons.handshake,
        l10n.translate('seva') ?? 'Seva',
        isTamil ? 'சேவை' : 'Seva',
        l10n.translate('sevaDesc') ?? 'Volunteer services and donations',
        AppColors.info,
      ),
    ];

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = services[i];
          return HighContrastCard(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: s.$5.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.$1, color: s.$5, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isTamil ? s.$3 : s.$2,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(s.$4,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
