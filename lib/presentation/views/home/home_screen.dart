import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/high_contrast_widgets.dart';
import '../../../data/repositories/mock_crowd_repository.dart';
import '../../../data/repositories/mock_festival_repository.dart';
import '../bookings/bookings_screen.dart';
import '../donation/donation_screen.dart';
import '../services/services_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const HomeScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: RefreshIndicator(
        onRefresh: () =>
            Provider.of<MockCrowdRepository>(context, listen: false)
                .refreshCrowdData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CrowdStatusCard(),
            const SizedBox(height: 24),
            _QuickActionsGrid(onToggleLocale: onToggleLocale),
            const SizedBox(height: 24),
            _UpcomingEventsSection(),
          ],
        ),
      ),
    );
  }
}

class _CrowdStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crowd =
        Provider.of<MockCrowdRepository>(context).getCrowdData();

    Color statusColor;
    String emoji;
    final statusKey = crowd.status.toLowerCase().replaceAll(' ', '');
    switch (statusKey) {
      case 'low':
        statusColor = AppColors.success;
        emoji = '🟢';
        break;
      case 'high':
        statusColor = AppColors.error;
        emoji = '🔴';
        break;
      case 'veryhigh':
        statusColor = Colors.deepPurple;
        emoji = '🟣';
        break;
      default:
        statusColor = AppColors.warning;
        emoji = '🟡';
    }

    final statusLabel =
        l10n.translate('${statusKey}Crowd') ?? '${crowd.status} Crowd';

    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('crowdStatus') ?? 'Crowd Status',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(emoji, style: const TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${l10n.translate('estWait') ?? 'Est. Wait'}: '
                '${crowd.estimatedWaitMinutes} '
                '${l10n.translate('mins') ?? 'Mins'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const _QuickActionsGrid({required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final actions = [
      (
        Icons.calendar_today,
        l10n.translate('quickBooking') ?? 'Quick Booking',
        AppTheme.primaryColor,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => BookingsScreen(onToggleLocale: onToggleLocale))),
      ),
      (
        Icons.visibility,
        l10n.translate('darshan') ?? 'Darshan',
        AppTheme.accentColor,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => BookingsScreen(onToggleLocale: onToggleLocale))),
      ),
      (
        Icons.spa,
        l10n.translate('services') ?? 'Services',
        const Color(0xFF6A1B9A),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ServicesScreen(onToggleLocale: onToggleLocale))),
      ),
      (
        Icons.favorite,
        l10n.translate('donations') ?? 'Donations',
        AppColors.error,
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DonationScreen(onToggleLocale: onToggleLocale))),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('quickActions') ?? 'Quick Actions',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: actions
              .map((a) => HighContrastButton(
                    icon: a.$1,
                    text: a.$2,
                    backgroundColor: a.$3,
                    onPressed: a.$4,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final festivals =
        Provider.of<MockFestivalRepository>(context).getUpcomingFestivals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('upcomingEvents') ?? 'Upcoming Events',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: festivals.isEmpty
              ? const Center(child: Text('No upcoming events'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: festivals.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final f = festivals[i];
                    return HighContrastCard(
                      width: 180,
                      height: 160,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.deepSaffron.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(Icons.temple_hindu,
                                    size: 36, color: AppColors.deepSaffron),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTamil ? f.tamilName : f.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 12, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(f.date,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                            if (f.isSpecial) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.translate('special') ?? 'Special',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
