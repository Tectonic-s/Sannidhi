import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../services/tax_receipt_service.dart';

class AccountScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const AccountScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activity = context.watch<UserActivityProvider>();
    final access = context.watch<AccessibilityProvider>();

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(
            passCount: activity.activePassCount,
            totalDonated: activity.totalDonated,
          ),
          const SizedBox(height: 20),
          _sectionHeader('Quick Actions'),
          const SizedBox(height: 10),
          _ActionTile(
            icon: Icons.qr_code_2,
            color: AppColors.info,
            title: 'My Active QR Passes',
            subtitle: '${activity.activePassCount} active pass(es)',
            onTap: () => _showPasses(context, activity, l10n),
          ),
          _ActionTile(
            icon: Icons.receipt_long,
            color: AppColors.success,
            title: 'Donation Tax (80G) Certificates',
            subtitle: '${activity.donations.length} receipt(s)',
            onTap: () => _show80g(context, activity),
          ),
          _ActionTile(
            icon: Icons.accessibility_new,
            color: const Color(0xFFD97706),
            title: 'Elderly High-Contrast Mode',
            subtitle: access.isElderlyMode ? 'Enabled' : 'Disabled',
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
            subtitle: l10n.currentLocale == 'ta' ? 'தமிழ்' : 'English',
            onTap: onToggleLocale,
          ),
          const SizedBox(height: 20),
          _sectionHeader('Emergency Contacts'),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.local_police,
            color: AppColors.error,
            title: 'Devasthanam Police',
            phone: '0422-2690100',
          ),
          _ContactTile(
            icon: Icons.local_hospital,
            color: const Color(0xFFC62828),
            title: 'Temple First-Aid Post',
            phone: '0422-2690200',
          ),
          _ContactTile(
            icon: Icons.support_agent,
            color: AppColors.info,
            title: 'Pilgrim Helpdesk',
            phone: '1800-425-0101',
          ),
          _ContactTile(
            icon: Icons.fire_truck,
            color: AppColors.warning,
            title: 'Fire & Rescue',
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
      AppLocalizations l10n) {
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
            const Text('Active Passes',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (activity.activeShuttleTickets.isEmpty &&
                activity.darshanTickets.isEmpty)
              const Center(
                  child: Text('No active passes',
                      style: TextStyle(color: AppTheme.textSecondary)))
            else ...[
              ...activity.activeShuttleTickets.map((t) => ListTile(
                    leading: const Icon(Icons.directions_bus,
                        color: AppColors.info),
                    title: Text(t.ticketId),
                    subtitle: Text('${t.slot} • ${t.seatCount} seat(s)'),
                  )),
              ...activity.darshanTickets.map((t) => ListTile(
                    leading: const Icon(Icons.visibility,
                        color: AppColors.deepSaffron),
                    title: Text(t.darshanType),
                    subtitle: Text('${t.slot} • ${t.date}'),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _show80g(BuildContext context, UserActivityProvider activity) {
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
            const Text('80G Donation Receipts',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (activity.donations.isEmpty)
              const Center(
                  child: Text('No donations yet',
                      style: TextStyle(color: AppTheme.textSecondary)))
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
  const _ProfileCard({required this.passCount, required this.totalDonated});

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
                  child: const Text('Devotee',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _stat('$passCount', 'Passes'),
                  const SizedBox(width: 20),
                  _stat('₹$totalDonated', 'Donated'),
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
