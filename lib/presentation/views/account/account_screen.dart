import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/devotee_avatar.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/widgets/ticket_carousel_modal.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../../../services/tax_receipt_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../facility/facility_locator_screen.dart';
import '../staff/gate_staff_screen.dart';

class AccountScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;
  const AccountScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final activity = context.watch<UserActivityProvider>();
    final access = context.watch<AccessibilityProvider>();
    final auth = context.watch<AuthProvider>();
    final passCount = activity.activeShuttleBookings.length + activity.darshanBookings.length;

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 110),
        children: [
          _ProfileCard(
            passCount: activity.activePassCount,
            totalDonated: activity.totalDonated,
            isTamil: isTamil,
            auth: auth,
          ),
          const SizedBox(height: 20),

          // Role-based Access Section for Staff and Admin
          if (auth.isStaff || auth.isAdmin) ...[
            _sectionHeader(isTamil ? 'அதிகாரப்பூர்வ நிர்வாக அணுகல்' : 'Staff & Admin Management'),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.qr_code_scanner,
              color: const Color(0xFFD97706),
              title: isTamil ? 'வாயில் பாஸ் சரிபார்ப்பு' : 'Gate Pass Verifier (Staff/Admin)',
              subtitle: isTamil
                  ? 'பக்தர்களின் நுழைவு பாஸ்களை சரிபார்த்து உறுதிப்படுத்து'
                  : 'Scan & verify devotee boarding and darshan passes',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GateStaffScreen(onToggleLocale: onToggleLocale)),
              ),
            ),
            if (auth.isAdmin)
              _ActionTile(
                icon: Icons.admin_panel_settings,
                color: AppTheme.primaryColor,
                title: isTamil ? 'கோயில் நிர்வாக டாஷ்போர்டு' : 'Temple Admin Dashboard (Admin)',
                subtitle: isTamil
                    ? 'நேரடி டிக்கெட் எண்ணிக்கைகள், வருவாய் மற்றும் புள்ளிவிவரங்கள்'
                    : 'Real-time ticket counts, footfall, and revenue analytics',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminDashboardScreen(onToggleLocale: onToggleLocale)),
                ),
              ),
            const SizedBox(height: 20),
          ],

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
            icon: Icons.map,
            color: const Color(0xFF0288D1),
            title: isTamil ? 'கோயில் வசதிகள் வழிகாட்டி' : 'Temple Facilities Locator',
            subtitle: isTamil
                ? 'குடிநீர், அன்னதானம், மருத்துவம், கழிப்பறைகள்'
                : 'Drinking water, dining hall, medical post, amenities',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FacilityLocatorScreen(onToggleLocale: onToggleLocale),
              ),
            ),
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

          // Login or Logout
          if (auth.isAuthenticated) ...[
            _ActionTile(
              icon: Icons.switch_account,
              color: const Color(0xFFD97706),
              title: isTamil ? 'கணக்கை மாற்று / உள்நுழைவு வகை' : 'Switch Account / Change Role',
              subtitle: isTamil
                  ? 'பக்தர், வாயில் ஊழியர் அல்லது நிர்வாகியாக உள்நுழைக'
                  : 'Switch between Devotee, Gate Staff, or Admin',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(onToggleLocale: onToggleLocale),
                ),
              ),
            ),
            _ActionTile(
              icon: Icons.logout,
              color: AppColors.error,
              title: isTamil ? 'வெளியேறுக' : 'Sign Out',
              subtitle: '${auth.currentUser?.email}',
              onTap: () {
                auth.logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isTamil ? 'வெளியேறியாயிற்று' : 'Signed out successfully'),
                    backgroundColor: AppTheme.primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(onToggleLocale: onToggleLocale),
                  ),
                );
              },
            ),
          ] else
            _ActionTile(
              icon: Icons.login,
              color: AppTheme.primaryColor,
              title: isTamil ? 'உள்நுழைக / பதிவு செய்க' : 'Sign In / Register',
              subtitle: isTamil
                  ? 'பாஸ்கள் மற்றும் ரசீதுகளை ஒத்திசைக்க'
                  : 'Sign in to access tickets, receipts, or staff tools',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(onToggleLocale: onToggleLocale),
                ),
              ),
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

  Widget _sectionHeader(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      );

  void _showPasses(BuildContext context, UserActivityProvider activity, bool isTamil) {
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
            Text(
              isTamil ? 'செயலிலுள்ள பாஸ்கள்' : 'Active Passes',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (activity.activeShuttleBookings.isEmpty && activity.darshanBookings.isEmpty)
              Center(
                child: Text(
                  isTamil ? 'செயலிலுள்ள பாஸ் இல்லை' : 'No active passes',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else ...[
              ...activity.activeShuttleBookings.map((b) => ListTile(
                    leading: Stack(
                      children: [
                        Icon(Icons.directions_bus,
                            color: b.isAllUsed ? const Color(0xFF16A34A) : AppColors.templeMaroon),
                        if (b.isAllUsed)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 7, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Text(isTamil ? 'சட்டில் பஸ் — ${b.slotTime}' : 'Shuttle — ${b.slotTime}'),
                    subtitle: Text(b.isAllUsed
                        ? (isTamil ? '✓ அனுமதிக்கப்பட்டது • ${b.date}' : '✓ Admitted at Gate • ${b.date}')
                        : (b.isExpired
                            ? (isTamil ? '⚠️ காலாவதியானது • ${b.date}' : '⚠️ Expired • ${b.date}')
                            : (isTamil ? '${b.seatCount} இருக்கை  •  ${b.date}' : '${b.seatCount} seat(s)  •  ${b.date}'))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (b.isAllUsed)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('USED',
                                style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          )
                        else if (b.isExpired)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isTamil ? 'காலாவதி' : 'EXPIRED',
                                style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        Icon(Icons.qr_code_2,
                            color: b.isAllUsed
                                ? const Color(0xFF16A34A)
                                : (b.isExpired ? const Color(0xFFDC2626) : AppColors.templeMaroon)),
                      ],
                    ),
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
                    leading: Stack(
                      children: [
                        Icon(Icons.visibility,
                            color: b.isAllUsed
                                ? const Color(0xFF16A34A)
                                : (b.isExpired ? const Color(0xFFDC2626) : AppColors.deepSaffron)),
                        if (b.isAllUsed)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 7, color: Colors.white),
                            ),
                          )
                        else if (b.isExpired)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.timer_off_rounded, size: 7, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    title: Text('${b.darshanType} — ${b.slotTime}'),
                    subtitle: Text(b.isAllUsed
                        ? (isTamil ? '✓ அனுமதிக்கப்பட்டது • ${b.date}' : '✓ Admitted at Gate • ${b.date}')
                        : (b.isExpired
                            ? (isTamil ? '⚠️ காலாவதியானது • ${b.date}' : '⚠️ Expired • ${b.date}')
                            : (isTamil ? '${b.ticketCount} பக்தர்  •  ${b.date}' : '${b.ticketCount} devotee(s)  •  ${b.date}'))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (b.isAllUsed)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('USED',
                                style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          )
                        else if (b.isExpired)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(isTamil ? 'காலாவதி' : 'EXPIRED',
                                style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800)),
                          ),
                        Icon(Icons.qr_code_2,
                            color: b.isAllUsed
                                ? const Color(0xFF16A34A)
                                : (b.isExpired ? const Color(0xFFDC2626) : AppColors.deepSaffron)),
                      ],
                    ),
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
            Text(
              isTamil ? '80G தான ரசீதுகள்' : '80G Donation Receipts',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (activity.donations.isEmpty)
              Center(
                child: Text(
                  isTamil ? 'இதுவரை தானம் இல்லை' : 'No donations yet',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              ...activity.donations.map((d) => ListTile(
                    leading: const Icon(Icons.receipt_long, color: AppColors.success),
                    title: Text('₹${d.amount} — ${d.cause}'),
                    subtitle: Text(d.dateStr),
                    trailing: IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                      onPressed: () => TaxReceiptService.instance.print80gReceipt(context, d),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final int passCount;
  final int totalDonated;
  final bool isTamil;
  final AuthProvider auth;

  const _ProfileCard({
    required this.passCount,
    required this.totalDonated,
    required this.isTamil,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final isAuth = auth.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x22800000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          if (auth.isAdmin || auth.isStaff)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                auth.isAdmin ? Icons.admin_panel_settings : Icons.badge,
                color: Colors.white,
                size: 32,
              ),
            )
          else
            FutureBuilder<Map<String, String?>>(
              future: DevoteeAvatar.getSavedProfile(),
              builder: (context, snapshot) {
                final photo = snapshot.data?['photoPath'];
                final avatar = snapshot.data?['avatarId'] ?? 'vel';
                return DevoteeAvatar(
                  size: 60,
                  photoPath: photo,
                  avatarId: avatar,
                  showBorder: true,
                  borderColor: AppColors.goldAccent,
                );
              },
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuth ? (user?.name ?? 'Devotee') : (isTamil ? 'விருந்தினர் பக்தர்' : 'Guest Pilgrim'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: auth.isAdmin
                            ? const Color(0xFFD97706)
                            : (auth.isStaff ? const Color(0xFF2563EB) : AppTheme.accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isAuth
                            ? (isTamil ? user!.role.displayNameTamil : user!.role.displayName)
                            : (isTamil ? 'விருந்தினர்' : 'Guest'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isAuth && user?.phone.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+91 ${user!.phone}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _stat('$passCount', isTamil ? 'பாஸ்கள்' : 'Passes'),
                    const SizedBox(width: 20),
                    _stat('₹$totalDonated', isTamil ? 'தானம்' : 'Donated'),
                  ],
                ),
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      );
}

// ── Action Tile ──────────────────────────────────────────────────────────────

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
    return BouncingScaleTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Contact Tile ─────────────────────────────────────────────────────────────

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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryOf(context),
              ),
            ),
          ),
          Text(
            phone,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.deepSaffron,
            ),
          ),
        ],
      ),
    );
  }
}
