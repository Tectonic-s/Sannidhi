import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/high_contrast_widgets.dart';

class DonationScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const DonationScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    final options = [
      (
        Icons.account_balance,
        l10n.translate('trustDonation') ?? 'Trust Donation',
        isTamil ? 'நம்பிக்கை தானம்' : 'Trust Donation',
        [100, 500, 1000, 5000],
      ),
      (
        Icons.restaurant,
        l10n.translate('prasadamDonation') ?? 'Prasadam Donation',
        isTamil ? 'பிரசாதம் தானம்' : 'Prasadam Donation',
        [50, 100, 250, 500],
      ),
      (
        Icons.lightbulb,
        l10n.translate('deepamDonation') ?? 'Deepam Donation',
        isTamil ? 'தீப தானம்' : 'Deepam Donation',
        [100, 250, 500, 1000],
      ),
      (
        Icons.handshake,
        l10n.translate('sevaDonation') ?? 'Seva Donation',
        isTamil ? 'சேவை தானம்' : 'Seva Donation',
        [500, 1000, 2500, 5000],
      ),
    ];

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final opt = options[i];
          return HighContrastCard(
            height: 150,
            onTap: () => _showDonationDialog(context, l10n, opt.$2, opt.$1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.deepSaffron.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          opt.$1,
                          color: AppColors.deepSaffron,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isTamil ? opt.$3 : opt.$2,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: (opt.$4).map((amt) {
                      return InkWell(
                        onTap: () => _showDonationDialog(
                          context,
                          l10n,
                          opt.$2,
                          opt.$1,
                          amount: amt,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₹$amt',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDonationDialog(
    BuildContext context,
    AppLocalizations l10n,
    String title,
    IconData icon, {
    int amount = 500,
  }) {
    final controller = TextEditingController(text: amount.toString());
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppColors.deepSaffron),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.translate('amount') ?? 'Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('donationNote') ??
                  'Your generous donation will help us serve humanity',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              controller.dispose();
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.close),
            label: Text(l10n.translate('cancel') ?? 'Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) return;
              controller.dispose();
              Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.translate('donationSuccess') ?? 'Donation successful!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.favorite),
            label: Text(l10n.translate('donate') ?? 'Donate'),
          ),
        ],
      ),
    );
  }
}
