import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/widgets/ticket_carousel_modal.dart';
import '../../../core/services/cashfree_payment_service.dart';
import '../../../data/models/activity_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../facility/facility_locator_screen.dart';
import '../payment/cashfree_payment_screen.dart';

class _ServiceItem {
  final IconData icon;
  final String titleKey;
  final String tamilTitle;
  final String descKey;
  final Color color;
  final double fee;
  final String timing;
  final String location;
  final String prasadam;
  final String items;

  const _ServiceItem({
    required this.icon,
    required this.titleKey,
    required this.tamilTitle,
    required this.descKey,
    required this.color,
    required this.fee,
    required this.timing,
    required this.location,
    required this.prasadam,
    required this.items,
  });
}

const _services = [
  _ServiceItem(
    icon: Icons.terrain,
    titleKey: 'caveVisit',
    tamilTitle: 'பம்பட்டி சித்தர் குகை',
    descKey: 'caveVisitDesc',
    color: Color(0xFF5D4037),
    fee: 0,
    timing: '6:00 AM – 12:00 PM & 4:00 PM – 8:00 PM',
    location: 'Hilltop — follow signs from main sanctum',
    prasadam: 'Vibhuti & Kumkum prasadam',
    items: 'Comfortable footwear, torch recommended',
  ),
  _ServiceItem(
    icon: Icons.auto_awesome,
    titleKey: 'specialAbhishekam',
    tamilTitle: 'சிறப்பு அபிஷேகம்',
    descKey: 'specialAbhishekamDesc',
    color: AppColors.deepSaffron,
    fee: 250,
    timing: '7:00 AM, 10:00 AM & 5:00 PM',
    location: 'Main Sanctum — Counter 2',
    prasadam: 'Panchamritam & Vibhuti',
    items: 'Dhoti / Saree mandatory, no shorts',
  ),
  _ServiceItem(
    icon: Icons.directions_car,
    titleKey: 'thangaratham',
    tamilTitle: 'தங்க தேர் (தங்க ரதம்)',
    descKey: 'thangarathamDesc',
    color: Color(0xFFFFB300),
    fee: 0,
    timing: 'Festival days only — check announcements',
    location: 'Temple main street procession',
    prasadam: 'Special prasadam distributed on route',
    items: 'Arrive 30 min early for good viewing spot',
  ),
  _ServiceItem(
    icon: Icons.restaurant,
    titleKey: 'annadhanam',
    tamilTitle: 'அன்னதானம்',
    descKey: 'annadhanamDesc',
    color: AppColors.success,
    fee: 0,
    timing: '11:30 AM – 3:00 PM daily',
    location: 'Hilltop Mandapam Dining Hall',
    prasadam: 'Full vegetarian meal — rice, sambar, kootu, payasam',
    items: 'No booking required, open to all pilgrims',
  ),
  _ServiceItem(
    icon: Icons.volunteer_activism,
    titleKey: 'archanai',
    tamilTitle: 'அர்ச்சனை',
    descKey: 'archanaiDesc',
    color: AppColors.templeMaroon,
    fee: 50,
    timing: 'All pooja timings',
    location: 'Archana counter near main entrance',
    prasadam: 'Flowers, Vibhuti, Kumkum & Prasadam',
    items: 'Bring devotee name & star (natchathiram)',
  ),
];

class ServicesScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const ServicesScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 110),
        children: [
          // Facility Locator Quick Tile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF01579B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x220288D1), blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.explore, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTamil ? 'கோயில் வசதிகள் வழிகாட்டி' : 'Temple Facilities Locator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTamil
                            ? 'குடிநீர், அன்னதானம், அவசர உதவி & கழிப்பறை'
                            : 'RO water points, medical post, dining hall & shoe stands',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                BouncingScaleTap(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacilityLocatorScreen(onToggleLocale: onToggleLocale),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FacilityLocatorScreen(onToggleLocale: onToggleLocale),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF01579B),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    child: Text(isTamil ? 'காண்க' : 'Locate'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            isTamil ? 'கோயில் சேவைகள் & வழிபாடுகள்' : 'Temple Devasthanam Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),

          ..._services.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final title = isTamil
                ? s.tamilTitle
                : (l10n.translate(s.titleKey) ?? s.titleKey);
            final desc = l10n.translate(s.descKey) ?? s.descKey;
            return FadeSlideIn(
              delay: Duration(milliseconds: 35 * idx.clamp(0, 10)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceCard(
                  service: s,
                  title: title,
                  desc: desc,
                  onTap: () => _showDetail(context, s, title, l10n),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, _ServiceItem s, String title,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceDetailSheet(
          service: s, title: title, l10n: l10n),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem service;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ServiceCard(
      {required this.service,
      required this.title,
      required this.desc,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    return BouncingScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(service.icon, color: service.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: isTamil ? 16.5 : 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryOf(context))),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: TextStyle(
                          fontSize: isTamil ? 13.5 : 12,
                          color: AppTheme.textSecondaryOf(context),
                          height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  service.fee == 0
                      ? (isTamil ? 'இலவசம்' : 'Free')
                      : '₹${service.fee.toInt()}',
                  style: TextStyle(
                      fontSize: isTamil ? 13.5 : 13,
                      fontWeight: FontWeight.w800,
                      color: service.fee == 0
                          ? AppColors.success
                          : service.color),
                ),
                Icon(Icons.chevron_right,
                    color: AppTheme.textSecondaryOf(context), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceDetailSheet extends StatelessWidget {
  final _ServiceItem service;
  final String title;
  final AppLocalizations l10n;

  const _ServiceDetailSheet(
      {required this.service, required this.title, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(service.icon, color: service.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context))),
              ),
            ]),
            const SizedBox(height: 20),
            _detailRow(context, Icons.access_time, 'Timings', service.timing),
            _detailRow(context, Icons.location_on, 'Location', service.location),
            _detailRow(context, Icons.card_giftcard, 'Prasadam', service.prasadam),
            _detailRow(context, Icons.checklist, 'What to bring', service.items),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bookmark_add),
                label: Text(service.fee == 0
                    ? 'Register (Free)'
                    : 'Book Service  •  ₹${service.fee.toInt()}'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: service.color),
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  final user = auth.currentUser;
                  final provider = context.read<UserActivityProvider>();
                  final now = DateTime.now();
                  final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  final slot = service.timing.split('&').first.trim();

                  void generateAndShowPass() {
                    final bookingId = UserActivityProvider.generateBookingId('SRV');
                    final tickets = UserActivityProvider.generateTickets(
                      bookingId: bookingId,
                      count: 1,
                      type: 'SRV',
                      slot: slot,
                      date: date,
                    );
                    final booking = DarshanBooking(
                      bookingId: bookingId,
                      darshanType: title,
                      slotTime: slot,
                      totalAmount: service.fee,
                      ticketCount: 1,
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
                      slotTime: slot,
                      date: date,
                      bookingId: bookingId,
                      darshanType: title,
                    );
                  }

                  if (service.fee == 0) {
                    Navigator.pop(context);
                    generateAndShowPass();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$title registered successfully 🙏'),
                      backgroundColor: AppColors.success,
                    ));
                    return;
                  }

                  Navigator.pop(context);
                  CashfreePaymentService.instance.startPayment(
                    context: context,
                    amount: service.fee,
                    description: title,
                    customerId: user != null && user.id.isNotEmpty
                        ? user.id
                        : 'devotee_${DateTime.now().millisecondsSinceEpoch}',
                    customerName: user != null && user.name.isNotEmpty ? user.name : 'Devotee',
                    customerEmail: user != null && user.email.isNotEmpty ? user.email : 'devotee@sannidhi.app',
                    customerPhone: user != null && user.phone.isNotEmpty ? user.phone : '9999999999',
                  ).then((result) {
                    if (!context.mounted) return;
                    if (result.result == CashfreePaymentResult.success) {
                      generateAndShowPass();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$title booked successfully 🙏'),
                        backgroundColor: AppColors.success,
                      ));
                    } else if (result.result == CashfreePaymentResult.failure) {
                      showCashfreePaymentFailureDialog(
                        context: context,
                        message: result.message,
                        onRetry: () => CashfreePaymentService.instance.startPayment(
                          context: context,
                          amount: service.fee,
                          description: title,
                          customerId: user != null && user.id.isNotEmpty
                              ? user.id
                              : 'devotee_${DateTime.now().millisecondsSinceEpoch}',
                          customerName: user != null && user.name.isNotEmpty ? user.name : 'Devotee',
                          customerEmail: user != null && user.email.isNotEmpty ? user.email : 'devotee@sannidhi.app',
                          customerPhone: user != null && user.phone.isNotEmpty ? user.phone : '9999999999',
                        ),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: service.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryOf(context))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textPrimaryOf(context))),
                ],
              ),
            ),
          ],
        ),
      );
}
