import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/widgets/announcement_ticker.dart';
import '../../../core/widgets/auth_required_dialog.dart';
import '../../../core/widgets/crowd_forecaster_chart.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../data/repositories/mock_crowd_repository.dart';
import '../../../data/repositories/mock_festival_repository.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../providers/auth_provider.dart';
import '../facility/facility_locator_screen.dart';
import '../services/services_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  final void Function(int index)? onNavigateTab;
  final void Function(int subPage)? onNavigateBookingSubPage;

  const HomeScreen({
    super.key,
    required this.onToggleLocale,
    this.onNavigateTab,
    this.onNavigateBookingSubPage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final access = Provider.of<AccessibilityProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: Column(
        children: [
          // 1. Live Admin Broadcast Stream (Travelling through Firebase)
          _LiveAdminBroadcastBanner(isTamil: isTamil),

          // 2. LIVE announcement / news carousel
          const AnnouncementTicker(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () =>
                  Provider.of<MockCrowdRepository>(context, listen: false)
                      .refreshCrowdData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Temple Information Banner (Open/Closed status & Darshan hours)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 40),
                      child: _TempleWelcomeBanner(
                        isTamil: isTamil,
                        isElderly: access.isElderlyMode,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Live Queue & Wait Status Card
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _CrowdStatusCard(
                        isTamil: isTamil,
                        isElderly: access.isElderlyMode,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Highly Useful Visitor-Information: Today's Visit Planner
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: _TodayVisitPlannerCard(
                        isTamil: isTamil,
                        isElderly: access.isElderlyMode,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Quick Links (Immediate actions: Darshan, Bus, Parking, Wheelchair, Annadhanam, Pooja)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 240),
                      child: _QuickLinksSection(
                        isTamil: isTamil,
                        isElderly: access.isElderlyMode,
                        onNavigateTab: onNavigateTab,
                        onNavigateBookingSubPage: onNavigateBookingSubPage,
                        onToggleLocale: onToggleLocale,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 7. Upcoming Festivals / Events
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 300),
                      child: _UpcomingEventsSection(
                        isTamil: isTamil,
                        isElderly: access.isElderlyMode,
                        onNavigateTab: onNavigateTab,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Temple Welcome & Timings Banner ──────────────────────────────────────────

class _TempleWelcomeBanner extends StatelessWidget {
  final bool isTamil;
  final bool isElderly;

  const _TempleWelcomeBanner({required this.isTamil, required this.isElderly});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final isLarge = scale > 1.15 || isElderly;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F1D1D).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLarge) ...[
            // Large text: Stacks gracefully into vertical flow
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.temple_hindu,
                      color: AppTheme.accentColor, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user != null
                        ? (isTamil
                            ? 'வணக்கம், ${user.name} 🙏'
                            : 'Vanakkam, ${user.name} 🙏')
                        : (isTamil
                            ? 'ஓம் நமச்சிவாய • நல்வரவு'
                            : 'Om Namah Shivaya • Welcome'),
                    style: const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'அருள்மிகு சந்நிதி திருக்கோவில்'
                  : 'Arulmigu Sannidhi Temple',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isTamil
                  ? 'மருதமலை அடிவாரம் & மலைக்கோவில்'
                  : 'Marudamalai Foothills & Hilltop',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(isTamil),
          ] else ...[
            // Normal text: Compact single row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.temple_hindu,
                      color: AppTheme.accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null
                            ? (isTamil
                                ? 'வணக்கம், ${user.name} 🙏'
                                : 'Vanakkam, ${user.name} 🙏')
                            : (isTamil
                                ? 'ஓம் நமச்சிவாய • நல்வரவு'
                                : 'Om Namah Shivaya • Welcome'),
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTamil
                            ? 'அருள்மிகு சந்நிதி திருக்கோவில்'
                            : 'Arulmigu Sannidhi Temple',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTamil ? 17.5 : 16.5,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTamil
                            ? 'மருதமலை அடிவாரம் & மலைக்கோவில்'
                            : 'Marudamalai Foothills & Hilltop',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTamil ? 12.5 : 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(isTamil),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Darshan Hours Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_filled,
                    color: Color(0xFFFDE68A), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTamil
                        ? 'தரிசன நேரம்: காலை 6:00 - 12:30 | மாலை 4:00 - 8:30'
                        : 'Darshan Hours: 6:00 AM - 12:30 PM | 4:00 PM - 8:30 PM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: isElderly ? 13.5 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isTamil) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isTamil ? 'திறந்துள்ளது' : 'Open Now',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Real-Time Crowd Telemetry & Senior Advice Card ───────────────────────────

class _CrowdStatusCard extends StatelessWidget {
  final bool isTamil;
  final bool isElderly;

  const _CrowdStatusCard({required this.isTamil, required this.isElderly});

  @override
  Widget build(BuildContext context) {
    final crowd = Provider.of<MockCrowdRepository>(context).getCrowdData();
    final statusKey = crowd.status.toLowerCase().replaceAll(' ', '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String statusText;
    String shortTip;
    Color statusColor;
    int crowdLevel; // 1: Low, 2: Normal, 3: High, 4: Peak

    switch (statusKey) {
      case 'low':
        statusColor = const Color(0xFF16A34A);
        statusText = isTamil ? 'குறைந்த கூட்டம்' : 'Low Crowd';
        shortTip = isTamil
            ? 'அமைதியான நேரம் • சிரமமின்றி விரைவு தரிசனம் செய்யலாம்'
            : 'Comfortable queue • Ideal time for peaceful darshan';
        crowdLevel = 1;
        break;
      case 'high':
        statusColor = const Color(0xFFEA580C);
        statusText = isTamil ? 'அதிக கூட்டம்' : 'Moderate Queue';
        shortTip = isTamil
            ? 'வரிசையில் நிழல் பந்தல் & அமரும் வசதி உண்டு'
            : 'Noticeable line • Shaded seating available in queue';
        crowdLevel = 3;
        break;
      case 'veryhigh':
        statusColor = const Color(0xFFDC2626);
        statusText = isTamil ? 'நெரிசல் நேரம்' : 'Peak Crowd';
        shortTip = isTamil
            ? 'நீண்ட வரிசை • முதியோர்கள் மாலை 5:00 மணிக்கு வரலாம்'
            : 'Long wait • Seniors advised to visit after 5:00 PM';
        crowdLevel = 4;
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusText = isTamil ? 'சாதாரண வரிசை' : 'Steady Flow';
        shortTip = isTamil
            ? 'சீரான வரிசை • வசதியான தரிசனம்'
            : 'Smoothly moving line • Comfortable for all devotees';
        crowdLevel = 2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Live indicator + Title + Wait pill
          Row(
            children: [
              PulsingLiveDot(
                color: statusColor,
                size: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTamil ? 'நேரலை வரிசை நிலை' : 'Live Queue Status',
                  style: TextStyle(
                    fontSize: isElderly ? 15 : 13.5,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      isTamil
                          ? '~${crowd.estimatedWaitMinutes} நிமி'
                          : '~${crowd.estimatedWaitMinutes} min wait',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3-Segment Throughput Bar
          Row(
            children: [
              Expanded(
                child: _buildMeterSegment(
                  active: crowdLevel >= 1,
                  color: const Color(0xFF16A34A),
                  label: isTamil ? 'அமைதி' : 'Calm',
                  isCurrent: crowdLevel == 1,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMeterSegment(
                  active: crowdLevel >= 2,
                  color: const Color(0xFFD97706),
                  label: isTamil ? 'சீரானது' : 'Steady',
                  isCurrent: crowdLevel == 2,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMeterSegment(
                  active: crowdLevel >= 3,
                  color: const Color(0xFFDC2626),
                  label: isTamil ? 'நெரிசல்' : 'Crowded',
                  isCurrent: crowdLevel >= 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Concise Advice Tip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$statusText • ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
              Expanded(
                child: Text(
                  shortTip,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterSegment({
    required bool active,
    required Color color,
    required String label,
    required bool isCurrent,
  }) {
    return Column(
      children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
            color: isCurrent ? color : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

// ── 5. Today's Visit Planner Card (Actionable Guidance, No Complex Graphs) ─────

class _TodayVisitPlannerCard extends StatelessWidget {
  final bool isTamil;
  final bool isElderly;

  const _TodayVisitPlannerCard({required this.isTamil, required this.isElderly});

  void _showHourlyChart(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const CrowdForecasterChart(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x06000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: isDark ? const Color(0xFFFBBF24) : AppColors.goldAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTamil ? 'தரிசன வழிகாட்டி' : "Visit Planner",
                    style: TextStyle(
                      fontSize: isElderly ? 15 : 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showHourlyChart(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        isTamil ? 'வரைபடம்' : 'Hourly Chart',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFFBBF24) : AppColors.templeMaroon,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: isDark ? const Color(0xFFFBBF24) : AppColors.templeMaroon,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF059669).withValues(alpha: 0.5)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTamil ? 'அமைதியான நேரம்' : 'Best Time',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              '6:00 – 7:30 AM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF78350F).withValues(alpha: 0.3)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFD97706).withValues(alpha: 0.5)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTamil ? 'அதிக கூட்டம்' : 'Peak Hours',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                              ),
                            ),
                            Text(
                              '10 AM – 1 PM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                              ),
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
        ],
      ),
    );
  }
}

// ── 6. Quick Links Section (Immediate Visitor Actions) ─────────────────────────

class _QuickLinksSection extends StatelessWidget {
  final bool isTamil;
  final bool isElderly;
  final void Function(int index)? onNavigateTab;
  final void Function(int subPage)? onNavigateBookingSubPage;
  final VoidCallback? onToggleLocale;

  const _QuickLinksSection({
    required this.isTamil,
    required this.isElderly,
    this.onNavigateTab,
    this.onNavigateBookingSubPage,
    this.onToggleLocale,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final isLarge = scale > 1.25 || isElderly || isTamil;

    final items = [
      // 1. Bus Booking
      _QuickLinkData(
        icon: Icons.directions_bus_rounded,
        color: AppColors.templeMaroon,
        title: isTamil ? 'பேருந்து முன்பதிவு' : 'Bus Booking',
        subtitle: isTamil ? 'அடிவாரம் ⇄ மலைக்கோவில்' : 'Adivaram ⇄ Hilltop',
        requiresAuth: true,
        onTap: () => onNavigateBookingSubPage?.call(0),
      ),
      // 2. Darshan Booking
      _QuickLinkData(
        icon: Icons.temple_hindu_rounded,
        color: const Color(0xFFEA580C),
        title: isTamil ? 'தரிசன முன்பதிவு' : 'Darshan Booking',
        subtitle: isTamil ? 'இலவச & சிறப்பு தரிசனம்' : 'Free & Special passes',
        requiresAuth: true,
        onTap: () => onNavigateBookingSubPage?.call(1),
      ),
      // 3. Parking & Facilities
      _QuickLinkData(
        icon: Icons.local_parking_rounded,
        color: const Color(0xFF0288D1),
        title: isTamil ? 'வாகனம் & வழிகாட்டி' : 'Parking & Facilities',
        subtitle: isTamil ? 'இடங்கள் & வரைபடம்' : 'Parking spots & gates',
        requiresAuth: false,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FacilityLocatorScreen(
              onToggleLocale: onToggleLocale ?? () {},
            ),
          ),
        ),
      ),
      // 4. Senior Wheelchair Help
      _QuickLinkData(
        icon: Icons.accessible_forward,
        color: const Color(0xFF7C3AED),
        title: isTamil ? 'சக்கர நாற்காலி' : 'Wheelchair Help',
        subtitle: isTamil ? 'முதியோர் இலவச உதவி' : 'Free senior assistance',
        requiresAuth: false,
        onTap: () => _showWheelchairDialog(context),
      ),
      // 5. Free Annadhanam
      _QuickLinkData(
        icon: Icons.restaurant,
        color: const Color(0xFF16A34A),
        title: isTamil ? 'இலவச அன்னதானம்' : 'Free Annadhanam',
        subtitle: isTamil ? 'மதியம் 11:30 - 3:00 வரை' : 'Daily 11:30 AM - 3:00 PM',
        requiresAuth: false,
        onTap: () => _showAnnadhanamDialog(context),
      ),
      // 6. Pooja & Seva
      _QuickLinkData(
        icon: Icons.spa,
        color: const Color(0xFFB45309),
        title: isTamil ? 'சிறப்பு பூஜை' : 'Pooja & Seva',
        subtitle: isTamil ? 'அர்ச்சனை & அபிஷேகம்' : 'Archana bookings',
        requiresAuth: false,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServicesScreen(
              onToggleLocale: onToggleLocale ?? () {},
            ),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTamil ? 'விரைவு செயல்கள்' : 'Quick Actions',
              style: TextStyle(
                fontSize: isElderly ? 18 : 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            Text(
              isTamil ? 'நேரடி பொத்தான்கள்' : 'Immediate Shortcuts',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.deepSaffron,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ACCESSIBILITY-FIRST RESPONSIVE CARDS:
        // When large text: Full-width stacked cards (never overflows)
        // When normal text: Flexible 2-column layout that naturally expands vertically
        if (isLarge) ...[
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildAdaptiveCard(context, item, isFullWidth: true),
            ),
        ] else ...[
          for (int i = 0; i < items.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAdaptiveCard(context, items[i],
                        isFullWidth: false),
                  ),
                  const SizedBox(width: 10),
                  if (i + 1 < items.length)
                    Expanded(
                      child: _buildAdaptiveCard(context, items[i + 1],
                          isFullWidth: false),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAdaptiveCard(BuildContext context, _QuickLinkData item,
      {required bool isFullWidth}) {
    final bool isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    Widget card = BouncingScaleTap(
      onTap: item.onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: (isElderly || isTamil) ? 72 : 60,
        ),
        padding: EdgeInsets.symmetric(
            horizontal: 12, vertical: (isElderly || isTamil) ? 12 : 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (isElderly || isTamil)
                ? item.color.withValues(alpha: 0.35)
                : AppTheme.borderColor(context),
            width: isElderly ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: (isElderly || isTamil) ? 46 : 40,
              height: (isElderly || isTamil) ? 46 : 40,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon,
                  color: item.color, size: (isElderly || isTamil) ? 26 : 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: (isElderly || isTamil) ? 14.5 : 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context),
                      height: 1.25,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: (isElderly || isTamil) ? 12 : 10.5,
                      color: AppTheme.textSecondaryOf(context),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            if (isFullWidth)
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );

    if (item.requiresAuth) {
      return AuthGuardedWrapper(
        featureName: item.title,
        onToggleLocale: onToggleLocale,
        child: card,
      );
    }
    return card;
  }

  void _showAnnadhanamDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: Color(0xFF16A34A), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil
                            ? 'ஸ்ரீ அன்னதான கூடம்'
                            : 'Sri Annadhanam Dining Hall',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        isTamil
                            ? 'அனைத்து பக்தர்களுக்கும் இலவச பிரசாதம்'
                            : 'Free Divine Prasadam for all pilgrims',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoTile(
                Icons.schedule,
                isTamil ? 'நேரம்' : 'Timing',
                isTamil
                    ? 'தினசரி மதியம் 11:30 AM முதல் 3:00 PM வரை'
                    : 'Daily 11:30 AM to 3:00 PM'),
            _infoTile(
                Icons.location_on,
                isTamil ? 'இடம்' : 'Location',
                isTamil
                    ? 'தெற்கு கோபுர வாசல் அருகில் (South Tower)'
                    : 'Near South Tower entrance & Hall 2'),
            _infoTile(
                Icons.elderly,
                isTamil ? 'முதியோர் வசதி' : 'Senior Amenities',
                isTamil
                    ? 'முதியோர்களுக்கு தனி அமரும் நாற்காலி வசதி உண்டு'
                    : 'Dedicated chair seating for seniors'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isTamil ? 'புரிந்தது • நன்று' : 'Understood • Close',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWheelchairDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.accessible_forward,
                      color: Color(0xFF7C3AED), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil
                            ? 'முதியோர் & மாற்றுத்திறனாளி உதவி'
                            : 'Senior Wheelchair & Support',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        isTamil
                            ? 'தன்னார்வலர் இலவச சேவை'
                            : 'Complimentary Volunteer Support',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoTile(
                Icons.pin_drop,
                isTamil ? 'உதவி மையங்கள்' : 'Pickup Counters',
                isTamil
                    ? 'வாசல் 1 (கிழக்கு கோபுரம்) & வாசல் 4 (பேருந்து நிலையம்)'
                    : 'Gate 1 (East Gate) & Gate 4 (Bus Stand)'),
            _infoTile(
                Icons.phone_in_talk,
                isTamil ? 'நேரடி உதவி எண்' : 'Direct Helpline',
                '1800-425-0101 (கட்டணமில்லா சேவை / Toll Free)'),
            _infoTile(
                Icons.ramp_right,
                isTamil ? 'தரிசன சாய்தள பாதை' : 'Access Ramp',
                isTamil
                    ? 'நேரடி சாய்தள பாதை மூலம் கருவறை தரிசனம்'
                    : 'Step-free ramp access directly to Sanctum'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isTamil ? 'சரி • நன்றி' : 'Got it • Thank You',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool requiresAuth;
  final VoidCallback onTap;

  const _QuickLinkData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.requiresAuth,
    required this.onTap,
  });
}

// ── 7. Upcoming Festivals / Events ─────────────────────────────────────────────

class _UpcomingEventsSection extends StatelessWidget {
  final bool isTamil;
  final bool isElderly;
  final void Function(int index)? onNavigateTab;

  const _UpcomingEventsSection({
    required this.isTamil,
    required this.isElderly,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final festivals =
        Provider.of<MockFestivalRepository>(context).getUpcomingFestivals(limit: 3);

    if (festivals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTamil ? 'வரும் திருவிழாக்கள்' : 'Upcoming Festivals',
              style: TextStyle(
                fontSize: isElderly ? 18 : 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            TextButton(
              onPressed: () => onNavigateTab?.call(2),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
              child: Text(
                isTamil ? 'அனைத்தும் ➔' : 'View All ➔',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepSaffron,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...festivals.map((f) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final target = DateTime.tryParse(f.date);
          int? diff;
          if (target != null) {
            final targetDay = DateTime(target.year, target.month, target.day);
            diff = targetDay.difference(today).inDays;
          }
          String countdown = '';
          if (diff != null) {
            if (diff == 0) {
              countdown = isTamil ? '🎉 இன்று!' : '🎉 Today!';
            } else if (diff == 1) {
              countdown = isTamil ? 'நாளை' : 'Tomorrow';
            } else if (diff > 1) {
              countdown = isTamil ? '$diff நாட்களில்' : 'In $diff days';
            }
          }

          final isDark = AppTheme.isDark(context);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor(context)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: isElderly ? 52 : 46,
                  height: isElderly ? 52 : 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? const [Color(0xFF1F1206), Color(0xFF331E09)]
                          : const [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF6B3A08) : const Color(0xFFFDBA74),
                    ),
                  ),
                  child: const Center(
                    child: Text('🛕', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? f.tamilName : f.name,
                        style: TextStyle(
                          fontSize: (isElderly || isTamil) ? 15.5 : 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryOf(context),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.event,
                              size: 14, color: AppTheme.textSecondaryOf(context)),
                          const SizedBox(width: 4),
                          Text(
                            f.date,
                            style: TextStyle(
                              fontSize: isElderly ? 12 : 11.5,
                              color: AppTheme.textSecondaryOf(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (countdown.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      countdown,
                      style: TextStyle(
                        fontSize: isElderly ? 12 : 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEA580C),
                      ),
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

// ── Live Temple Broadcast Banner (Streamed via Firebase) ─────────────────────

class _LiveAdminBroadcastBanner extends StatelessWidget {
  final bool isTamil;

  const _LiveAdminBroadcastBanner({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: FirebaseService.instance.streamActiveBroadcast(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        final isActive = data['isActive'] as bool? ?? false;
        final message = (data['message'] as String?) ?? '';
        final messageTa = (data['messageTa'] as String?) ?? message;

        if (!isActive || message.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final displayMessage = isTamil && messageTa.isNotEmpty ? messageTa : message;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isTamil ? 'கோயில் நேரலை அறிவிப்பு' : 'TEMPLE LIVE BROADCAST',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isTamil ? 'நேரலை' : 'LIVE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

