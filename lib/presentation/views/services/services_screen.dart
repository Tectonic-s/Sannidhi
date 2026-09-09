import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/services/cashfree_payment_service.dart';
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = _services[i];
          final title = isTamil
              ? s.tamilTitle
              : (l10n.translate(s.titleKey) ?? s.titleKey);
          final desc = l10n.translate(s.descKey) ?? s.descKey;
          return _ServiceCard(
            service: s,
            title: title,
            desc: desc,
            onTap: () => _showDetail(context, s, title, l10n),
          );
        },
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  service.fee == 0 ? 'Free' : '₹${service.fee.toInt()}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: service.fee == 0
                          ? AppColors.success
                          : service.color),
                ),
                const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 20),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: Colors.grey.shade300,
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
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ),
            ]),
            const SizedBox(height: 20),
            _detailRow(Icons.access_time, 'Timings', service.timing),
            _detailRow(Icons.location_on, 'Location', service.location),
            _detailRow(Icons.card_giftcard, 'Prasadam', service.prasadam),
            _detailRow(Icons.checklist, 'What to bring', service.items),
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
                  if (service.fee == 0) {
                    Navigator.pop(context);
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
                    customerId: 'devotee_${DateTime.now().millisecondsSinceEpoch}',
                    customerName: 'Devotee',
                    customerEmail: 'devotee@sannidhi.app',
                    customerPhone: '9999999999',
                  ).then((result) {
                    if (!context.mounted) return;
                    if (result.result == CashfreePaymentResult.success) {
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
                          customerId: 'devotee_${DateTime.now().millisecondsSinceEpoch}',
                          customerName: 'Devotee',
                          customerEmail: 'devotee@sannidhi.app',
                          customerPhone: '9999999999',
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

  Widget _detailRow(IconData icon, String label, String value) => Padding(
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
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      );
}
