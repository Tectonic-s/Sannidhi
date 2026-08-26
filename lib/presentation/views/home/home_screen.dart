import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/announcement_ticker.dart';
import '../../../core/widgets/crowd_forecaster_chart.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/repositories/mock_crowd_repository.dart';
import '../../../data/repositories/mock_festival_repository.dart';
import '../ai_assistant_dialog.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const HomeScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AiAssistantDialog(isTamil: isTamil),
        ),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: Text(
            isTamil ? 'கேள்வி கேளுங்கள்' : 'Ask a Question',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _CrowdStatusCard(),
                  const SizedBox(height: 16),
                  const CrowdForecasterChart(),
                  const SizedBox(height: 20),
                  _UpcomingEventsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crowd Status Card ─────────────────────────────────────────────────────────

class _CrowdStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final crowd = Provider.of<MockCrowdRepository>(context).getCrowdData();
    final isTamil = l10n.currentLocale == 'ta';

    final statusKey = crowd.status.toLowerCase().replaceAll(' ', '');

    // Human-friendly labels
    String bigEmoji;
    String bigLabel;
    String subLabel;
    Color statusColor;

    switch (statusKey) {
      case 'low':
        bigEmoji = '😊';
        bigLabel = isTamil ? 'கூட்டம் குறைவு' : 'Not Crowded';
        subLabel = isTamil
            ? 'இப்போது வரலாம்! வரிசை குறைவாக இருக்கும்.'
            : 'Good time to visit! Short queue.';
        statusColor = AppColors.success;
        break;
      case 'high':
        bigEmoji = '😰';
        bigLabel = isTamil ? 'அதிக கூட்டம்' : 'Very Crowded';
        subLabel = isTamil
            ? 'கொஞ்சம் காத்திருக்க வேண்டும். பொறுமையாக வாருங்கள்.'
            : 'Long queue expected. Please be patient.';
        statusColor = AppColors.error;
        break;
      case 'veryhigh':
        bigEmoji = '🚨';
        bigLabel = isTamil ? 'மிக அதிக கூட்டம்' : 'Extremely Crowded';
        subLabel = isTamil
            ? 'மிகவும் கூட்டமாக உள்ளது. சற்று நேரம் கழித்து வாருங்கள்.'
            : 'Very long wait. Try visiting later today.';
        statusColor = Colors.deepPurple;
        break;
      default:
        bigEmoji = '🙂';
        bigLabel = isTamil ? 'சாதாரண கூட்டம்' : 'Moderate Crowd';
        subLabel = isTamil
            ? 'சாதாரண வரிசை இருக்கும். வரலாம்.'
            : 'Normal queue. You can visit now.';
        statusColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(bigEmoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bigLabel,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isTamil ? 18 : 22,
                      fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isTamil
                              ? 'காத்திருப்பு: ~${crowd.estimatedWaitMinutes} நிமிடம்'
                              : 'Wait: ~${crowd.estimatedWaitMinutes} minutes',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Events ───────────────────────────────────────────────────────────

class _UpcomingEventsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final festivals =
        Provider.of<MockFestivalRepository>(context).getUpcomingFestivals(limit: 3);

    if (festivals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTamil ? 'வரும் திருவிழாக்கள்' : 'Upcoming Festivals',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        ...festivals.map((f) {
          final target = DateTime.tryParse(f.date);
          final diff = target?.difference(DateTime.now()).inDays;
          String countdown = '';
          if (diff != null) {
            if (diff == 0) {
              countdown = isTamil ? '🎉 இன்று!' : '🎉 Today!';
            } else if (diff == 1) {
              countdown = isTamil ? 'நாளை' : 'Tomorrow';
            } else {
              countdown = isTamil ? '$diff நாட்களில்' : 'In $diff days';
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 6,
                    offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.deepSaffron.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🛕', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? f.tamilName : f.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.date,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (countdown.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.deepSaffron.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      countdown,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepSaffron),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
