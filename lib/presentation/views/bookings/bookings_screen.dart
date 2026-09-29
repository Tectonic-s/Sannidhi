import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/auth_required_dialog.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/services/cashfree_payment_service.dart';
import '../../../core/widgets/ticket_carousel_modal.dart';
import '../../../data/models/activity_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../payment/cashfree_payment_screen.dart';

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isSlotPast(String slot, [DateTime? selectedDate]) {
  final now = DateTime.now();
  if (selectedDate != null) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (target.isAfter(today)) return false;
    if (target.isBefore(today)) return true;
  }

  final parts = slot.split(' ');
  final timeParts = parts[0].split(':');
  var hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  final period = parts[1];

  if (period == 'AM' && hour == 12) hour = 0;
  if (period == 'PM' && hour != 12) hour += 12;

  final slotMinutes = hour * 60 + minute;
  final currentMinutes = now.hour * 60 + now.minute;
  return currentMinutes >= slotMinutes;
}

class BookingsScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  final int initialSubPage;
  final int initialTabIndex;

  const BookingsScreen({
    super.key,
    required this.onToggleLocale,
    this.initialSubPage = 0,
    this.initialTabIndex = 0,
  });

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void didUpdateWidget(covariant BookingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tab.animateTo(widget.initialTabIndex);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: widget.onToggleLocale),
      body: Column(
        children: [
          Container(
            color: AppTheme.primaryColor,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.accentColor,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        isTamil
                            ? 'டிக்கெட் முன்பதிவு'
                            : (l10n.translate('bookServices') ?? 'Book Passes'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        isTamil
                            ? 'என் பாஸ்கள் (செயலில்)'
                            : (l10n.translate('myPasses') ?? 'My Active Passes'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BookPassesTab(
                  onBooked: () => _tab.animateTo(1),
                  initialSubPage: widget.initialSubPage,
                ),
                const _MyPassesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Book Passes ────────────────────────────────────────────────────────

class _BookPassesTab extends StatefulWidget {
  final VoidCallback onBooked;
  final int initialSubPage;

  const _BookPassesTab({
    required this.onBooked,
    this.initialSubPage = 0,
  });

  @override
  State<_BookPassesTab> createState() => _BookPassesTabState();
}

class _BookPassesTabState extends State<_BookPassesTab> {
  Timer? _slotRefreshTimer;
  late int _selectedSubPage;
  late DateTime _selectedBookingDate;

  @override
  void initState() {
    super.initState();
    _selectedSubPage = widget.initialSubPage;
    final now = DateTime.now();
    _selectedBookingDate = DateTime(now.year, now.month, now.day);
    final firstAvailable = _slots.firstWhere(
      (slot) => !_isSlotPast(slot, _selectedBookingDate),
      orElse: () => _slots.last,
    );
    _shuttleSlot = firstAvailable;
    _darshanSlot = firstAvailable;
    _slotRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _BookPassesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSubPage != oldWidget.initialSubPage) {
      setState(() => _selectedSubPage = widget.initialSubPage);
    }
  }

  @override
  void dispose() {
    _slotRefreshTimer?.cancel();
    super.dispose();
  }

  static const _slots = [
    '06:00 AM', '07:00 AM', '08:00 AM', '08:30 AM',
    '09:00 AM', '09:30 AM', '10:00 AM', '11:00 AM',
    '04:00 PM', '05:00 PM', '06:00 PM', '07:00 PM',
  ];

  static const _darshanTypes = [
    _DarshanType('Normal Darshan', 0, Icons.people, AppColors.info,
        'General queue • Est. 45–90 min', ['Free entry', 'Temple prasadam']),
    _DarshanType('Special Darshan', 50, Icons.star_outline, AppColors.deepSaffron,
        'Priority queue • Est. 15–30 min', ['Priority entry', 'Prasadam + flower']),
    _DarshanType('VIP Darshan', 250, Icons.workspace_premium, AppColors.templeMaroon,
        'Direct access • Est. < 10 min', ['Direct entry', 'Abhishekam viewing', 'Prasadam + archana']),
  ];

  // Bus Shuttle state
  String _shuttleSlot = '09:00 AM';
  int _shuttleSeats = 1;

  // Darshan state
  String _darshanSlot = '09:00 AM';
  int _darshanIdx = 0;
  int _devotees = 1;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';

    final isDark = AppTheme.isDark(context);

    return Column(
      children: [
        // ── Sub-page Segmented Switcher ─────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedSubPage = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedSubPage == 0 ? AppColors.templeMaroon : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedSubPage == 0
                          ? [
                              BoxShadow(
                                color: AppColors.templeMaroon.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: 18,
                          color: _selectedSubPage == 0 ? Colors.white : AppTheme.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTamil ? 'பேருந்து முன்பதிவு' : 'Bus Booking',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _selectedSubPage == 0 ? Colors.white : AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedSubPage = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedSubPage == 1 ? AppColors.deepSaffron : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _selectedSubPage == 1
                          ? [
                              BoxShadow(
                                color: AppColors.deepSaffron.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.temple_hindu_rounded,
                          size: 18,
                          color: _selectedSubPage == 1 ? Colors.white : AppTheme.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTamil ? 'தரிசன முன்பதிவு' : 'Darshan Booking',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _selectedSubPage == 1 ? Colors.white : AppTheme.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Active Sub-Page Content ─────────────────────────────────────────
        Expanded(
          child: _selectedSubPage == 0
              ? _buildBusBookingPage(auth, isTamil)
              : _buildDarshanBookingPage(auth, isTamil),
        ),
      ],
    );
  }

  // ── Sub-Page 1: Bus Booking ───────────────────────────────────────────────
  Widget _buildBusBookingPage(AuthProvider auth, bool isTamil) {
    final fare = _shuttleSeats * 20;

    return ListView(
      key: const ValueKey('bus_booking_sub_page'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
      children: [
        if (!auth.isAuthenticated)
          AuthLockBanner(
            featureName: isTamil ? 'பேருந்து முன்பதிவு' : 'Bus Booking',
          ),

        // Route & Service Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7F1D1D).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'மின்கலப் பேருந்து சேவை' : 'Eco-Electric Temple Bus',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isTamil ? 'அடிவாரம் ⇄ மலைக்கோவில் சந்நிதி' : 'Adivaram Terminal ⇄ Hilltop Sannidhi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '₹20 / seat',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.templeMaroon,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _pillBadge(Icons.bolt, isTamil ? 'மின்சார வாகனம்' : '100% Electric'),
                  _pillBadge(Icons.schedule, isTamil ? '15 நிமிடங்களுக்கு ஒன்று' : 'Every 15 mins'),
                  _pillBadge(Icons.accessible, isTamil ? 'முதியோர் முன்னுரிமை' : 'Senior Priority'),
                  _pillBadge(Icons.straighten, isTamil ? '8.5 கி.மீ மலைப்பாதை' : '8.5 km Scenic Road'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Departure Slot Selection
        _sectionCard(
          icon: Icons.access_time_rounded,
          color: AppColors.templeMaroon,
          title: isTamil ? 'பயணத் தேதி & புறப்படும் நேரம்' : 'Travel Date & Departure Slot',
          subtitle: isTamil ? 'அடிவாரம் முனையத்தில் இருந்து தொடங்கும் • 7 நாட்கள் முன்பதிவு' : 'Departs from Adivaram Terminal • Book up to 7 days ahead',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(
                color: AppColors.templeMaroon,
                isTamil: isTamil,
              ),
              const SizedBox(height: 14),
              _SlotGrid(
                slots: _slots,
                selected: _shuttleSlot,
                selectedDate: _selectedBookingDate,
                color: AppColors.templeMaroon,
                onSelect: (s) => setState(() => _shuttleSlot = s),
              ),
              const SizedBox(height: 16),
              _Counter(
                label: isTamil ? 'பயணிகள் எண்ணிக்கை' : 'Passengers / Seats',
                count: _shuttleSeats,
                max: 6,
                color: AppColors.templeMaroon,
                onChanged: (v) => setState(() => _shuttleSeats = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Fare Summary & Boarding Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Column(
            children: [
              _summaryRow(
                isTamil ? 'பயணத் தேதி' : 'Travel Date',
                _formatDisplayDate(_selectedBookingDate, isTamil),
              ),
              _summaryRow(
                isTamil ? 'புறப்படும் நேரம்' : 'Departure Time',
                _shuttleSlot,
              ),
              _summaryRow(
                isTamil ? 'ஒரு நபருக்கான கட்டணம்' : 'Standard Ticket Fare',
                '₹20',
              ),
              _summaryRow(
                isTamil ? 'பயணிகள் எண்ணிக்கை' : 'Seats Selected',
                '$_shuttleSeats',
              ),
              _summaryRow(
                isTamil ? 'ஏறும் இடம்' : 'Boarding Point',
                isTamil ? 'அடிவாரம் பேருந்து முனையம் (வாயில் 1)' : 'Adivaram Bus Terminal (Gate 1)',
              ),
              _summaryRow(
                isTamil ? 'இறங்கும் இடம்' : 'Drop-off Point',
                isTamil ? 'மலைக்கோவில் ராஜகோபுரம்' : 'Hilltop Rajagopuram',
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTamil ? 'மொத்தக் கட்டணம்' : 'Total Fare',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  Text(
                    '₹$fare',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.templeMaroon,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Book Button
        _bookButton(
          label: isTamil ? 'பேருந்து பாஸ் பதிவு செய் • ₹$fare' : 'Book Bus Pass  •  ₹$fare',
          color: AppColors.templeMaroon,
          onTap: _bookShuttle,
        ),
        const SizedBox(height: 16),

        // Travel Guidelines
        _infoCard(
          icon: Icons.info_outline,
          title: isTamil ? 'பேருந்து பயண வழிகாட்டுதல்கள்' : 'Bus Travel Guidelines',
          points: [
            isTamil
                ? 'காலை 6:00 மணி முதல் இரவு 8:00 மணி வரை பேருந்து இயக்கப்படும்.'
                : 'Buses operate daily from 6:00 AM to 8:00 PM.',
            isTamil
                ? 'முதியவர்கள் மற்றும் மாற்றுத்திறனாளிகளுக்கு முன் வரிசை இருக்கைகள் ஒதுக்கப்படும்.'
                : 'Front rows are reserved for senior citizens and pregnant women.',
            isTamil
                ? 'மலை இறங்குவதற்கான பயணச் சீட்டை மலைக்கோவில் முனையத்தில் பெறலாம்.'
                : 'Return tickets can also be booked directly at the hilltop terminal.',
          ],
        ),
        const SizedBox(height: 12),

        // Switch to Darshan sub-page
        _switchPageCard(
          icon: Icons.temple_hindu_rounded,
          color: AppColors.deepSaffron,
          title: isTamil ? 'தரிசன அனுமதி தேவையா?' : 'Need a Darshan Pass too?',
          subtitle: isTamil
              ? 'இலவச, சிறப்பு அல்லது வி.ஐ.பி தரிசன வரிசை முன்பதிவு செய்ய இங்கே கிளிக் செய்யவும்.'
              : 'Book Free, Special (₹50) or VIP (₹250) Darshan tickets.',
          actionText: isTamil ? 'தரிசன முன்பதிவு செல்ல ➔' : 'Go to Darshan Booking ➔',
          onTap: () => setState(() => _selectedSubPage = 1),
        ),
      ],
    );
  }

  // ── Sub-Page 2: Darshan Booking ───────────────────────────────────────────
  Widget _buildDarshanBookingPage(AuthProvider auth, bool isTamil) {
    final type = _darshanTypes[_darshanIdx];
    final total = type.price * _devotees;

    return ListView(
      key: const ValueKey('darshan_booking_sub_page'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
      children: [
        if (!auth.isAuthenticated)
          AuthLockBanner(
            featureName: isTamil ? 'தரிசன முன்பதிவு' : 'Darshan Booking',
          ),

        // Darshan Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.temple_hindu_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'தரிசன அனுமதி முன்பதிவு' : 'Temple Darshan Booking',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isTamil ? 'மருதமலை முருகன் தேவஸ்தானம்' : 'Marudamalai Murugan Devasthanam',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _pillBadge(Icons.confirmation_number, isTamil ? 'மின்-பாஸ் (QR Code)' : 'Instant E-Pass QR'),
                  _pillBadge(Icons.fastfood, isTamil ? 'இலவச பிரசாதம்' : 'Temple Prasadam'),
                  _pillBadge(Icons.timer, isTamil ? 'நேரடி வரிசை நேரம்' : 'Live Queue Times'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Darshan Tier
        _sectionCard(
          icon: Icons.workspace_premium_rounded,
          color: AppColors.deepSaffron,
          title: isTamil ? 'தரிசன வகையைத் தேர்ந்தெடுக்கவும்' : 'Choose Darshan Category',
          subtitle: isTamil ? 'இலவச அல்லது விரைவு வரிசை தரிசனம்' : 'Select Free, Priority or VIP Access',
          child: Column(
            children: [
              ..._darshanTypes.asMap().entries.map((e) => _DarshanTypeCard(
                    type: e.value,
                    isSelected: e.key == _darshanIdx,
                    onTap: () => setState(() => _darshanIdx = e.key),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Time Slot & Devotees
        _sectionCard(
          icon: Icons.event_available_rounded,
          color: AppColors.deepSaffron,
          title: isTamil ? 'தரிசனத் தேதி & நேரம்' : 'Darshan Date & Time Slot',
          subtitle: isTamil ? 'கோவில் சந்நிதி நடை திறந்திருக்கும் நேரம் • 7 நாட்கள் முன்பதிவு' : 'Temple sanctum open slots • Book up to 7 days ahead',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateSelector(
                color: AppColors.deepSaffron,
                isTamil: isTamil,
              ),
              const SizedBox(height: 14),
              _SlotGrid(
                slots: _slots,
                selected: _darshanSlot,
                selectedDate: _selectedBookingDate,
                color: AppColors.deepSaffron,
                onSelect: (s) => setState(() => _darshanSlot = s),
              ),
              const SizedBox(height: 16),
              _Counter(
                label: isTamil ? 'பக்தர்கள் எண்ணிக்கை' : 'Devotees (Max 6)',
                count: _devotees,
                max: 6,
                color: AppColors.deepSaffron,
                onChanged: (v) => setState(() => _devotees = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Column(
            children: [
              _summaryRow(
                isTamil ? 'தேர்ந்தெடுக்கப்பட்ட தரிசனம்' : 'Selected Category',
                type.name,
              ),
              _summaryRow(
                isTamil ? 'தரிசனத் தேதி' : 'Darshan Date',
                _formatDisplayDate(_selectedBookingDate, isTamil),
              ),
              _summaryRow(
                isTamil ? 'பக்தர்கள் எண்ணிக்கை' : 'Devotees Count',
                '$_devotees',
              ),
              _summaryRow(
                isTamil ? 'தரிசன நேரம்' : 'Slot Time',
                _darshanSlot,
              ),
              _summaryRow(
                isTamil ? 'உத்தேச காத்திருப்பு நேரம்' : 'Estimated Queue Wait',
                type.description.split('•').last.trim(),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTamil ? 'மொத்தத் தொகை' : 'Total Amount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  Text(
                    total == 0 ? (isTamil ? 'இலவசம்' : 'Free') : '₹${total.toInt()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepSaffron,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Book Button
        _bookButton(
          label: isTamil
              ? 'தரிசன அனுமதி பதிவு செய் • ${total == 0 ? 'இலவசம்' : '₹${total.toInt()}'}'
              : 'Book Darshan Pass  •  ${total == 0 ? 'Free' : '₹${total.toInt()}'}',
          color: AppColors.deepSaffron,
          onTap: _bookDarshan,
        ),
        const SizedBox(height: 16),

        // Guidelines
        _infoCard(
          icon: Icons.gavel_rounded,
          title: isTamil ? 'கோவில் தரிசன நெறிமுறைகள்' : 'Temple Darshan Guidelines',
          points: [
            isTamil
                ? 'பாரம்பரிய உடை மட்டுமே அனுமதிக்கப்படும் (வேட்டி / சல்வார் / புடவை).'
                : 'Traditional attire strictly required (Dhoti/Kurta for men, Saree/Churidar for women).',
            isTamil
                ? 'கருவறைக்குள் கேமரா மற்றும் செல்லிடப்பேசி உபயோகிக்க தடை விதிக்கப்பட்டுள்ளது.'
                : 'Photography and mobile phones are strictly prohibited inside Sanctum.',
            isTamil
                ? 'அனைத்து தரிசன சீட்டுகளுக்கும் வெளிப் பிரகாரத்தில் இலவச பிரசாதம் வழங்கப்படும்.'
                : 'Blessed temple prasadam will be provided at the outer prakaram counter.',
          ],
        ),
        const SizedBox(height: 12),

        // Switch to Bus sub-page
        _switchPageCard(
          icon: Icons.directions_bus_rounded,
          color: AppColors.templeMaroon,
          title: isTamil ? 'அடிவாரத்தில் இருந்து பேருந்து தேவையா?' : 'Need Transit up the Hill?',
          subtitle: isTamil
              ? 'மின்கலப் பேருந்து மூலம் மலைக்கோவிலுக்கு செல்ல முன்பதிவு செய்யவும்.'
              : 'Book electric temple bus seats from Adivaram Bus Terminal (₹20).',
          actionText: isTamil ? 'பேருந்து முன்பதிவு செல்ல ➔' : 'Go to Bus Booking ➔',
          onTap: () => setState(() => _selectedSubPage = 0),
        ),
      ],
    );
  }

  void _onDateSelected(DateTime d) {
    setState(() {
      _selectedBookingDate = DateTime(d.year, d.month, d.day);
      if (_isSameDay(_selectedBookingDate, DateTime.now())) {
        if (_isSlotPast(_shuttleSlot, _selectedBookingDate)) {
          _shuttleSlot = _slots.firstWhere(
            (s) => !_isSlotPast(s, _selectedBookingDate),
            orElse: () => _slots.last,
          );
        }
        if (_isSlotPast(_darshanSlot, _selectedBookingDate)) {
          _darshanSlot = _slots.firstWhere(
            (s) => !_isSlotPast(s, _selectedBookingDate),
            orElse: () => _slots.last,
          );
        }
      }
    });
  }

  String _formatDisplayDate(DateTime date, bool isTamil) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isTomorrow = _isSameDay(date, now.add(const Duration(days: 1)));

    const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthsTa = ['ஜன', 'பிப்', 'மார்', 'ஏப்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆக', 'செப்', 'அக்', 'நவ', 'டிச'];
    const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysTa = ['திங்', 'செவ்', 'புத', 'வியா', 'வெள்', 'சனி', 'ஞாயி'];

    final month = (isTamil ? monthsTa : monthsEn)[date.month - 1];
    final dayName = (isTamil ? daysTa : daysEn)[date.weekday - 1];

    if (isToday) {
      return isTamil ? 'இன்று (${date.day} $month)' : 'Today (${date.day} $month)';
    }
    if (isTomorrow) {
      return isTamil ? 'நாளை (${date.day} $month)' : 'Tomorrow (${date.day} $month)';
    }
    return '$dayName, ${date.day} $month ${date.year}';
  }

  Widget _buildDateSelector({
    required Color color,
    required bool isTamil,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    final isDark = AppTheme.isDark(context);

    const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const monthsTa = ['ஜன', 'பிப்', 'மார்', 'ஏப்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆக', 'செப்', 'அக்', 'நவ', 'டிச'];
    const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const daysTa = ['திங்', 'செவ்', 'புத', 'வியா', 'வெள்', 'சனி', 'ஞாயி'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 15, color: color),
                const SizedBox(width: 6),
                Text(
                  isTamil ? 'தேதியைத் தேர்ந்தெடுக்கவும்' : 'Select Date',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedBookingDate,
                  firstDate: today,
                  lastDate: today.add(const Duration(days: 6)),
                  builder: (ctx, child) {
                    return Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: Theme.of(ctx).colorScheme.copyWith(
                              primary: color,
                              onPrimary: Colors.white,
                              surface: isDark ? const Color(0xFF141414) : Colors.white,
                              onSurface: isDark ? Colors.white : Colors.black87,
                            ),
                        dialogTheme: DialogThemeData(
                          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  _onDateSelected(picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTamil ? '7 நாட்கள் வரை' : '7 Days Advance',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.edit_calendar_rounded, size: 13, color: color),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final d = days[index];
              final isSel = _isSameDay(_selectedBookingDate, d);
              final isToday = index == 0;
              final dayName = isToday
                  ? (isTamil ? 'இன்று' : 'Today')
                  : (isTamil ? '${daysTa[d.weekday - 1]} ${d.day}' : '${daysEn[d.weekday - 1]} ${d.day}');
              final monthName = isTamil ? monthsTa[d.month - 1] : monthsEn[d.month - 1];

              return Semantics(
                button: true,
                selected: isSel,
                label: '$dayName ${d.day} $monthName',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _onDateSelected(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? color
                          : (isDark ? const Color(0xFF0A0A0A) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSel
                            ? color
                            : (isDark ? const Color(0xFF27272A) : Colors.grey.shade300),
                        width: isSel ? 1.8 : 1.0,
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isToday ? (isTamil ? 'இன்று (${d.day})' : 'Today (${d.day})') : dayName,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel
                              ? Colors.white
                              : (isDark ? Colors.white : AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pillBadge(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _summaryRow(String label, String value) => Builder(builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryOf(context))),
          ],
        ),
      ));

  Widget _infoCard({
    required IconData icon,
    required String title,
    required List<String> points,
  }) =>
      Builder(builder: (context) {
        final isDark = AppTheme.isDark(context);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...points.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: TextStyle(
                                color: AppTheme.textSecondaryOf(context),
                                fontWeight: FontWeight.w800)),
                        Expanded(
                          child: Text(
                            p,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondaryOf(context),
                                height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      });

  Widget _switchPageCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context))),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                actionText,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );

  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryOf(context))),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryOf(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: child,
            ),
          ],
        ),
      );

  Widget _bookButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final auth = context.watch<AuthProvider>();
    final isAuth = auth.isAuthenticated;

    final VoidCallback action = isAuth
        ? onTap
        : () => showAuthRequiredDialog(
              context: context,
              featureName: 'Ticket Booking',
            );

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: BouncingScaleTap(
        onTap: action,
        child: ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
            backgroundColor: isAuth ? color : Colors.grey.shade400,
            elevation: isAuth ? 2 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAuth ? Icons.check_circle_outline : Icons.lock,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isAuth ? label : 'Sign In to Access ($label)',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _bookShuttle() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAuthRequiredDialog(
        context: context,
        featureName: 'Shuttle Pass Booking',
      );
      return;
    }
    if (_isSlotPast(_shuttleSlot, _selectedBookingDate)) {
      _showPastSlotMessage();
      return;
    }
    final user = auth.currentUser;
    final amount = (_shuttleSeats * 20).toDouble();

    CashfreePaymentService.instance.startPayment(
      context: context,
      amount: amount,
      description: 'Shuttle Bus Booking',
      customerId: user != null && user.id.isNotEmpty
          ? user.id
          : 'devotee_${DateTime.now().millisecondsSinceEpoch}',
      customerName: user != null && user.name.isNotEmpty ? user.name : 'Devotee',
      customerEmail: user != null && user.email.isNotEmpty ? user.email : 'devotee@sannidhi.app',
      customerPhone: user != null && user.phone.isNotEmpty ? user.phone : '9999999999',
    ).then((result) {
      if (!mounted) return;
      if (result.result == CashfreePaymentResult.success) {
        final provider = context.read<UserActivityProvider>();
        final bookingId = UserActivityProvider.generateBookingId('SB');
        final now = DateTime.now();
        final bookingDate = _selectedBookingDate;
        final date =
            '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
        final tickets = UserActivityProvider.generateTickets(
          bookingId: bookingId,
          count: _shuttleSeats,
          type: 'BUS',
          slot: _shuttleSlot,
          date: date,
        );
        final booking = ShuttleBooking(
          bookingId: bookingId,
          slotTime: _shuttleSlot,
          totalFare: amount,
          seatCount: _shuttleSeats,
          tickets: tickets,
          timestamp: now,
          date: date,
        );
        provider.addShuttleBooking(
          booking,
          token: auth.token,
          userId: user?.id,
        );
        showTicketCarousel(
          context: context,
          tickets: tickets,
          type: TicketCarouselType.shuttle,
          slotTime: _shuttleSlot,
          date: date,
          bookingId: bookingId,
          pickupLocation: 'Adivaram Bus Stand',
          dropLocation: 'Hilltop Sannidhi',
        );
      } else if (result.result == CashfreePaymentResult.failure) {
        showCashfreePaymentFailureDialog(
          context: context,
          message: result.message,
          onRetry: _bookShuttle,
        );
      }
    });
  }

  void _bookDarshan() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAuthRequiredDialog(
        context: context,
        featureName: 'Darshan Pass Booking',
      );
      return;
    }
    if (_isSlotPast(_darshanSlot, _selectedBookingDate)) {
      _showPastSlotMessage();
      return;
    }
    final type = _darshanTypes[_darshanIdx];
    final total = type.price * _devotees;
    if (total == 0) {
      _saveDarshan(type);
      return;
    }
    final user = auth.currentUser;

    CashfreePaymentService.instance.startPayment(
      context: context,
      amount: total.toDouble(),
      description: type.name,
      customerId: user != null && user.id.isNotEmpty
          ? user.id
          : 'devotee_${DateTime.now().millisecondsSinceEpoch}',
      customerName: user != null && user.name.isNotEmpty ? user.name : 'Devotee',
      customerEmail: user != null && user.email.isNotEmpty ? user.email : 'devotee@sannidhi.app',
      customerPhone: user != null && user.phone.isNotEmpty ? user.phone : '9999999999',
    ).then((result) {
      if (!mounted) return;
      if (result.result == CashfreePaymentResult.success) {
        _saveDarshan(type);
      } else if (result.result == CashfreePaymentResult.failure) {
        showCashfreePaymentFailureDialog(
          context: context,
          message: result.message,
          onRetry: _bookDarshan,
        );
      }
    });
  }

  void _showPastSlotMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This time slot has already passed.')),
    );
  }

  void _saveDarshan(_DarshanType type) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final provider = context.read<UserActivityProvider>();
    final bookingId = UserActivityProvider.generateBookingId('DS');
    final now = DateTime.now();
    final bookingDate = _selectedBookingDate;
    final date =
        '${bookingDate.year}-${bookingDate.month.toString().padLeft(2, '0')}-${bookingDate.day.toString().padLeft(2, '0')}';
    final tickets = UserActivityProvider.generateTickets(
      bookingId: bookingId,
      count: _devotees,
      type: 'DRS',
      slot: _darshanSlot,
      date: date,
    );
    final booking = DarshanBooking(
      bookingId: bookingId,
      darshanType: type.name,
      slotTime: _darshanSlot,
      totalAmount: (type.price * _devotees).toDouble(),
      ticketCount: _devotees,
      tickets: tickets,
      timestamp: now,
      date: date,
    );
    provider.addDarshanBooking(
      booking,
      token: auth.token,
      userId: user?.id,
    );
    showTicketCarousel(
      context: context,
      tickets: tickets,
      type: TicketCarouselType.darshan,
      slotTime: _darshanSlot,
      date: date,
      bookingId: bookingId,
      darshanType: type.name,
    );
  }
}

// ── Darshan type data ─────────────────────────────────────────────────────────

class _DarshanType {
  final String name;
  final int price;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> benefits;

  const _DarshanType(this.name, this.price, this.icon, this.color,
      this.description, this.benefits);
}

class _DarshanTypeCard extends StatelessWidget {
  final _DarshanType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _DarshanTypeCard(
      {required this.type, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? type.color.withValues(alpha: 0.08)
              : (AppTheme.isDark(context) ? const Color(0xFF0A0A0A) : Colors.grey.shade50),
          border: Border.all(
            color: isSelected ? type.color : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(type.icon, color: type.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.textPrimaryOf(context)
                                  : AppTheme.textSecondaryOf(context))),
                      Text(type.description,
                          style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryOf(context))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type.price == 0 ? 'FREE' : '₹${type.price}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: type.color),
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: type.benefits
                    .map((b) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: type.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 10, color: type.color),
                              const SizedBox(width: 4),
                              Text(b,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: type.color,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Slot grid ─────────────────────────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  final List<String> slots;
  final String selected;
  final Color color;
  final ValueChanged<String> onSelect;
  final DateTime? selectedDate;

  const _SlotGrid({
    required this.slots,
    required this.selected,
    required this.color,
    required this.onSelect,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    final visibleSlots = slots.where((s) => !_isSlotPast(s, selectedDate)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTamil ? 'நேரத்தைத் தேர்ந்தெடுக்கவும்' : 'Select Time Slot',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
            Text(
              isTamil ? 'நேரடி இருப்பு' : 'Live availability',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryOf(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (visibleSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1D17) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTamil
                        ? 'இன்றைய அனைத்து நேரங்களும் முடிந்துவிட்டன. அடுத்த நாளைத் தேர்ந்தெடுக்கவும்.'
                        : 'All slots for today have passed. Please select a future date above.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: visibleSlots.map((s) {
              final isSel = s == selected;
              return Semantics(
                button: true,
                selected: isSel,
                label: s,
                child: InkWell(
                  onTap: () => onSelect(s),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minWidth: 92, minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel
                          ? color
                          : (isDark ? const Color(0xFF0A0A0A) : Colors.white),
                      border: Border.all(
                        color: isSel
                            ? color
                            : (isDark ? const Color(0xFF27272A) : Colors.grey.shade300),
                        width: isSel ? 2 : 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel
                              ? Colors.white
                              : (isDark ? Colors.white : AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ── Counter ───────────────────────────────────────────────────────────────────

class _Counter extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _Counter(
      {required this.label,
      required this.count,
      required this.max,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF222222) : Colors.grey.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.people_alt, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                Text(
                  'Max $max per booking',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          _btn(
            context,
            Icons.remove,
            count > 1 ? () => onChanged(count - 1) : null,
            color,
            'Decrease $label',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          _btn(
            context,
            Icons.add,
            count < max ? () => onChanged(count + 1) : null,
            color,
            'Increase $label',
          ),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, VoidCallback? onTap, Color color, String semanticLabel) {
    final isDark = AppTheme.isDark(context);
    return Semantics(
        button: true,
        label: semanticLabel,
        enabled: onTap != null,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: onTap != null
                ? color.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF141414) : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: onTap != null ? color : (isDark ? const Color(0xFF52525B) : Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ),
      );
  }
}

// ── Tab 2: My Active Passes ───────────────────────────────────────────────────

class _MyPassesTab extends StatefulWidget {
  const _MyPassesTab();

  @override
  State<_MyPassesTab> createState() => _MyPassesTabState();
}

class _MyPassesTabState extends State<_MyPassesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPasses();
    });
  }

  Future<void> _refreshPasses() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<UserActivityProvider>();
    await provider.loadFromLocal();
    if (auth.token.isNotEmpty) {
      await provider.syncFromBackend(auth.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 36, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 16),
              Text(
                isTamil ? 'பாஸ்களைக் காண உள்நுழையவும்' : 'Sign In to View Passes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryOf(context)),
              ),
              const SizedBox(height: 8),
              Text(
                isTamil
                    ? 'உங்கள் செயலில் உள்ள தரிசன பாஸ்கள் மற்றும் QR குறியீடுகளைக் காண உள்நுழையவும்.'
                    : 'Sign in to synchronize your active Darshan passes, QR codes, and boarding passes across your devices.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context), height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: Text(isTamil ? 'இப்போது உள்நுழையவும்' : 'Sign In Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => showAuthRequiredDialog(
                  context: context,
                  featureName: isTamil ? 'என் பாஸ்கள்' : 'My Passes',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final provider = context.watch<UserActivityProvider>();
    final shuttles = provider.activeShuttleBookings;
    final darshans = provider.darshanBookings;

    if (shuttles.isEmpty && darshans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.confirmation_num_outlined,
                size: 64, color: AppTheme.isDark(context) ? const Color(0xFF27272A) : Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              isTamil ? 'செயலிலுள்ள பாஸ்கள் எதுவும் இல்லை' : 'No active passes yet',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isTamil
                  ? 'தொடங்க பேருந்து அல்லது தரிசன பாஸை முன்பதிவு செய்யவும்'
                  : 'Book a shuttle or darshan pass to get started',
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPasses,
      color: AppTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 110),
        children: [
          if (shuttles.isNotEmpty) ...[
            _header(isTamil ? 'பேருந்து பாஸ்கள்' : 'Shuttle Passes', Icons.directions_bus, AppColors.templeMaroon),
            const SizedBox(height: 8),
            ...shuttles.asMap().entries.map((e) => FadeSlideIn(
                  delay: Duration(milliseconds: 35 * e.key),
                  child: _ShuttleBookingCard(booking: e.value, isTamil: isTamil),
                )),
            const SizedBox(height: 20),
          ],
          if (darshans.isNotEmpty) ...[
            _header(isTamil ? 'தரிசன பாஸ்கள்' : 'Darshan Passes', Icons.visibility, AppColors.deepSaffron),
            const SizedBox(height: 8),
            ...darshans.asMap().entries.map((e) => FadeSlideIn(
                  delay: Duration(milliseconds: 35 * e.key),
                  child: _DarshanBookingCard(booking: e.value, isTamil: isTamil),
                )),
          ],
        ],
      ),
    );
  }

  Widget _header(String title, IconData icon, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryOf(context))),
        ],
      );
}

class _ShuttleBookingCard extends StatelessWidget {
  final ShuttleBooking booking;
  final bool isTamil;
  const _ShuttleBookingCard({required this.booking, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return BouncingScaleTap(
      onTap: () => showTicketCarousel(
        context: context,
        tickets: booking.tickets,
        type: TicketCarouselType.shuttle,
        slotTime: booking.slotTime,
        date: booking.date,
        bookingId: booking.bookingId,
        pickupLocation: isTamil ? 'அடிவாரம் பேருந்து நிலையம்' : 'Adivaram Bus Stand',
        dropLocation: isTamil ? 'மலைக்கோவில் சன்னதி' : 'Hilltop Sannidhi',
      ),
      child: _PassCard(
        icon: Icons.directions_bus,
        color: AppColors.templeMaroon,
        title: isTamil ? 'பேருந்து — ${booking.slotTime}' : 'Shuttle — ${booking.slotTime}',
        subtitle: isTamil
            ? '${booking.seatCount} இருக்கை  •  ₹${booking.totalFare.toInt()}  •  ${booking.date}'
            : '${booking.seatCount} seat(s)  •  ₹${booking.totalFare.toInt()}  •  ${booking.date}',
        ticketCount: booking.tickets.length,
        bookingId: booking.bookingId,
        isUsed: booking.isAllUsed,
        isExpired: booking.isExpired,
        usedCount: booking.usedCount,
        isTamil: isTamil,
      ),
    );
  }
}

class _DarshanBookingCard extends StatelessWidget {
  final DarshanBooking booking;
  final bool isTamil;
  const _DarshanBookingCard({required this.booking, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    final String localizedType;
    if (isTamil) {
      if (booking.darshanType.contains('Free') || booking.darshanType.contains('General') || booking.darshanType.contains('இலவச')) {
        localizedType = 'இலவச பொது தரிசனம்';
      } else if (booking.darshanType.contains('VIP') || booking.darshanType.contains('விஐபி')) {
        localizedType = 'விஐபி தரிசனம்';
      } else if (booking.darshanType.contains('Special') || booking.darshanType.contains('சிறப்பு')) {
        localizedType = 'சிறப்பு விரைவு தரிசனம்';
      } else {
        localizedType = booking.darshanType;
      }
    } else {
      localizedType = booking.darshanType;
    }

    return BouncingScaleTap(
      onTap: () => showTicketCarousel(
        context: context,
        tickets: booking.tickets,
        type: TicketCarouselType.darshan,
        slotTime: booking.slotTime,
        date: booking.date,
        bookingId: booking.bookingId,
        darshanType: localizedType,
      ),
      child: _PassCard(
        icon: Icons.visibility,
        color: AppColors.deepSaffron,
        title: '$localizedType — ${booking.slotTime}',
        subtitle: isTamil
            ? '${booking.ticketCount} பக்தர்(கள்)  •  ${booking.totalAmount == 0 ? 'இலவசம்' : '₹${booking.totalAmount.toInt()}'}  •  ${booking.date}'
            : '${booking.ticketCount} devotee(s)  •  ${booking.totalAmount == 0 ? 'Free' : '₹${booking.totalAmount.toInt()}'}  •  ${booking.date}',
        ticketCount: booking.tickets.length,
        bookingId: booking.bookingId,
        isUsed: booking.isAllUsed,
        isExpired: booking.isExpired,
        usedCount: booking.usedCount,
        isTamil: isTamil,
      ),
    );
  }
}

class _PassCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int ticketCount;
  final String bookingId;
  final bool isUsed;
  final bool isExpired;
  final int usedCount;
  final bool isTamil;

  const _PassCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.ticketCount,
    required this.bookingId,
    this.isUsed = false,
    this.isExpired = false,
    this.usedCount = 0,
    this.isTamil = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final cardBg = isUsed
        ? (isDark ? const Color(0xFF1E2822) : const Color(0xFFF0FDF4))
        : (isExpired
            ? (isDark ? const Color(0xFF241414) : const Color(0xFFFEF2F2))
            : AppTheme.cardBg(context));

    final borderColor = isUsed
        ? const Color(0xFF16A34A).withValues(alpha: 0.4)
        : (isExpired
            ? const Color(0xFFDC2626).withValues(alpha: 0.45)
            : (isDark ? const Color(0xFF332D2A) : color.withValues(alpha: 0.25)));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: (isUsed || isExpired) ? 1.5 : 1.0),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isUsed
                      ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                      : (isExpired
                          ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                          : color.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isUsed
                      ? const Color(0xFF16A34A)
                      : (isExpired ? const Color(0xFFDC2626) : color),
                  size: 24,
                ),
              ),
              if (isUsed)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 9, color: Colors.white),
                  ),
                )
              else if (isExpired)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_off_rounded, size: 9, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTamil ? 13.5 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryOf(context),
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTamil ? 11.5 : 11,
                    color: AppTheme.textSecondaryOf(context),
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
                if (isUsed) ...[
                  const SizedBox(height: 4),
                  Text(
                    isTamil
                        ? '✓ வாயிலில் பதிவு செய்யப்பட்டது • பயன்பட்டது'
                        : '✓ Entry recorded at Gate • Used',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ] else if (isExpired) ...[
                  const SizedBox(height: 4),
                  Text(
                    isTamil
                        ? '⚠️ பாஸ் காலாவதியானது (நேரம் கடந்துவிட்டது)'
                        : '⚠️ Pass expired (Time slot lapsed)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isUsed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 10, color: Color(0xFF15803D)),
                      const SizedBox(width: 3),
                      Text(
                        isTamil ? 'பயன்பட்டது' : 'USED',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_off_rounded, size: 10, color: Color(0xFFDC2626)),
                      const SizedBox(width: 3),
                      Text(
                        isTamil ? 'காலாவதியானது' : 'EXPIRED',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                )
              else if (usedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    isTamil ? '$usedCount/$ticketCount பயன்பட்டது' : '$usedCount/$ticketCount USED',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isTamil ? '$ticketCount பாஸ்' : '$ticketCount QR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Icon(
                Icons.qr_code_2,
                color: isUsed
                    ? const Color(0xFF16A34A)
                    : (isExpired ? const Color(0xFFDC2626) : color),
                size: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
