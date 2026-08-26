import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sannidhi/core/constants/app_theme.dart';
import 'package:sannidhi/data/models/activity_models.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isShuttle => widget.type == TicketCarouselType.shuttle;

  Color get _accentColor =>
      _isShuttle ? AppColors.info : AppColors.deepSaffron;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                child: Column(
                  children: [
                    SizedBox(
                      height: 520,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.tickets.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) => _TicketCard(
                          ticket: widget.tickets[i],
                          type: widget.type,
                          slotTime: widget.slotTime,
                          date: widget.date,
                          bookingId: widget.bookingId,
                          accentColor: _accentColor,
                          pickupLocation: widget.pickupLocation,
                          dropLocation: widget.dropLocation,
                          darshanType: widget.darshanType,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _dots(),
                    if (widget.tickets.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 2),
                        child: Text(
                          'Swipe for next pass →',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: _accentColor),
                        child: const Text('Done  🙏',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2)),
      );

  Widget _header() => Padding(
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
                        ? 'Shuttle Transit Pass'
                        : 'Darshan Pass — ${widget.darshanType ?? ''}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Booking #${widget.bookingId}  •  ${widget.tickets.length} ticket(s)',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('CONFIRMED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success)),
            ),
          ],
        ),
      );

  Widget _dots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.tickets.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _currentPage ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _currentPage
                  ? _accentColor
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
}

// ── Individual ticket card ────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final IndividualTicket ticket;
  final TicketCarouselType type;
  final String slotTime;
  final String date;
  final String bookingId;
  final Color accentColor;
  final String? pickupLocation;
  final String? dropLocation;
  final String? darshanType;

  const _TicketCard({
    required this.ticket,
    required this.type,
    required this.slotTime,
    required this.date,
    required this.bookingId,
    required this.accentColor,
    this.pickupLocation,
    this.dropLocation,
    this.darshanType,
  });

  bool get _isShuttle => type == TicketCarouselType.shuttle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: accentColor.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            _cardHeader(),
            _dashedDivider(),
            _qrSection(),
            _dashedDivider(),
            _detailsSection(),
            _bottomBadge(),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.temple_hindu,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Maruthamalai Devasthanam',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket.ticketLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _isShuttle ? 'Shuttle Transit Pass' : 'Darshan Pass',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            if (_isShuttle && pickupLocation != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pickupLocation!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward,
                          color: Colors.white70, size: 12),
                    ),
                    Text(dropLocation ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            if (!_isShuttle && darshanType != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(darshanType!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ),
          ],
        ),
      );

  Widget _qrSection() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            QrImageView(
              data: ticket.qrPayload,
              version: QrVersions.auto,
              size: 140,
              eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square, color: accentColor),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF333333)),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan at entry gate',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );

  Widget _detailsSection() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _row('Ticket ID', ticket.ticketId, bold: true),
            _row('Date', date),
            _row('Time Slot', slotTime),
            _row('Booking Ref', bookingId),
          ],
        ),
      );

  Widget _bottomBadge() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified, color: accentColor, size: 14),
            const SizedBox(width: 6),
            Text(
              'Valid for one-time entry  •  Non-transferable',
              style: TextStyle(
                  fontSize: 10,
                  color: accentColor,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _dashedDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          children: [
            _notch(),
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
                          color: Colors.grey.shade300)),
                );
              }),
            ),
            _notch(),
          ],
        ),
      );

  Widget _notch() => SizedBox(
        width: 16,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), shape: BoxShape.circle),
        ),
      );

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w500,
                    color: AppTheme.textPrimary)),
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
