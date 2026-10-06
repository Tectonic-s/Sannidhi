import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/firebase_service.dart';
import '../../../data/models/festival_model.dart';
import '../../../data/repositories/mock_crowd_repository.dart';
import '../../../data/repositories/mock_festival_repository.dart';
import '../../../data/repositories/mock_shuttle_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bulletin_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onToggleLocale;

  const AdminDashboardScreen({
    super.key,
    this.onToggleLocale,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = true;

  // Live Metrics state
  Map<String, dynamic>? _backendMetrics;
  List<dynamic> _recentBookings = [];

  // Emergency Alert Broadcast
  bool _emergencyAlertActive = false;
  String _activeAlertMessage = 'Normal Operations: Queue moving smoothly';
  StreamSubscription<Map<String, dynamic>>? _broadcastSub;

  @override
  void initState() {
    super.initState();
    _fetchLiveMetrics();
    _startAutoRefresh();
    _listenToCloudBroadcast();
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _listenToCloudBroadcast() {
    _broadcastSub = FirebaseService.instance.streamActiveBroadcast().listen((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          _emergencyAlertActive = data['isActive'] as bool? ?? false;
          final msg = (data['message'] as String?) ?? '';
          if (msg.isNotEmpty) {
            _activeAlertMessage = msg;
          }
        });
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (_autoRefreshEnabled) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (mounted && _autoRefreshEnabled) {
          _fetchLiveMetrics(isBackground: true);
        }
      });
    }
  }

  Future<void> _fetchLiveMetrics({bool isBackground = false}) async {
    final auth = context.read<AuthProvider>();

    try {
      final response = await http.get(
        Uri.parse('${AuthProvider.backendUrl}/api/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          if (auth.token.isNotEmpty) 'Authorization': 'Bearer ${auth.token}',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _backendMetrics = body['metrics'] as Map<String, dynamic>?;
            _recentBookings = body['recent_bookings'] as List<dynamic>? ?? [];
          });
        }
      }
    } catch (_) {
      // Offline fallback: Use simulated live data based on app activity
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });
    _startAutoRefresh();
  }

  void _confirmLogout(BuildContext context, bool isTamil) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isTamil ? 'வெளியேறவா?' : 'Sign Out / Switch User?'),
        content: Text(
          isTamil
              ? 'நிர்வாக பயன்முறையிலிருந்து வெளியேறி பக்தர் முறைக்குத் திரும்ப விரும்புகிறீர்களா?'
              : 'Do you want to sign out from Temple Admin mode and return to Devotee view?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(onToggleLocale: widget.onToggleLocale),
                ),
              );
            },
            child: Text(isTamil ? 'வெளியேறு' : 'Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, bool isTamil) {
    final controller = TextEditingController(text: _activeAlertMessage);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isTamil ? 'அவசர அறிவிப்பு மையம்' : 'Temple Broadcast Announcement',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTamil
                    ? 'பக்தர்களுக்கு அனுப்ப வேண்டிய அவசர செய்தி அல்லது வரிசை நிலையை உள்ளிடவும்:'
                    : 'Broadcast a live announcement or queue advisory to all devotee apps:',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryOf(context)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isTamil ? 'செய்தி...' : 'Enter advisory message...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          if (_emergencyAlertActive)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
              ),
              icon: const Icon(Icons.clear_rounded, size: 16),
              onPressed: () async {
                setState(() {
                  _emergencyAlertActive = false;
                  _activeAlertMessage = 'Normal Operations';
                });
                await FirebaseService.instance.publishBroadcast(
                  message: '',
                  isActive: false,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              label: Text(isTamil ? 'அறிவிப்பை நீக்கு' : 'Clear Alert'),
            ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _emergencyAlertActive = true;
                  _activeAlertMessage = text;
                });
                await FirebaseService.instance.publishBroadcast(
                  message: text,
                  isActive: true,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            label: Text(isTamil ? 'ஒளிபரப்பு செய்' : 'Broadcast Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final crowd = context.watch<MockCrowdRepository>();
    final shuttle = context.watch<MockShuttleRepository>();
    final activity = context.watch<UserActivityProvider>();
    final festivalRepo = context.watch<MockFestivalRepository>();
    final bulletin = context.watch<BulletinProvider>();

    // Dynamic metrics calculated from database / repositories
    final totalTickets = _backendMetrics?['total_tickets'] ?? 1340;
    final activeTickets = _backendMetrics?['active_tickets'] ?? 412;
    final usedTickets = _backendMetrics?['used_tickets'] ?? 916;
    final totalRevenue = (_backendMetrics?['total_revenue'] as num?)?.toDouble() ?? 148500.0;
    final totalDonations = (_backendMetrics?['total_donations'] as num?)?.toDouble() ?? 84200.0;

    final crowdData = crowd.getCrowdData();
    final insideCount = crowdData.currentVisitors > 0 ? crowdData.currentVisitors : 1420;
    const maxCapacity = 3000;
    final occupancyPercent = (insideCount / maxCapacity).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F12) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF18181B) : AppTheme.primaryColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTamil ? 'கோயில் நிர்வாக மையம்' : 'Temple Executive Center',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              isTamil ? 'மருதமலை முருகன் தேவஸ்தானம் • நேரலை' : 'Marudamalai Murugan Devasthanam • Live',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        actions: [
          // Auto-refresh pulse toggle
          IconButton(
            icon: Icon(
              _autoRefreshEnabled ? Icons.sync : Icons.sync_disabled,
              color: _autoRefreshEnabled ? const Color(0xFF86EFAC) : Colors.white70,
              size: 20,
            ),
            tooltip: _autoRefreshEnabled ? 'Live Stream Active (12s)' : 'Live Stream Paused',
            onPressed: _toggleAutoRefresh,
          ),
          // Language toggle
          TextButton.icon(
            onPressed: widget.onToggleLocale,
            icon: const Icon(Icons.language, color: Colors.white, size: 18),
            label: Text(
              isTamil ? 'ENG' : 'தமிழ்',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          // Sign Out / Switch Role
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: isTamil ? 'பயனர் மாற்றம்' : 'Switch Role / Logout',
            onPressed: () => _confirmLogout(context, isTamil),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchLiveMetrics(isBackground: false),
          color: AppTheme.primaryColor,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Top Operational Status Ribbon
              _buildOperationalRibbon(isTamil, insideCount, occupancyPercent),
              const SizedBox(height: 14),

              // Emergency / Public Announcement Banner
              if (_emergencyAlertActive)
                _buildEmergencyBanner(isTamil)
              else
                _buildAnnouncementShortcut(isTamil),

              const SizedBox(height: 16),

              // ── Live Bulletins Management (2 Core + Admin Custom) ────────
              _buildSectionHeader(
                isTamil ? 'நேரலைச் செய்தி & தகவல் பலகை மேலாண்மை' : 'Live Bulletins & Ticker Management',
                Icons.view_carousel_rounded,
              ),
              const SizedBox(height: 10),
              _buildLiveBulletinsManagementCard(isTamil, bulletin),
              const SizedBox(height: 16),

              // ── 1. Live Crowd & Queue Occupancy ─────────────────────────
              _buildSectionHeader(
                isTamil ? 'நேரடி கூட்ட நெரிசல் மற்றும் மண்டப நிலவரம்' : 'Live Crowd Telemetry & Zones',
                Icons.people_alt,
              ),
              const SizedBox(height: 10),
              _buildCrowdTelemetryCard(isTamil, crowdData.estimatedWaitMinutes, insideCount, maxCapacity, occupancyPercent, crowd),
              const SizedBox(height: 16),

              // ── 2. Pass & Ticket Validation Flow ─────────────────────────
              _buildSectionHeader(
                isTamil ? 'டிக்கெட் சரிபார்ப்பு மற்றும் நுழைவு புள்ளிவிவரங்கள்' : 'Darshan Passes & Gate Flow',
                Icons.confirmation_num,
              ),
              const SizedBox(height: 10),
              _buildTicketFlowCard(isTamil, totalTickets, activeTickets, usedTickets),
              const SizedBox(height: 16),

              // ── 3. Revenue & Hundi Collections ──────────────────────────
              _buildSectionHeader(
                isTamil ? 'வருவாய் மற்றும் உண்டியல் நிதி மேலாண்மை' : 'Revenue & Temple Collections',
                Icons.account_balance_wallet,
              ),
              const SizedBox(height: 10),
              _buildRevenueCard(isTamil, totalRevenue, totalDonations),
              const SizedBox(height: 16),

              // ── 4. Hill Transit & Shuttle Operations ────────────────────
              _buildSectionHeader(
                isTamil ? 'மலைப்பாதை போக்குவரத்து மற்றும் மின்-பேருந்துகள்' : 'Hill Transit & Shuttle Operations',
                Icons.directions_bus,
              ),
              const SizedBox(height: 10),
              _buildTransitCard(isTamil, shuttle),
              const SizedBox(height: 16),

              // ── 5. Gate Health & Operators ──────────────────────────────
              _buildSectionHeader(
                isTamil ? 'வாயில் ஆபரேட்டர்கள் மற்றும் நுழைவு வாயில்கள்' : 'Gate Operators & Checkpoints',
                Icons.door_front_door,
              ),
              const SizedBox(height: 10),
              _buildGateStatusCard(isTamil, usedTickets),
              const SizedBox(height: 16),

              // ── 6. Live Devotee Bookings Feed ───────────────────────────
              _buildSectionHeader(
                isTamil ? 'சமீபத்திய முன்பதிவு பதிவு (நேரலை)' : 'Recent Devotee Bookings Feed',
                Icons.receipt_long,
              ),
              const SizedBox(height: 10),
              _buildRecentBookingsList(isTamil, activity),
              const SizedBox(height: 16),

              // ── 7. Temple Festival Schedule & Date Control ─────────────────
              _buildSectionHeader(
                isTamil ? 'திருவிழா காலண்டர் மற்றும் தேதி கட்டுப்பாடு' : 'Temple Festival Schedule & Date Control',
                Icons.celebration_rounded,
              ),
              const SizedBox(height: 10),
              _buildFestivalManagementCard(isTamil, festivalRepo),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Operational Status Ribbon ──────────────────────────────────────────────
  Widget _buildOperationalRibbon(bool isTamil, int insideCount, double percent) {
    Color badgeColor;
    String statusText;

    if (percent < 0.5) {
      badgeColor = const Color(0xFF10B981);
      statusText = isTamil ? 'வழக்கமான நெரிசல்' : 'Normal Flow';
    } else if (percent < 0.8) {
      badgeColor = const Color(0xFFF59E0B);
      statusText = isTamil ? 'மிதமான நெரிசல்' : 'Moderate Rush';
    } else {
      badgeColor = const Color(0xFFEF4444);
      statusText = isTamil ? 'அதிக கூட்ட நெரிசல்' : 'Peak Rush Alert';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          Text(
            isTamil ? 'உள்ளே: $insideCount பக்தர்கள்' : 'Inside: $insideCount Devotees',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          Row(
            children: [
              Icon(
                _autoRefreshEnabled ? Icons.bolt : Icons.pause_circle_outline,
                size: 14,
                color: _autoRefreshEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Text(
                _autoRefreshEnabled ? (isTamil ? 'நேரலை' : 'Live (12s)') : 'Paused',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _autoRefreshEnabled ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Announcement Banner ───────────────────────────────────────────────────
  Widget _buildEmergencyBanner(bool isTamil) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${isTamil ? "செயலில் உள்ள அறிவிப்பு:" : "Active Alert:"} $_activeAlertMessage',
              style: TextStyle(
                color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFFDC2626)),
            onPressed: () => _showBroadcastDialog(context, isTamil),
            tooltip: 'Edit Announcement',
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementShortcut(bool isTamil) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: () => _showBroadcastDialog(context, isTamil),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppTheme.borderColor(context) : const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFF2563EB), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isTamil
                    ? 'பக்தர்களுக்கு புதிய அவசர அறிவிப்பை ஒளிபரப்பு செய்'
                    : 'Broadcast public advisory or queue status to devotee apps',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  // ── Live Bulletins Management (2 Core + Admin Custom) ─────────────────────
  Widget _buildLiveBulletinsManagementCard(bool isTamil, BulletinProvider bulletin) {
    final isDark = AppTheme.isDark(context);
    final coreCount = bulletin.coreBulletins.length;
    final customCount = bulletin.customBulletins.length;
    final totalCount = bulletin.items.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with count and "+ Add Bulletin" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil ? 'செயலில் உள்ள நேரலைச் செய்திகள்' : 'Active Live Bulletins',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTamil
                          ? '$totalCount செய்திகள் ($coreCount அடிப்படை + $customCount நிர்வாகம்)'
                          : '$totalCount bulletins ($coreCount Core + $customCount Custom)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isTamil ? '+ புதிய செய்தி' : '+ Add Bulletin',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _showAddBulletinDialog(context, isTamil, bulletin),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bulletins List
          ...bulletin.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.isCustom
                      ? item.accentColor.withValues(alpha: 0.4)
                      : (isDark ? AppTheme.borderColor(context) : const Color(0xFFE2E8F0)),
                  width: item.isCustom ? 1.2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.accentColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isTamil ? item.categoryTa : item.categoryEn,
                                style: TextStyle(
                                  color: item.accentColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: item.isCustom
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isCustom
                                    ? (isTamil ? 'நிர்வாகம் சேர்த்தது' : 'Custom Admin')
                                    : (isTamil ? 'அடிப்படை விதி' : 'Core Rule'),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.isCustom
                                      ? const Color(0xFF2563EB)
                                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isTamil ? item.textTa : item.textEn,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryOf(context),
                            height: 1.3,
                          ),
                        ),
                        if (isTamil && item.textEn != item.textTa) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.textEn,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryOf(context),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (item.isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                      tooltip: isTamil ? 'நீக்கு' : 'Delete Bulletin',
                      onPressed: () => _confirmDeleteBulletin(context, isTamil, bulletin, item),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmDeleteBulletin(
    BuildContext context,
    bool isTamil,
    BulletinProvider bulletin,
    BulletinItem item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTamil ? 'செய்தியை நீக்கவா?' : 'Delete Bulletin?'),
        content: Text(
          isTamil
              ? 'இந்த நேரலை செய்தி பக்தர் முகப்புப் பக்கத்தின் சுழற்சியிலிருந்து நீக்கப்படும்.'
              : 'This live bulletin will be removed from the devotee rotating feed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await bulletin.removeBulletin(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTamil ? 'நேரலைச் செய்தி நீக்கப்பட்டது' : 'Live bulletin deleted'),
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                );
              }
            },
            child: Text(isTamil ? 'நீக்கு' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddBulletinDialog(
    BuildContext context,
    bool isTamil,
    BulletinProvider bulletin,
  ) {
    final catEnController = TextEditingController(text: 'SPECIAL ADVISORY');
    final catTaController = TextEditingController(text: 'சிறப்பு அறிவிப்பு');
    final textEnController = TextEditingController();
    final textTaController = TextEditingController();

    IconData selectedIcon = Icons.campaign_rounded;
    Color selectedColor = const Color(0xFFD97706);

    final availableIcons = <({IconData icon, String label})>[
      (icon: Icons.campaign_rounded, label: 'Notice'),
      (icon: Icons.two_wheeler_rounded, label: 'Vehicle'),
      (icon: Icons.auto_stories_rounded, label: 'Pooja'),
      (icon: Icons.restaurant_rounded, label: 'Food'),
      (icon: Icons.warning_rounded, label: 'Safety'),
      (icon: Icons.directions_bus_rounded, label: 'Shuttle'),
      (icon: Icons.water_drop_rounded, label: 'Water'),
      (icon: Icons.info_rounded, label: 'Info'),
    ];

    final availableColors = [
      const Color(0xFFD97706), // Amber
      const Color(0xFFDC2626), // Red
      const Color(0xFF2563EB), // Blue
      const Color(0xFF16A34A), // Green
      const Color(0xFF9333EA), // Purple
      const Color(0xFFEA580C), // Orange
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTamil ? 'புதிய நேரலைச் செய்தி சேர்க்க' : 'Add Live Temple Bulletin',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil
                      ? 'பக்தர்களின் முகப்புப் பக்கத்தில் சுழலும் நேரலை பலகையில் சேர்க்கப்படும்:'
                      : 'This bulletin will immediately rotate on the Devotee Home Screen carousel:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                ),
                const SizedBox(height: 12),

                // Category English & Tamil
                TextField(
                  controller: catEnController,
                  decoration: InputDecoration(
                    labelText: isTamil ? 'பிரிவு (ஆங்கிலம்)' : 'Category / Tag (English)',
                    hintText: 'e.g. DARSHAN UPDATE',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: catTaController,
                  decoration: InputDecoration(
                    labelText: isTamil ? 'பிரிவு (தமிழ்)' : 'Category (Tamil - optional)',
                    hintText: 'எ.கா: தரிசன தகவல்',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Message Text English
                TextField(
                  controller: textEnController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isTamil ? 'செய்தி (ஆங்கிலம்)' : 'Bulletin Text (English)',
                    hintText: 'e.g. Devotees carrying offerings may use North gate counter 2.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),

                // Message Text Tamil
                TextField(
                  controller: textTaController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isTamil ? 'செய்தி (தமிழ்)' : 'Bulletin Text (Tamil - optional)',
                    hintText: 'தமிழ் மொழிபெயர்ப்பு (விருப்பப்பட்டால்)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                // Icon selection
                Text(
                  isTamil ? 'சின்னம் தேர்வு:' : 'Choose Icon:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: availableIcons.map((i) {
                    final isSel = selectedIcon == i.icon;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIcon = i.icon),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.primaryColor : (isDark ? const Color(0xFF27272A) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          i.icon,
                          size: 18,
                          color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Color selection
                Text(
                  isTamil ? 'வண்ணம் தேர்வு:' : 'Choose Color:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: availableColors.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2.5) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTamil ? 'ரத்து' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final textEn = textEnController.text.trim();
                if (textEn.isEmpty) return;
                final catEn = catEnController.text.trim().isEmpty ? 'ADVISORY' : catEnController.text.trim();
                final catTa = catTaController.text.trim().isEmpty ? catEn : catTaController.text.trim();
                final textTa = textTaController.text.trim().isEmpty ? textEn : textTaController.text.trim();

                await bulletin.addBulletin(
                  categoryEn: catEn,
                  categoryTa: catTa,
                  textEn: textEn,
                  textTa: textTa,
                  icon: selectedIcon,
                  accentColor: selectedColor,
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTamil
                            ? 'நேரலைச் செய்தி வெற்றிகரமாக சேர்க்கப்பட்டது!'
                            : 'Live bulletin published to Devotee Home Screen!',
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              child: Text(isTamil ? 'சேர்' : 'Publish Bulletin'),
            ),
          ],
        );
        },
      ),
    );
  }

  // ── 1. Live Crowd & Queue Occupancy ───────────────────────────────────────
  Widget _buildCrowdTelemetryCard(
    bool isTamil,
    int waitMinutes,
    int insideCount,
    int maxCapacity,
    double percent,
    MockCrowdRepository crowd,
  ) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTamil ? 'கோயில் வளாக கொள்ளளவு' : 'Temple Safe Capacity',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$insideCount / $maxCapacity',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedBg(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(1)}% Full',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: AppTheme.borderColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 0.8
                    ? const Color(0xFFEF4444)
                    : (percent > 0.5 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dual-source deduplication chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14532D).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF15803D).withValues(alpha: 0.5) : const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTamil
                        ? 'இரட்டைப் பதிவு தடுப்பு: GPS ஜியோபென்ஸ் + கேட் பாஸ்கள் ஒத்திசைவு (${crowd.overlapDeduplicatedCount > 0 ? crowd.overlapDeduplicatedCount : 284} சரிபார்ப்பு, நகல் தவிர்ப்பு)'
                        : 'Dual-Source Deduplication: GPS Geofence + Gate Passes synchronized (${crowd.overlapDeduplicatedCount > 0 ? crowd.overlapDeduplicatedCount : 284} reconciled, no double counting)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Wait Times
          Row(
            children: [
              Expanded(
                child: _waitBox(
                  label: isTamil ? 'பொது தரிசனம்' : 'General Queue',
                  wait: '$waitMinutes mins',
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _waitBox(
                  label: isTamil ? 'சிறப்பு தரிசனம்' : 'Special Entry',
                  wait: '${(waitMinutes / 3).round().clamp(5, 30)} mins',
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _waitBox(
                  label: isTamil ? 'மூத்த குடிமக்கள்' : 'Senior / Elderly',
                  wait: '5 mins',
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zone Breakdown
          Text(
            isTamil ? 'மண்டல வாரியாக நெரிசல் விகிதம்:' : 'Zone Density Breakdown:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          _zoneRow('Sanctum Sanctorum (Garbhagriha)', 0.78, '390 / 500', const Color(0xFFEF4444)),
          _zoneRow('Maha Mandapam & Queue Hall', 0.62, '620 / 1000', const Color(0xFFF59E0B)),
          _zoneRow('Outer Prakaram (Circumambulation)', 0.35, '350 / 1000', const Color(0xFF10B981)),
          _zoneRow('Foothill Shuttle Boarding Terminal', 0.12, '60 / 500', const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _waitBox({required String label, required String wait, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            wait,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _zoneRow(String name, double factor, String counts, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textPrimaryOf(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                counts,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: factor,
              minHeight: 5,
              backgroundColor: AppTheme.borderColor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Pass & Ticket Validation Flow ──────────────────────────────────────
  Widget _buildTicketFlowCard(bool isTamil, int total, int active, int used) {
    return Row(
      children: [
        Expanded(
          child: _metricBox(
            title: isTamil ? 'மொத்த பாஸ்கள்' : 'Total Issued',
            count: '$total',
            icon: Icons.confirmation_num,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricBox(
            title: isTamil ? 'செயலில் உள்ளவை' : 'Active (Pending)',
            count: '$active',
            icon: Icons.hourglass_top,
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricBox(
            title: isTamil ? 'அனுமதிக்கப்பட்டவை' : 'Scanned (Used)',
            count: '$used',
            icon: Icons.check_circle,
            color: const Color(0xFF059669),
          ),
        ),
      ],
    );
  }

  Widget _metricBox({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Revenue & Collections ──────────────────────────────────────────────
  Widget _buildRevenueCard(bool isTamil, double revenue, double donations) {
    final total = revenue + donations;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTamil ? 'மொத்த தினசரி நிதி வசூல்' : 'Total Daily Collections',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      isTamil ? '+14% இன்று' : '+14% Today',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _revenueItem(
                  label: isTamil ? 'தரிசன டிக்கெட்டுகள்' : 'Darshan & Sevas',
                  amount: '₹${revenue.toStringAsFixed(0)}',
                  color: const Color(0xFF0D9488),
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _revenueItem(
                  label: isTamil ? 'உண்டியல் & நன்கொடைகள்' : 'E-Hundi & Donations',
                  amount: '₹${donations.toStringAsFixed(0)}',
                  color: const Color(0xFFE11D48),
                  icon: Icons.volunteer_activism_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueItem({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryOf(context)),
                ),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Transit & Shuttle Operations ───────────────────────────────────────
  Widget _buildTransitCard(bool isTamil, MockShuttleRepository shuttle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.electric_bolt, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isTamil ? 'செயலில் உள்ள மின்-பேருந்துகள்' : 'Electric Shuttle Fleet',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '4 Active Buses',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _transitItem(
                  label: isTamil ? 'பயணிகள் இன்று' : 'Passengers Ferried',
                  value: '1,120',
                  icon: Icons.airline_seat_recline_normal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _transitItem(
                  label: isTamil ? 'சராசரி காத்திருப்பு' : 'Average Wait Time',
                  value: '6 mins',
                  icon: Icons.timer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _transitItem(
                  label: isTamil ? 'மலைப்பாதை நிலை' : 'Ghat Road Status',
                  value: 'Clear',
                  icon: Icons.traffic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _transitItem({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.elevatedBg(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0284C7)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context)),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }

  // ── 5. Gate Health & Operators ────────────────────────────────────────────
  Widget _buildGateStatusCard(bool isTamil, int usedCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          _gateRow('Gate 1 (East Gopuram)', 'Staff on duty: Active', (usedCount * 0.55).round(), true),
          const Divider(height: 16),
          _gateRow('Gate 2 (South Raja Gopuram)', 'Staff on duty: Active', (usedCount * 0.30).round(), true),
          const Divider(height: 16),
          _gateRow('Gate 3 (Hilltop Shuttle Terminal)', 'Staff on duty: Active', (usedCount * 0.15).round(), true),
        ],
      ),
    );
  }

  Widget _gateRow(String name, String staff, int count, bool active) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)),
              ),
              Text(
                staff,
                style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryOf(context)),
              ),
            ],
          ),
        ),
        Text(
          '$count scanned',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
        ),
      ],
    );
  }

  // ── 6. Live Recent Devotee Bookings Feed ──────────────────────────────────
  Widget _buildRecentBookingsList(bool isTamil, UserActivityProvider activity) {
    if (_recentBookings.isEmpty && activity.darshanBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Center(
          child: Text(
            isTamil ? 'முன்பதிவுகள் ஏதுமில்லை' : 'No recent bookings in database',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ),
      );
    }

    // Display list from backend or local activity
    final items = _recentBookings.isNotEmpty
        ? _recentBookings
        : activity.darshanBookings.map((b) => {
              'id': b.bookingId,
              'devotee_name': 'Devotee',
              'type': 'DARSHAN',
              'slot_time': b.slotTime,
              'tickets_count': b.ticketCount,
              'status': 'ACTIVE',
              'date': b.date,
            }).toList();

    return Column(
      children: items.take(6).map((b) {
        final status = b['status'] as String? ?? 'ACTIVE';
        final isUsed = status == 'USED';
        final statusColor = isUsed ? const Color(0xFF059669) : const Color(0xFFD97706);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUsed ? Icons.check_circle : Icons.qr_code,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${b['devotee_name'] ?? "Devotee"} • ${b['type'] ?? "DARSHAN"}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context)),
                    ),
                    Text(
                      '${b['id']} • Slot: ${b['slot_time'] ?? "Today"}',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Helper: Section Header ─────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryOf(context),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── 7. Festival Management Card ──────────────────────────────────────────
  Widget _buildFestivalManagementCard(bool isTamil, MockFestivalRepository repo) {
    final isDark = AppTheme.isDark(context);
    final festivals = repo.festivals;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Sync and Add Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil ? 'கோயில் உற்சவங்கள் அட்டவணை' : 'Master Festival Calendar',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      isTamil
                          ? '${festivals.length} திருவிழாக்கள் • தேதி மாற்ற "மாற்று" அழுத்தவும்'
                          : '${festivals.length} events • Tap Edit to update dates',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              // API Sync Button
              IconButton(
                icon: repo.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded, color: AppTheme.primaryColor),
                tooltip: isTamil ? 'API இலிருந்து புதுப்பி' : 'Sync from Backend API',
                onPressed: repo.isLoading
                    ? null
                    : () async {
                        final ok = await repo.fetchFestivalsFromApi();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? (isTamil
                                      ? 'திருவிழா தேதிகள் வெற்றிகரமாக ஒத்திசைக்கப்பட்டன!'
                                      : 'Festivals synchronized with server!')
                                  : (isTamil
                                      ? 'ஆஃப்லைன் பயன்முறை: உள்ளூர் சேமிப்பகம் செயலில் உள்ளது'
                                      : 'Offline mode: Cached festival dates loaded')),
                              backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
              ),
              // Add Custom Festival Button
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
                tooltip: isTamil ? 'புதிய திருவிழா சேர்' : 'Add Special Festival',
                onPressed: () => _showAddFestivalDialog(context, isTamil, repo),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Festival List
          ...festivals.map((festival) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isTamil ? festival.tamilName : festival.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryOf(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (festival.isSpecial) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isTamil ? 'சிறப்பு' : 'Special',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event, size: 13, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              festival.date,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit Date Action
                  InkWell(
                    onTap: () => _showEditFestivalDialog(context, festival, isTamil, repo),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.4 : 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            isTamil ? 'மாற்று' : 'Edit Date',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showEditFestivalDialog(
    BuildContext context,
    FestivalModel festival,
    bool isTamil,
    MockFestivalRepository repo,
  ) {
    DateTime selectedDate = DateTime.tryParse(festival.date) ?? DateTime.now();
    final dateController = TextEditingController(text: festival.date);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTamil ? 'திருவிழா தேதி மாற்றம்' : 'Update Festival Date',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTamil ? festival.tamilName : festival.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTamil ? festival.tamilDescription : festival.description,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isTamil ? 'புதிய தேதி (YYYY-MM-DD):' : 'Select New Date (YYYY-MM-DD):',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: const Icon(Icons.event, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.calendar_today_rounded),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025, 1, 1),
                            lastDate: DateTime(2035, 12, 31),
                          );
                          if (picked != null) {
                            final formatted = '${picked.year.toString().padLeft(4, '0')}-'
                                '${picked.month.toString().padLeft(2, '0')}-'
                                '${picked.day.toString().padLeft(2, '0')}';
                            setDialogState(() {
                              selectedDate = picked;
                              dateController.text = formatted;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isTamil ? 'ரத்து' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final newDate = dateController.text.trim();
                  if (newDate.isEmpty) return;

                  final auth = context.read<AuthProvider>();
                  final ok = await repo.updateFestivalDate(
                    festival.id,
                    newDate,
                    token: auth.token,
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? (isTamil
                                ? 'தேதி வெற்றிகரமாக மாற்றப்பட்டது & சேமிக்கப்பட்டது!'
                                : 'Festival date updated and saved!')
                            : (isTamil
                                ? 'உள்ளூரில் புதுப்பிக்கப்பட்டது (சர்வர் ஆஃப்லைன்)'
                                : 'Updated locally (Offline cache active)')),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  }
                },
                child: Text(isTamil ? 'சேமி' : 'Save Date'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddFestivalDialog(
    BuildContext context,
    bool isTamil,
    MockFestivalRepository repo,
  ) {
    final nameController = TextEditingController();
    final tamilNameController = TextEditingController();
    final dateController = TextEditingController(
      text: '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              isTamil ? 'புதிய உற்சவம் சேர்' : 'Add Temple Event',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isTamil ? 'பெயர் (ஆங்கிலம்)' : 'Festival Name (English)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tamilNameController,
                decoration: InputDecoration(
                  labelText: isTamil ? 'பெயர் (தமிழ்)' : 'Festival Name (Tamil)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: isTamil ? 'தேதி (YYYY-MM-DD)' : 'Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isTamil ? 'விளக்கம்' : 'Description / Significance',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final auth = context.read<AuthProvider>();
              final newFest = FestivalModel(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                tamilName: tamilNameController.text.trim().isNotEmpty
                    ? tamilNameController.text.trim()
                    : name,
                date: dateController.text.trim(),
                description: descController.text.trim(),
                tamilDescription: descController.text.trim(),
                imageUrl: '',
                isSpecial: true,
                isTamilMonth: true,
              );

              await repo.createCustomFestival(newFest, token: auth.token);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTamil
                        ? 'புதிய உற்சவம் வெற்றிகரமாக சேர்க்கப்பட்டது!'
                        : 'New festival added successfully!'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              }
            },
            child: Text(isTamil ? 'சேர்' : 'Add Event'),
          ),
        ],
      ),
    );
  }
}

