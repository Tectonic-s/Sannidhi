import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/mock_payment_sheet.dart';
import '../../../data/models/activity_models.dart';
import '../../../data/models/shuttle_booking_model.dart';
import '../../../data/repositories/mock_shuttle_repository.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../services/tax_receipt_service.dart';

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
                Tab(text: l10n.translate('bookServices') ?? 'Book Services'),
                Tab(text: l10n.translate('myPasses') ?? 'My Active Passes'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _BookServicesTab(onToggleLocale: widget.onToggleLocale),
                const _MyPassesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Book Services ──────────────────────────────────────────────────────

class _BookServicesTab extends StatefulWidget {
  final VoidCallback onToggleLocale;
  const _BookServicesTab({required this.onToggleLocale});

  @override
  State<_BookServicesTab> createState() => _BookServicesTabState();
}

class _BookServicesTabState extends State<_BookServicesTab> {
  static const _slots = [
    '06:00 AM','06:30 AM','07:00 AM','07:30 AM',
    '08:00 AM','08:30 AM','09:00 AM','09:30 AM',
    '10:00 AM','10:30 AM','11:00 AM','04:00 PM',
    '04:30 PM','05:00 PM','05:30 PM','06:00 PM',
  ];

  static const _darshanTypes = [
    ('Free Queue', 0.0, 'freeQueue'),
    ('Special Darshan', 50.0, 'specialDarshan'),
    ('VIP Abhishekam', 250.0, 'vipAbhishekam'),
  ];

  String _selectedSlot = '09:00 AM';
  int _passengers = 1;
  int _darshanIdx = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(l10n.translate('shuttleBus') ?? 'Shuttle Bus'),
        const SizedBox(height: 4),
        _routeInfo(),
        const SizedBox(height: 12),
        _SlotSelector(
          slots: _slots,
          selected: _selectedSlot,
          onSelect: (s) => setState(() => _selectedSlot = s),
        ),
        const SizedBox(height: 16),
        _PassengerCounter(
          count: _passengers,
          max: 6,
          onChanged: (v) => setState(() => _passengers = v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.confirmation_num_outlined),
            label: Text(
                '${l10n.translate('confirmBooking') ?? 'Confirm Booking'}  •  ₹${_passengers * 50}'),
            onPressed: _confirmShuttle,
          ),
        ),
        const SizedBox(height: 28),
        _sectionTitle(l10n.translate('darshan') ?? 'Darshan'),
        const SizedBox(height: 12),
        _DarshanTypeSelector(
          types: _darshanTypes,
          selectedIdx: _darshanIdx,
          onSelect: (i) => setState(() => _darshanIdx = i),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility),
            label: Text(
                '${l10n.translate('bookDarshan') ?? 'Book Darshan'}  •  '
                '${_darshanTypes[_darshanIdx].$2 == 0 ? 'Free' : '₹${_darshanTypes[_darshanIdx].$2.toInt()}'}'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor),
            onPressed: _confirmDarshan,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  Widget _routeInfo() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.route, color: AppColors.info, size: 18),
            SizedBox(width: 8),
            Text('Main Bus Stand → Temple Entrance  •  ₹50/seat',
                style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  void _confirmShuttle() {
    final amount = (_passengers * 50).toDouble();
    showMockPaymentSheet(
      context: context,
      amount: amount,
      title: 'Shuttle Booking',
      onSuccess: () {
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final ticketId = 'SB${now.millisecondsSinceEpoch.toString().substring(7)}';
        final qr = 'SANNIDHI|SHUTTLE|$ticketId|$dateStr|$_selectedSlot|$_passengers';

        final ticket = ShuttleTicketModel(
          ticketId: ticketId,
          slot: _selectedSlot,
          seatCount: _passengers,
          qrPayload: qr,
          fare: amount,
          date: dateStr,
          pickupLocation: 'Main Bus Stand',
          dropLocation: 'Temple Entrance',
        );

        context.read<MockShuttleRepository>().bookShuttle(
              ShuttleBookingModel(
                id: ticketId,
                date: dateStr,
                time: _selectedSlot,
                status: 'Confirmed',
                pickupLocation: 'Main Bus Stand',
                dropLocation: 'Temple Entrance',
                seats: _passengers,
                price: amount,
              ),
            );
        context.read<UserActivityProvider>().addShuttleBooking(ticket);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _BoardingPassSheet(ticket: ticket),
        );
      },
    );
  }

  void _confirmDarshan() {
    final type = _darshanTypes[_darshanIdx];
    final amount = type.$2;
    if (amount == 0) {
      _saveDarshanAndShow('Free Queue', 0);
      return;
    }
    showMockPaymentSheet(
      context: context,
      amount: amount,
      title: type.$1,
      onSuccess: () => _saveDarshanAndShow(type.$1, amount),
    );
  }

  void _saveDarshanAndShow(String typeName, double amount) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final ticketId = 'DS${now.millisecondsSinceEpoch.toString().substring(7)}';
    final qr = 'SANNIDHI|DARSHAN|$ticketId|$typeName|$_selectedSlot|$dateStr';

    final ticket = DarshanTicketModel(
      ticketId: ticketId,
      darshanType: typeName,
      slot: _selectedSlot,
      devoteeName: 'Devotee',
      qrPayload: qr,
      fare: amount,
      date: dateStr,
    );
    context.read<UserActivityProvider>().addDarshanBooking(ticket);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DarshanPassSheet(ticket: ticket),
    );
  }
}

// ── Darshan type selector ─────────────────────────────────────────────────────

class _DarshanTypeSelector extends StatelessWidget {
  final List<(String, double, String)> types;
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  const _DarshanTypeSelector({
    required this.types,
    required this.selectedIdx,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: types.asMap().entries.map((e) {
        final isSelected = e.key == selectedIdx;
        final t = e.value;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accentColor.withValues(alpha: 0.1)
                  : Colors.white,
              border: Border.all(
                color: isSelected ? AppTheme.accentColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppTheme.accentColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.$1,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary)),
                ),
                Text(
                  t.$2 == 0 ? 'Free' : '₹${t.$2.toInt()}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Tab 2: My Active Passes ───────────────────────────────────────────────────

class _MyPassesTab extends StatelessWidget {
  const _MyPassesTab();

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<UserActivityProvider>();
    final shuttles = activity.activeShuttleTickets;
    final darshans = activity.darshanTickets;

    if (shuttles.isEmpty && darshans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.confirmation_num_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No active passes yet',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (shuttles.isNotEmpty) ...[
          _passHeader('Shuttle Passes', Icons.directions_bus, AppColors.info),
          const SizedBox(height: 8),
          ...shuttles.map((t) => _ShuttlePassCard(ticket: t)),
          const SizedBox(height: 20),
        ],
        if (darshans.isNotEmpty) ...[
          _passHeader('Darshan Passes', Icons.visibility, AppColors.deepSaffron),
          const SizedBox(height: 8),
          ...darshans.map((t) => _DarshanPassCard(ticket: t)),
        ],
      ],
    );
  }

  Widget _passHeader(String title, IconData icon, Color color) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      );
}

class _ShuttlePassCard extends StatelessWidget {
  final ShuttleTicketModel ticket;
  const _ShuttlePassCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BoardingPassSheet(ticket: ticket),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_bus,
                  color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.ticketId,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text(
                      '${ticket.slot}  •  ${ticket.seatCount} seat(s)  •  ₹${ticket.fare.toInt()}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.qr_code_2, color: AppTheme.primaryColor, size: 28),
          ],
        ),
      ),
    );
  }
}

class _DarshanPassCard extends StatelessWidget {
  final DarshanTicketModel ticket;
  const _DarshanPassCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DarshanPassSheet(ticket: ticket),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.deepSaffron.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.deepSaffron.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.visibility,
                  color: AppColors.deepSaffron, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.darshanType,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text('${ticket.slot}  •  ${ticket.date}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.qr_code_2,
                color: AppTheme.accentColor, size: 28),
          ],
        ),
      ),
    );
  }
}

// ── Slot selector ─────────────────────────────────────────────────────────────

class _SlotSelector extends StatelessWidget {
  final List<String> slots;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SlotSelector(
      {required this.slots, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('selectSlot') ?? 'Select Time Slot',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSel = slot == selected;
            return GestureDetector(
              onTap: () => onSelect(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primaryColor : Colors.white,
                  border: Border.all(
                      color: isSel
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(slot,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSel ? Colors.white : AppTheme.textPrimary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Passenger counter ─────────────────────────────────────────────────────────

class _PassengerCounter extends StatelessWidget {
  final int count;
  final int max;
  final ValueChanged<int> onChanged;

  const _PassengerCounter(
      {required this.count, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l10n.translate('passengers') ?? 'Passengers',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ),
          _Btn(
              icon: Icons.remove,
              onTap: count > 1 ? () => onChanged(count - 1) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
          ),
          _Btn(
              icon: Icons.add,
              onTap: count < max ? () => onChanged(count + 1) : null),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: onTap != null
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(icon,
              size: 20,
              color: onTap != null ? AppTheme.primaryColor : Colors.grey),
        ),
      ),
    );
  }
}

// ── Boarding pass sheet ───────────────────────────────────────────────────────

class _BoardingPassSheet extends StatelessWidget {
  final ShuttleTicketModel ticket;
  const _BoardingPassSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            _header(l10n.translate('bookingConfirmed') ?? 'Booking Confirmed!',
                AppTheme.primaryColor),
            _dashedDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: QrImageView(
                data: ticket.qrPayload,
                version: QrVersions.auto,
                size: 160,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: AppTheme.primaryColor),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF333333)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                _row(l10n.translate('ticketId') ?? 'Ticket ID', ticket.ticketId, bold: true),
                _row(l10n.translate('route') ?? 'Route',
                    '${ticket.pickupLocation} → ${ticket.dropLocation}'),
                _row(l10n.translate('date') ?? 'Date', ticket.date),
                _row(l10n.translate('time') ?? 'Time', ticket.slot),
                _row(l10n.translate('seats') ?? 'Seats', '${ticket.seatCount}'),
                _row(l10n.translate('price') ?? 'Price',
                    '₹${ticket.fare.toInt()}', bold: true),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Boarding Pass PDF'),
                onPressed: () => TaxReceiptService.instance
                    .printBoardingPass(context, ticket),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56)),
                child: Text(l10n.translate('done') ?? 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Darshan pass sheet ────────────────────────────────────────────────────────

class _DarshanPassSheet extends StatelessWidget {
  final DarshanTicketModel ticket;
  const _DarshanPassSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            _header('Darshan Pass', AppTheme.accentColor),
            _dashedDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: QrImageView(
                data: ticket.qrPayload,
                version: QrVersions.auto,
                size: 160,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: AppTheme.accentColor),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF333333)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                _row('Ticket ID', ticket.ticketId, bold: true),
                _row('Type', ticket.darshanType),
                _row(l10n.translate('date') ?? 'Date', ticket.date),
                _row(l10n.translate('time') ?? 'Time', ticket.slot),
                _row(l10n.translate('price') ?? 'Price',
                    ticket.fare == 0 ? 'Free' : '₹${ticket.fare.toInt()}',
                    bold: true),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppTheme.accentColor),
                child: Text(l10n.translate('done') ?? 'Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _handle() => Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
          color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
    );

Widget _header(String title, Color color) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(children: [
        const Icon(Icons.check_circle, color: Colors.white, size: 36),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ]),
    );

Widget _dashedDivider() => Row(children: [
      const SizedBox(
          width: 20,
          height: 20,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: AppColors.lightBackground, shape: BoxShape.circle))),
      Expanded(
        child: LayoutBuilder(builder: (_, c) {
          final count = (c.maxWidth / 8).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                count,
                (_) => Container(
                    width: 4, height: 1.5, color: Colors.grey.shade300)),
          );
        }),
      ),
      const SizedBox(
          width: 20,
          height: 20,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: AppColors.lightBackground, shape: BoxShape.circle))),
    ]);

Widget _row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
