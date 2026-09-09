import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/services/cashfree_payment_service.dart';
import '../../../core/widgets/ticket_carousel_modal.dart';
import '../../../data/models/activity_models.dart';
import '../../../providers/user_activity_provider.dart';
import '../payment/cashfree_payment_screen.dart';

bool _isSlotPast(String slot) {
  final parts = slot.split(' ');
  final timeParts = parts[0].split(':');
  var hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  final period = parts[1];

  if (period == 'AM' && hour == 12) hour = 0;
  if (period == 'PM' && hour != 12) hour += 12;

  final now = TimeOfDay.now();
  final slotMinutes = hour * 60 + minute;
  final currentMinutes = now.hour * 60 + now.minute;
  return currentMinutes >= slotMinutes;
}

class BookingsScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  const BookingsScreen({super.key, required this.onToggleLocale});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                Tab(text: l10n.translate('bookServices') ?? 'Book Passes'),
                Tab(text: l10n.translate('myPasses') ?? 'My Active Passes'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BookPassesTab(onBooked: () => _tab.animateTo(1)),
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
  const _BookPassesTab({required this.onBooked});

  @override
  State<_BookPassesTab> createState() => _BookPassesTabState();
}

class _BookPassesTabState extends State<_BookPassesTab> {
  Timer? _slotRefreshTimer;

  @override
  void initState() {
    super.initState();
    final firstAvailable = _slots.firstWhere(
      (slot) => !_isSlotPast(slot),
      orElse: () => _slots.last,
    );
    _shuttleSlot = firstAvailable;
    _darshanSlot = firstAvailable;
    _slotRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
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

  // Shuttle state
  String _shuttleSlot = '09:00 AM';
  int _shuttleSeats = 1;

  // Darshan state
  String _darshanSlot = '09:00 AM';
  int _darshanIdx = 0;
  int _devotees = 1;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionCard(
          icon: Icons.directions_bus,
          color: AppColors.info,
          title: 'Shuttle Bus',
          subtitle: 'Adivaram Bus Stand → Hilltop Sannidhi  •  ₹20/seat',
          child: Column(
            children: [
              _SlotGrid(
                slots: _slots,
                selected: _shuttleSlot,
                color: AppColors.info,
                onSelect: (s) => setState(() => _shuttleSlot = s),
              ),
              const SizedBox(height: 12),
              _Counter(
                label: 'Seats',
                count: _shuttleSeats,
                max: 6,
                color: AppColors.info,
                onChanged: (v) => setState(() => _shuttleSeats = v),
              ),
              const SizedBox(height: 16),
              _bookButton(
                label: 'Book Shuttle  •  ₹${_shuttleSeats * 20}',
                color: AppColors.info,
                onTap: _bookShuttle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard(
          icon: Icons.visibility,
          color: AppColors.deepSaffron,
          title: 'Darshan Pass',
          subtitle: 'Select type, slot & number of devotees',
          child: Column(
            children: [
              ..._darshanTypes.asMap().entries.map((e) => _DarshanTypeCard(
                    type: e.value,
                    isSelected: e.key == _darshanIdx,
                    onTap: () => setState(() => _darshanIdx = e.key),
                  )),
              const SizedBox(height: 12),
              _SlotGrid(
                slots: _slots,
                selected: _darshanSlot,
                color: AppColors.deepSaffron,
                onSelect: (s) => setState(() => _darshanSlot = s),
              ),
              const SizedBox(height: 12),
              _Counter(
                label: 'Devotees',
                count: _devotees,
                max: 6,
                color: AppColors.deepSaffron,
                onChanged: (v) => setState(() => _devotees = v),
              ),
              const SizedBox(height: 16),
              _bookButton(
                label: () {
                  final t = _darshanTypes[_darshanIdx];
                  final total = t.price * _devotees;
                  return 'Book Darshan  •  ${total == 0 ? 'Free' : '₹${total.toInt()}'}';
                }(),
                color: AppColors.deepSaffron,
                onTap: _bookDarshan,
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
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
  }) =>
      SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );

  void _bookShuttle() {
    if (_isSlotPast(_shuttleSlot)) {
      _showPastSlotMessage();
      return;
    }
    final amount = (_shuttleSeats * 20).toDouble();
    CashfreePaymentService.instance.startPayment(
      context: context,
      amount: amount,
      description: 'Shuttle Bus Booking',
      customerId: 'devotee_${DateTime.now().millisecondsSinceEpoch}',
      customerName: 'Devotee',
      customerEmail: 'devotee@sannidhi.app',
      customerPhone: '9999999999',
    ).then((result) {
      if (!mounted) return;
      if (result.result == CashfreePaymentResult.success) {
        final provider = context.read<UserActivityProvider>();
        final bookingId = UserActivityProvider.generateBookingId('SB');
        final now = DateTime.now();
        final date =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
        provider.addShuttleBooking(booking);
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
    if (_isSlotPast(_darshanSlot)) {
      _showPastSlotMessage();
      return;
    }
    final type = _darshanTypes[_darshanIdx];
    final total = type.price * _devotees;
    if (total == 0) {
      _saveDarshan(type);
      return;
    }
    CashfreePaymentService.instance.startPayment(
      context: context,
      amount: total.toDouble(),
      description: type.name,
      customerId: 'devotee_${DateTime.now().millisecondsSinceEpoch}',
      customerName: 'Devotee',
      customerEmail: 'devotee@sannidhi.app',
      customerPhone: '9999999999',
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
    final provider = context.read<UserActivityProvider>();
    final bookingId = UserActivityProvider.generateBookingId('DS');
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
    provider.addDarshanBooking(booking);
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
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? type.color : Colors.grey.shade200,
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
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary)),
                      Text(type.description,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary)),
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

  const _SlotGrid(
      {required this.slots,
      required this.selected,
      required this.color,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Time Slot',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((s) {
            final isSel = s == selected;
            final isPast = _isSlotPast(s);
            return GestureDetector(
              onTap: isPast ? null : () => onSelect(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: isPast
                      ? Colors.grey.shade100
                      : isSel
                        ? color
                        : Colors.white,
                  border: Border.all(
                      color: isPast
                        ? Colors.grey.shade300
                        : isSel
                          ? color
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(s,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPast
                          ? Colors.grey.shade500
                          : isSel
                            ? Colors.white
                            : AppTheme.textPrimary)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          _btn(Icons.remove, count > 1 ? () => onChanged(count - 1) : null,
              color),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
          _btn(Icons.add, count < max ? () => onChanged(count + 1) : null,
              color),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap, Color color) => SizedBox(
        width: 36,
        height: 36,
        child: Material(
          color: onTap != null
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Icon(icon,
                size: 18,
                color: onTap != null ? color : Colors.grey),
          ),
        ),
      );
}

// ── Tab 2: My Active Passes ───────────────────────────────────────────────────

class _MyPassesTab extends StatelessWidget {
  const _MyPassesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserActivityProvider>();
    final shuttles = provider.activeShuttleBookings;
    final darshans = provider.darshanBookings;

    if (shuttles.isEmpty && darshans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.confirmation_num_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No active passes yet',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Book a shuttle or darshan pass to get started',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (shuttles.isNotEmpty) ...[
          _header('Shuttle Passes', Icons.directions_bus, AppColors.info),
          const SizedBox(height: 8),
          ...shuttles.map((b) => _ShuttleBookingCard(booking: b)),
          const SizedBox(height: 20),
        ],
        if (darshans.isNotEmpty) ...[
          _header('Darshan Passes', Icons.visibility, AppColors.deepSaffron),
          const SizedBox(height: 8),
          ...darshans.map((b) => _DarshanBookingCard(booking: b)),
        ],
      ],
    );
  }

  Widget _header(String title, IconData icon, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      );
}

class _ShuttleBookingCard extends StatelessWidget {
  final ShuttleBooking booking;
  const _ShuttleBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showTicketCarousel(
        context: context,
        tickets: booking.tickets,
        type: TicketCarouselType.shuttle,
        slotTime: booking.slotTime,
        date: booking.date,
        bookingId: booking.bookingId,
        pickupLocation: 'Adivaram Bus Stand',
        dropLocation: 'Hilltop Sannidhi',
      ),
      child: _PassCard(
        icon: Icons.directions_bus,
        color: AppColors.info,
        title: 'Shuttle — ${booking.slotTime}',
        subtitle:
            '${booking.seatCount} seat(s)  •  ₹${booking.totalFare.toInt()}  •  ${booking.date}',
        ticketCount: booking.tickets.length,
        bookingId: booking.bookingId,
      ),
    );
  }
}

class _DarshanBookingCard extends StatelessWidget {
  final DarshanBooking booking;
  const _DarshanBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showTicketCarousel(
        context: context,
        tickets: booking.tickets,
        type: TicketCarouselType.darshan,
        slotTime: booking.slotTime,
        date: booking.date,
        bookingId: booking.bookingId,
        darshanType: booking.darshanType,
      ),
      child: _PassCard(
        icon: Icons.visibility,
        color: AppColors.deepSaffron,
        title: '${booking.darshanType} — ${booking.slotTime}',
        subtitle:
            '${booking.ticketCount} devotee(s)  •  ${booking.totalAmount == 0 ? 'Free' : '₹${booking.totalAmount.toInt()}'}  •  ${booking.date}',
        ticketCount: booking.tickets.length,
        bookingId: booking.bookingId,
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

  const _PassCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.ticketCount,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$ticketCount QR',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
              const SizedBox(height: 4),
              Icon(Icons.qr_code_2, color: color, size: 22),
            ],
          ),
        ],
      ),
    );
  }
}
