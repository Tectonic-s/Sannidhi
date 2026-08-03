import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/high_contrast_widgets.dart';
import '../../../data/repositories/mock_shuttle_repository.dart';

class BookingsScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const BookingsScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shuttleRepo = Provider.of<MockShuttleRepository>(context);

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: l10n.translate('shuttleBus') ?? 'Shuttle Bus',
          ),
          const SizedBox(height: 12),
          ...shuttleRepo.getBookings().map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: HighContrastCard(
                  height: 100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: AppColors.info, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(b.time,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary)),
                                  const SizedBox(width: 8),
                                  StatusBadge(status: b.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${b.pickupLocation} → ${b.dropLocation}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                              ),
                              Text(
                                '₹${b.price.toStringAsFixed(0)}  •  ${b.seats} seats',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          HighContrastButton(
            icon: Icons.add_circle_outline,
            text: l10n.translate('bookShuttle') ?? 'Book Shuttle',
            onPressed: () {},
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: l10n.translate('darshan') ?? 'Darshan',
          ),
          const SizedBox(height: 12),
          HighContrastCard(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.deepSaffron.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.visibility,
                        color: AppColors.deepSaffron, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.translate('darshanSlots') ?? 'Darshan Slots',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.translate('bookDarshan') ??
                              'Book your darshan slot',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary),
    );
  }
}
