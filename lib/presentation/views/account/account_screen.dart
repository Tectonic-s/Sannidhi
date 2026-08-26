import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/ticket_carousel_modal.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../services/tax_receipt_service.dart';

class AccountScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const AccountScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final activity = context.watch<UserActivityProvider>();
    final access = context.watch<AccessibilityProvider>();
    final passCount = activity.activeShuttleBookings.length + activity.darshanBookings.length;

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(
            passCount: activity.activePassCount,
            totalDonated: activity.totalDonated,
            isTamil: isTamil,
          ),
          const SizedBox(height: 20),
          _sectionHeader(isTamil ? 'விரைவு செயல்கள்' : 'Quick Actions'),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.qr_code_2,
            color: AppColors.info,
            title: isTamil ? 'என் செயலிலுள்ள QR பாஸ்கள்' : 'My Active QR Passes',
            subtitle: isTamil ? '$passCount பாஸ் உள்ளது' : '$passCount active pass(es)',
            onTap: () => _showPasses(context, activity, isTamil),
          ),
          _ActionTile(
            icon: Icons.receipt_long,
            color: AppColors.success,
            title: isTamil ? 'தான வரி சான்றிதழ் (80G)' : 'Donation Tax (80G) Certificates',
            subtitle: isTamil ? '${activity.donations.length} ரசீது' : '${activity.donations.length} receipt(s)',
            onTap: () => _show80g(context, activity, isTamil),
          ),
          _ActionTile(
            icon: Icons.accessibility_new,
            color: const Color(0xFFD97706),
            title: isTamil ? 'மூத்தோர் உயர் தெளிவு மோட்' : 'Elderly High-Contrast Mode',
            subtitle: access.isElderlyMode
                ? (isTamil ? 'இயங்குகிறது' : 'Enabled')
                : (isTamil ? 'இயங்கவில்லை' : 'Disabled'),
            trailing: Switch(
              value: access.isElderlyMode,
              onChanged: (_) => access.toggle(),
              activeThumbColor: const Color(0xFFD97706),
            ),
            onTap: () => access.toggle(),
          ),
          _ActionTile(
            icon: Icons.language,
            color: AppTheme.primaryColor,
            title: 'Language / மொழி',
            subtitle: isTamil ? 'தமிழ்' : 'English',
            onTap: onToggleLocale,
          ),
          const SizedBox(height: 20),
          _sectionHeader(isTamil ? 'அவசர தொடர்புகள்' : 'Emergency Contacts'),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.local_police,
            color: AppColors.error,
            title: isTamil ? 'தேவஸ்தானம் காவல்' : 'Devasthanam Police',
            phone: '0422-2690100',
          ),
          _ContactTile(
            icon: Icons.local_hospital,
            color: const Color(0xFFC62828),
            title: isTamil ? 'கோயில் முதலளவு சிகிச்சை' : 'Temple First-Aid Post',
            phone: '0422-2690200',
          ),
          _ContactTile(
            icon: Icons.support_agent,
            color: AppColors.info,
            title: isTamil ? 'யாத்ரிகர் உதவி மையம்' : 'Pilgrim Helpdesk',
            phone: '1800-425-0101',
          ),
          _ContactTile(
            icon: Icons.fire_truck,
            color: AppColors.warning,
            title: isTamil ? 'தீயணைப்பு & காப்பு' : 'Fire & Rescue',
            phone: '101',
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  void _showPasses(BuildContext context, UserActivityProvider activity,
      bool isTamil) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(16),
          children: [
            Text(isTamil ? 'செயலிலுள்ள பாஸ்கள்' : 'Active Passes',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (activity.activeShuttleBookings.isEmpty &&
                activity.darshanBookings.isEmpty)
              Center(
                  child: Text(
                      isTamil ? 'செயலிலுள்ள பாஸ் இல்லை' : 'No active passes',
                      style: const TextStyle(color: AppTheme.textSecondary)))
            else ...[
              ...activity.activeShuttleBookings.map((b) => ListTile(
                    leading: const Icon(Icons.directions_bus,
                        color: AppColors.info),
                    title: Text(isTamil
                        ? 'சட்டில் பஸ் — ${b.slotTime}'
                        : 'Shuttle — ${b.slotTime}'),
                    subtitle: Text(isTamil
                        ? '${b.seatCount} இருக்கை  •  ${b.date}'
                        : '${b.seatCount} seat(s)  •  ${b.date}'),
                    trailing: const Icon(Icons.qr_code_2,
                        color: AppColors.info),
                    onTap: () {
                      Navigator.pop(context);
                      showTicketCarousel(
                        context: context,
                        tickets: b.tickets,
                        type: TicketCarouselType.shuttle,
                        slotTime: b.slotTime,
                        date: b.date,
                        bookingId: b.bookingId,
                        pickupLocation: 'Adivaram Bus Stand',
                        dropLocation: 'Hilltop Sannidhi',
                      );
                    },
                  )),
              ...activity.darshanBookings.map((b) => ListTile(
                    leading: const Icon(Icons.visibility,
                        color: AppColors.deepSaffron),
                    title: Text('${b.darshanType} — ${b.slotTime}'),
                    subtitle: Text(isTamil
                        ? '${b.ticketCount} பக்தர்  •  ${b.date}'
                        : '${b.ticketCount} devotee(s)  •  ${b.date}'),
                    trailing: const Icon(Icons.qr_code_2,
                        color: AppColors.deepSaffron),
                    onTap: () {
                      Navigator.pop(context);
                      showTicketCarousel(
                        context: context,
                        tickets: b.tickets,
                        type: TicketCarouselType.darshan,
                        slotTime: b.slotTime,
                        date: b.date,
                        bookingId: b.bookingId,
                        darshanType: b.darshanType,
                      );
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _show80g(BuildContext context, UserActivityProvider activity, bool isTamil) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(16),
          children: [
            Text(isTamil ? '80G தான ரசீதுகள்' : '80G Donation Receipts',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (activity.donations.isEmpty)
              Center(
                  child: Text(
                      isTamil ? 'இதுவரை தானம் இல்லை' : 'No donations yet',
                      style: const TextStyle(color: AppTheme.textSecondary)))
            else
              ...activity.donations.map((d) => ListTile(
                    leading: const Icon(Icons.receipt_long,
                        color: AppColors.success),
                    title: Text('₹${d.amount} — ${d.cause}'),
                    subtitle: Text(d.dateStr),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf,
                          color: AppTheme.primaryColor),
                      onPressed: () => TaxReceiptService.instance
                          .print80gReceipt(context, d),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final int passCount;
  final int totalDonated;
  final bool isTamil;
  const _ProfileCard({required this.passCount, required this.totalDonated, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilgrim',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(isTamil ? 'பக்தர்' : 'Devotee',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _stat('$passCount', isTamil ? 'பாஸ்கள்' : 'Passes'),
                  const SizedBox(width: 20),
                  _stat('₹$totalDonated', isTamil ? 'தானம்' : 'Donated'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right,
                    color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String phone;

  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(phone,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.info,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.call, color: color, size: 22),
        ],
      ),
    );
  }
}
