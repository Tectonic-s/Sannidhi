import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/footfall_service.dart';
import '../../../core/widgets/announcement_ticker.dart';
import '../../../core/widgets/crowd_forecaster_chart.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/high_contrast_widgets.dart';
import '../../../data/repositories/mock_crowd_repository.dart';
import '../../../data/repositories/mock_festival_repository.dart';
import '../bookings/bookings_screen.dart';
import '../facility/facility_locator_screen.dart';
import '../services/services_screen.dart';
import '../ai_assistant_dialog.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const HomeScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AiAssistantDialog(),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('Ask Sahayak',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          const AnnouncementTicker(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  Provider.of<MockCrowdRepository>(context, listen: false)
                      .refreshCrowdData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CrowdStatusCard(),
                  const SizedBox(height: 16),
                  const CrowdForecasterChart(),
                  const SizedBox(height: 24),
                  _QuickActionsGrid(onToggleLocale: onToggleLocale),
                  const SizedBox(height: 24),
                  _UpcomingEventsSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrowdStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crowd = Provider.of<MockCrowdRepository>(context).getCrowdData();
    final footfall = FootfallService.instance.estimate(DateTime.now());

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
              Text(l10n.translate('crowdStatus') ?? 'Crowd Status',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text(emoji, style: const TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 8),
          Text(statusLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
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
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Text(l10n.translate('footfallDensity') ?? 'Footfall Density',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Text('${footfall.crowdDensityPercent}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: footfall.crowdDensityPercent / 100,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
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
        Icons.map,
        'Facilities',
        const Color(0xFF0288D1),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => FacilityLocatorScreen(onToggleLocale: onToggleLocale))),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('quickActions') ?? 'Quick Actions',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
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
        Text(l10n.translate('upcomingEvents') ?? 'Upcoming Events',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: festivals.isEmpty
              ? const Center(child: Text('No upcoming events'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: festivals.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 12),
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
                                color: AppColors.deepSaffron
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(Icons.temple_hindu,
                                    size: 36,
                                    color: AppColors.deepSaffron),
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
                            Row(children: [
                              const Icon(Icons.calendar_today,
                                  size: 12,
                                  color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text(f.date,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                            ]),
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
