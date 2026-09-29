import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sannidhi/core/constants/app_theme.dart';
import 'package:sannidhi/core/services/firebase_service.dart';
import 'package:sannidhi/core/utils/booking_utils.dart';
import 'package:sannidhi/core/widgets/micro_animations.dart';
import 'package:sannidhi/data/models/activity_models.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';
import '../l10n/app_localizations.dart';

enum TicketCarouselType { shuttle, darshan }

class TicketCarouselModal extends StatefulWidget {
  final List<IndividualTicket> tickets;
  final TicketCarouselType type;
  final String slotTime;
  final String date;
  final String bookingId;
  // Shuttle-specific
  final String? pickupLocation;
  final String? dropLocation;
  // Darshan-specific
  final String? darshanType;

  const TicketCarouselModal({
    super.key,
    required this.tickets,
    required this.type,
    required this.slotTime,
    required this.date,
    required this.bookingId,
    this.pickupLocation,
    this.dropLocation,
    this.darshanType,
  });

  @override
  State<TicketCarouselModal> createState() => _TicketCarouselModalState();
}

class _TicketCarouselModalState extends State<TicketCarouselModal> {
  late final PageController _pageController;
  int _currentPage = 0;

  late List<IndividualTicket> _tickets;
  StreamSubscription? _firebaseSub;
  Timer? _liveSyncTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _tickets = List<IndividualTicket>.from(widget.tickets);

    // 1. Subscribe to Cloud Firestore real-time ticket stream
    _initFirebaseStream();

    // 2. Start high-frequency background polling (checks backend SQLite & SharedPreferences)
    _startLiveSyncTimer();
  }

  void _initFirebaseStream() {
    if (FirebaseService.instance.isInitialized) {
      _firebaseSub = FirebaseService.instance
          .streamBookingTickets(widget.bookingId)
          .listen((docs) {
        if (!mounted) return;
        bool changed = false;
        for (final doc in docs) {
          final tid = doc['ticketId'] ?? doc['id'];
          final qr = doc['qrPayload'];
          final status = doc['status'];
          if (status == 'USED') {
            final tIndex = _tickets.indexWhere(
                (t) => t.ticketId == tid || t.qrPayload == qr || t.qrPayload == tid);
            if (tIndex != -1 && !_tickets[tIndex].isUsed) {
              _tickets[tIndex].isUsed = true;
              final scannedAt = doc['scannedAt'];
              if (scannedAt is Timestamp) {
                _tickets[tIndex].usedAt = scannedAt.toDate();
              } else {
                _tickets[tIndex].usedAt = DateTime.now();
              }
              _tickets[tIndex].verifiedBy = doc['scannedByName'] as String? ?? 'Gate Staff';
              changed = true;
            }
          }
        }
        if (changed && mounted) {
          setState(() {});
        }
      });
    }
  }

  void _startLiveSyncTimer() {
    _liveSyncTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      _checkBackendAndLocalStatus();
    });
  }

  Future<void> _checkBackendAndLocalStatus() async {
    bool stateChanged = false;

    // A. Check shared used ticket IDs from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final usedSet = (prefs.getStringList('sannidhi_used_ticket_ids') ?? []).toSet();
      for (final t in _tickets) {
        if (!t.isUsed && (usedSet.contains(t.ticketId) || usedSet.contains(t.qrPayload))) {
          t.isUsed = true;
          t.usedAt ??= DateTime.now();
          t.verifiedBy ??= 'Gate Staff';
          stateChanged = true;
        }
      }
    } catch (_) {}

    // B. Check backend live booking status endpoint
    try {
      final res = await http
          .get(Uri.parse('${AuthProvider.backendUrl}/api/bookings/${widget.bookingId}/status'))
          .timeout(const Duration(seconds: 2));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ticketsList = data['tickets'] as List<dynamic>? ?? [];
        for (final item in ticketsList) {
          final tid = item['ticketId'] as String?;
          final isUsed = item['isUsed'] == true || item['status'] == 'USED';
          if (isUsed && tid != null) {
            final idx = _tickets.indexWhere((t) => t.ticketId == tid);
            if (idx != -1 && !_tickets[idx].isUsed) {
              _tickets[idx].isUsed = true;
              if (item['verifiedAt'] != null) {
                _tickets[idx].usedAt = DateTime.tryParse(item['verifiedAt']);
              } else {
                _tickets[idx].usedAt = DateTime.now();
              }
              _tickets[idx].verifiedBy = item['verifiedBy'] ?? 'Gate Staff';
              stateChanged = true;
            }
          }
        }
      }
    } catch (_) {}

    // C. Rebuild if state changed or to re-evaluate live expiration
    if (mounted) {
      if (stateChanged ||
          isBookingExpired(slotTime: widget.slotTime, date: widget.date)) {
        setState(() {});
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activity = Provider.of<UserActivityProvider>(context);
    bool changed = false;
    for (final t in _tickets) {
      if (!t.isUsed && activity.isTicketUsed(t.ticketId)) {
        t.isUsed = true;
        t.usedAt ??= DateTime.now();
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
    }
  }

  void _manualSimulateScan(IndividualTicket t) {
    if (t.isUsed) return;
    setState(() {
      t.isUsed = true;
      t.usedAt = DateTime.now();
      t.verifiedBy = 'Gate Verifier (Simulated)';
    });

    final activity = context.read<UserActivityProvider>();
    activity.markTicketUsed(t.ticketId, verifiedBy: 'Gate Verifier');

    // Also notify Firebase if initialized
    if (FirebaseService.instance.isInitialized) {
      FirebaseService.instance.verifyTicketAtGate(
        qrPayloadOrTicketId: t.ticketId,
        staffId: 'staff_demo',
        staffName: 'Gate Staff',
      );
    }
  }

  @override
  void dispose() {
    _firebaseSub?.cancel();
    _liveSyncTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isShuttle => widget.type == TicketCarouselType.shuttle;

  Color get _accentColor =>
      _isShuttle ? AppColors.templeMaroon : AppColors.deepSaffron;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) {
        final isDark = AppTheme.isDark(context);
        final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _handle(),
              _header(isTamil),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 535,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _tickets.length,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemBuilder: (_, i) => _TicketCard(
                            key: ValueKey(_tickets[i].ticketId),
                            ticket: _tickets[i],
                            type: widget.type,
                            slotTime: widget.slotTime,
                            date: widget.date,
                            bookingId: widget.bookingId,
                            accentColor: _accentColor,
                            pickupLocation: widget.pickupLocation,
                            dropLocation: widget.dropLocation,
                            darshanType: widget.darshanType,
                            onSimulateScan: () => _manualSimulateScan(_tickets[i]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _dots(),
                      if (_tickets.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Text(
                            isTamil ? 'அடுத்த பாஸுக்கு ஸ்வைப் செய்யவும் →' : 'Swipe for next pass →',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
                        child: BouncingScaleTap(
                          onTap: () => Navigator.pop(context),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: _accentColor,
                            ),
                            child: Text(
                              isTamil ? 'சரி • முடிந்தது' : 'Done',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: AppTheme.isDark(context) ? const Color(0xFF27272A) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2)),
      );

  Widget _header(bool isTamil) {
    final allUsed = _tickets.isNotEmpty && _tickets.every((t) => t.isUsed);
    final anyUsed = _tickets.any((t) => t.isUsed);
    final usedCount = _tickets.where((t) => t.isUsed).length;
    final isExpired = isBookingExpired(slotTime: widget.slotTime, date: widget.date) && !allUsed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
                _isShuttle ? Icons.directions_bus : Icons.visibility,
                color: _accentColor,
                size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isShuttle
                      ? (isTamil ? 'பேருந்து பயண பாஸ்' : 'Shuttle Transit Pass')
                      : (isTamil ? 'தரிசன பாஸ் — ${widget.darshanType ?? ''}' : 'Darshan Pass — ${widget.darshanType ?? ''}'),
                  style: TextStyle(
                      fontSize: isTamil ? 13.5 : 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context)),
                ),
                Text(
                  isTamil
                      ? 'முன்பதிவு #${widget.bookingId}  •  ${_tickets.length} டிக்கெட்'
                      : 'Booking #${widget.bookingId}  •  ${_tickets.length} ticket(s)',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
          if (allUsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 12, color: Color(0xFF15803D)),
                  const SizedBox(width: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_off_rounded, size: 12, color: Color(0xFFDC2626)),
                  const SizedBox(width: 4),
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
          else if (anyUsed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_filled, size: 12, color: Color(0xFFB45309)),
                  const SizedBox(width: 4),
                  Text(
                    isTamil
                        ? '$usedCount/${_tickets.length} பயன்பட்டது'
                        : '$usedCount/${_tickets.length} USED',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulsingLiveDot(color: AppColors.success, size: 5),
                  const SizedBox(width: 5),
                  Text(
                    isTamil ? 'உறுதியானது' : 'CONFIRMED',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _tickets.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _currentPage ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _currentPage
                  ? _accentColor
                  : (AppTheme.isDark(context) ? const Color(0xFF27272A) : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
}

// ── Individual ticket card with Live Stamp Animation & Expiry ─────────────────

class _TicketCard extends StatefulWidget {
  final IndividualTicket ticket;
  final TicketCarouselType type;
  final String slotTime;
  final String date;
  final String bookingId;
  final Color accentColor;
  final String? pickupLocation;
  final String? dropLocation;
  final String? darshanType;
  final VoidCallback? onSimulateScan;

  const _TicketCard({
    super.key,
    required this.ticket,
    required this.type,
    required this.slotTime,
    required this.date,
    required this.bookingId,
    required this.accentColor,
    this.pickupLocation,
    this.dropLocation,
    this.darshanType,
    this.onSimulateScan,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard>
    with TickerProviderStateMixin {
  late final AnimationController _stampController;
  late final Animation<double> _stampScale;
  late final Animation<double> _stampOpacity;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  bool _justScanned = false;

  @override
  void initState() {
    super.initState();

    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _stampScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 2.5, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
    ]).animate(_stampController);

    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );

    if (widget.ticket.isUsed) {
      _stampController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _TicketCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.ticket.isUsed && widget.ticket.isUsed) {
      _triggerLiveScanAnimation();
    }
  }

  void _triggerLiveScanAnimation() {
    setState(() {
      _justScanned = true;
    });
    HapticFeedback.heavyImpact();
    _stampController.forward(from: 0.0);
    _glowController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _stampController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool get _isShuttle => widget.type == TicketCarouselType.shuttle;

  bool get _isExpired =>
      widget.ticket.isExpired(fallbackSlot: widget.slotTime, fallbackDate: widget.date);

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowVal = _glowAnimation.value;
          final isGlowing = _glowController.isAnimating || _justScanned;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.ticket.isUsed
                    ? const Color(0xFF16A34A).withValues(alpha: isGlowing ? 0.9 : 0.4)
                    : (_isExpired
                        ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                        : (isDark ? const Color(0xFF222222) : Colors.transparent)),
                width: isGlowing ? 2.5 : 1.2,
              ),
              boxShadow: [
                if (isGlowing)
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.35 * (1.0 - glowVal)),
                    blurRadius: 24 * (1.0 + glowVal),
                    spreadRadius: 4 * (1.0 - glowVal),
                  ),
                BoxShadow(
                  color: widget.accentColor.withValues(alpha: isDark ? 0.08 : 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            _cardHeader(isTamil),
            _dashedDivider(context),
            _qrSection(context, isTamil),
            _dashedDivider(context),
            _detailsSection(context, isTamil),
            _bottomBadge(isTamil),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(bool isTamil) {
    final isUsed = widget.ticket.isUsed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isUsed
            ? const Color(0xFF15803D)
            : (_isExpired ? const Color(0xFF991B1B) : widget.accentColor),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.temple_hindu, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isTamil ? 'மருதமலை தேவஸ்தானம்' : 'Maruthamalai Devasthanam',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUsed
                      ? const Color(0xFF166534)
                      : (_isExpired
                          ? const Color(0xFF7F1D1D)
                          : Colors.white.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUsed) ...[
                      const Icon(Icons.check, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        isTamil ? 'பயன்பட்டது' : 'USED',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ] else if (_isExpired) ...[
                      const Icon(Icons.timer_off, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        isTamil ? 'காலாவதியானது' : 'EXPIRED',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ] else ...[
                      Text(
                        widget.ticket.ticketLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isShuttle
                ? (isTamil ? 'பேருந்து பயண பாஸ்' : 'Shuttle Transit Pass')
                : (isTamil ? 'தரிசன பாஸ்' : 'Darshan Pass'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          if (_isShuttle && widget.pickupLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.pickupLocation!,
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward,
                        color: Colors.white70, size: 12),
                  ),
                  Text(widget.dropLocation ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          if (!_isShuttle && widget.darshanType != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(widget.darshanType!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _qrSection(BuildContext context, bool isTamil) {
    final isUsed = widget.ticket.isUsed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          GestureDetector(
            onDoubleTap: () {
              // Quick developer/tester shortcut to simulate scanning
              if (!isUsed && !_isExpired) {
                widget.onSimulateScan?.call();
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (isUsed || _isExpired) ? 0.16 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: widget.ticket.qrPayload,
                      version: QrVersions.auto,
                      size: 130,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: isUsed
                            ? const Color(0xFF16A34A)
                            : (_isExpired ? const Color(0xFFDC2626) : widget.accentColor),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ),

                // ── SCANNED STAMP WITH LIVE BOUNCE ANIMATION ──────────────
                if (isUsed)
                  FadeTransition(
                    opacity: _stampOpacity,
                    child: ScaleTransition(
                      scale: _stampScale,
                      child: Transform.rotate(
                        angle: -0.14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF16A34A),
                              width: 2.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified,
                                      color: Color(0xFF16A34A), size: 16),
                                  SizedBox(width: 5),
                                  Text(
                                    'ENTRY VERIFIED',
                                    style: TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isTamil ? 'பயன்பட்டது • SCANNED' : 'ADMITTED • SCANNED',
                                style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )

                // ── EXPIRED STAMP ──────────────────────────────────────────
                else if (_isExpired)
                  Transform.rotate(
                    angle: -0.14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFDC2626),
                          width: 2.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.timer_off_rounded,
                                  color: Color(0xFFDC2626), size: 16),
                              SizedBox(width: 5),
                              Text(
                                'PASS EXPIRED',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTamil
                                ? 'காலாவதியானது • NOT SCANNED'
                                : 'SLOT PASSED • NOT SCANNED',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Explanatory banners below QR ────────────────────────────────
          if (isUsed) ...[
            if (_justScanned)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF22C55E)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.celebration_rounded, size: 13, color: Color(0xFF15803D)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isTamil
                            ? 'தற்போது வாயிலில் ஸ்கேன் செய்யப்பட்டது! சந்நிதிக்கு நல்வரவு 🙏'
                            : 'Just scanned live at Temple Gate! Welcome 🙏',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 11, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    widget.ticket.usedAt != null
                        ? (isTamil
                            ? '${_formatTime(widget.ticket.usedAt!)} மணிக்கு அனுமதிக்கப்பட்டது'
                            : 'Admitted at ${_formatTime(widget.ticket.usedAt!)}')
                        : (isTamil
                            ? 'கோவில் வாயிலில் சரிபார்க்கப்பட்டது'
                            : 'Pass verified & admitted at Temple Gate'),
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isExpired) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_toggle_off_rounded,
                      size: 13, color: Color(0xFFDC2626)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isTamil
                          ? 'முன்பதிவு நேரம் கடந்துவிட்டது. வாயிலில் ஸ்கேன் செய்யப்படவில்லை.'
                          : 'Time passed without scan. Pass validity has expired.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PulsingLiveDot(color: AppColors.success, size: 5),
                const SizedBox(width: 6),
                Text(
                  isTamil ? 'நுழைவு வாயிலில் ஸ்கேன் செய்யவும்' : 'Scan live at Entry Gate',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsSection(BuildContext context, bool isTamil) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _row(context, isTamil ? 'டிக்கெட் எண்' : 'Ticket ID', widget.ticket.ticketId, bold: true),
            _row(context, isTamil ? 'தேதி' : 'Date', widget.date),
            _row(context, isTamil ? 'நேரம்' : 'Time Slot', widget.slotTime),
            _row(context, isTamil ? 'முன்பதிவு எண்' : 'Booking Ref', widget.bookingId),
          ],
        ),
      );

  Widget _bottomBadge(bool isTamil) {
    final isUsed = widget.ticket.isUsed;
    final badgeColor = isUsed
        ? const Color(0xFF16A34A)
        : (_isExpired ? const Color(0xFFDC2626) : widget.accentColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isUsed
                ? Icons.check_circle
                : (_isExpired ? Icons.timer_off_rounded : Icons.verified),
            color: badgeColor,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isUsed
                ? (isTamil ? 'தரிசனம் அனுமதிக்கப்பட்டது • Verified' : 'Entry recorded • Admitted at Gate')
                : (_isExpired
                    ? (isTamil ? 'பாஸ் காலாவதியானது • பயன்படுத்த முடியாது' : 'Pass expired • Validity lapsed')
                    : (isTamil ? 'ஒருமுறை மட்டுமே செல்லுபடியாகும்' : 'Valid for one-time entry  •  Non-transferable')),
            style: TextStyle(
              fontSize: isTamil ? 11 : 10,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Widget _dashedDivider(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          _notch(context),
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              final count = (c.maxWidth / 8).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 4,
                    height: 1.5,
                    color: isDark ? const Color(0xFF27272A) : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
          _notch(context),
        ],
      ),
    );
  }

  Widget _notch(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondaryOf(context))),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.textPrimaryOf(context))),
          ],
        ),
      );
}

// ── Helper to show the modal ──────────────────────────────────────────────────

void showTicketCarousel({
  required BuildContext context,
  required List<IndividualTicket> tickets,
  required TicketCarouselType type,
  required String slotTime,
  required String date,
  required String bookingId,
  String? pickupLocation,
  String? dropLocation,
  String? darshanType,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TicketCarouselModal(
      tickets: tickets,
      type: type,
      slotTime: slotTime,
      date: date,
      bookingId: bookingId,
      pickupLocation: pickupLocation,
      dropLocation: dropLocation,
      darshanType: darshanType,
    ),
  );
}
