import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/devotee_avatar.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/widgets/ticket_carousel_modal.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_activity_provider.dart';
import '../account/account_screen.dart';
import '../donation/donation_screen.dart';
import '../facility/facility_locator_screen.dart';
import '../services/services_screen.dart';

class MoreScreen extends StatelessWidget {
  final VoidCallback onToggleLocale;

  const MoreScreen({super.key, required this.onToggleLocale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final access = Provider.of<AccessibilityProvider>(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final activity = context.watch<UserActivityProvider>();
    final passCount =
        activity.activeShuttleBookings.length + activity.darshanBookings.length;

    return Scaffold(
      appBar: CustomAppBar(onToggleLocale: onToggleLocale),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          // 1. Devotee Profile & Account Card
          _buildProfileCard(context, auth, user, isTamil, access.isElderlyMode),
          const SizedBox(height: 16),

          // 2. Quick Active Passes Access
          if (auth.isAuthenticated && passCount > 0) ...[
            _buildActivePassesCard(
                context, activity, passCount, isTamil, access.isElderlyMode),
            const SizedBox(height: 16),
          ],

          // 3. Temple Services & Sevas Section
          _buildSectionHeader(
              isTamil ? 'சேவைகள் & வசதிகள்' : 'Services & Facilities',
              isTamil ? 'அனைத்தும் ஒரே இடத்தில்' : 'All in one place'),
          const SizedBox(height: 10),
          _buildActionTile(
            context: context,
            icon: Icons.spa,
            color: const Color(0xFFB45309),
            title: isTamil ? 'சிறப்பு பூஜைகள் & அர்ச்சனை' : 'Special Poojas & Sevas',
            subtitle: isTamil
                ? 'அபிஷேகம், அர்ச்சனை & குகை தரிசனம்'
                : 'Abhishekam, Archana & Cave visits',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServicesScreen(onToggleLocale: onToggleLocale),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            context: context,
            icon: Icons.map,
            color: const Color(0xFF0288D1),
            title: isTamil
                ? 'கோவில் வசதிகள் & வரைபடம்'
                : 'Facility & Parking Locator',
            subtitle: isTamil
                ? 'குடிநீர், கழிப்பறை & வாகனம் நிறுத்துமிடம்'
                : 'Water, restrooms, medical post & parking',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    FacilityLocatorScreen(onToggleLocale: onToggleLocale),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            context: context,
            icon: Icons.volunteer_activism,
            color: const Color(0xFFB91C1C),
            title: isTamil ? 'மின்னணு உண்டியல் & காணிக்கை' : 'E-Undiyal & Donations',
            subtitle: isTamil
                ? '80G வரி விலக்கு சான்றிதழ் ரசீதுடன்'
                : 'With instant 80G tax exemption receipts',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DonationScreen(onToggleLocale: onToggleLocale),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Language & Accessibility Settings
          _buildSectionHeader(
              isTamil ? 'மொழி, தீம் & பார்வை அமைப்புகள்' : 'Language, Theme & Accessibility',
              isTamil ? 'உங்கள் விருப்பத்திற்கேற்ப மாற்றவும்' : 'Customize your preferred view'),
          const SizedBox(height: 10),
          _buildThemeModeTile(context, access, isTamil),
          const SizedBox(height: 10),
          _buildLanguageTile(
            context: context,
            isTamil: isTamil,
            onToggle: onToggleLocale,
          ),
          const SizedBox(height: 10),
          _buildAccessibilityTile(context, access, isTamil),
          const SizedBox(height: 10),
          _buildBackendConfigTile(context, isTamil),
          const SizedBox(height: 20),

          // 5. Pilgrim Helpline & Emergency Assistance
          _buildSectionHeader(
              isTamil ? 'யாத்ரிகர் உதவி & அவசர எண்கள்' : 'Pilgrim Help & Helpline',
              isTamil ? '24 மணி நேர உதவி' : '24x7 Direct Temple Support'),
          const SizedBox(height: 10),
          _buildContactTile(
            context: context,
            icon: Icons.support_agent,
            color: AppColors.templeMaroon,
            title: isTamil ? 'யாத்ரிகர் உதவி மையம்' : 'Pilgrim Helpdesk (Toll Free)',
            phone: '1800-425-0101',
          ),
          const SizedBox(height: 8),
          _buildContactTile(
            context: context,
            icon: Icons.medical_services,
            color: const Color(0xFFC62828),
            title: isTamil ? 'முதலளவு சிகிச்சை மையம்' : 'Temple First-Aid Post',
            phone: '0422-2690200',
          ),
          const SizedBox(height: 8),
          _buildContactTile(
            context: context,
            icon: Icons.emergency,
            color: const Color(0xFF15803D),
            title: isTamil ? 'அவசர ஆம்புலன்ஸ்' : 'Emergency Ambulance',
            phone: '108',
          ),
          const SizedBox(height: 24),

          // 6. Respectful Temple Footer
          Center(
            child: Column(
              children: [
                Text(
                  isTamil
                      ? 'அருள்மிகு சந்நிதி திருக்கோவில் தேவஸ்தானம்'
                      : 'Arulmigu Sannidhi Temple Devasthanam',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isTamil
                      ? 'பதிப்பு 2.5.0 • அனைவருக்குமான எளிய தளம்'
                      : 'Version 2.5.0 • Accessible Digital Portal',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryOf(context),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthProvider auth,
      dynamic user, bool isTamil, bool isElderly) {
    return Container(
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (auth.isAdmin || auth.isStaff)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                auth.isAdmin ? Icons.admin_panel_settings : Icons.badge,
                color: Colors.white,
                size: 28,
              ),
            )
          else
            FutureBuilder<Map<String, String?>>(
              future: DevoteeAvatar.getSavedProfile(),
              builder: (context, snapshot) {
                final photo = snapshot.data?['photoPath'];
                final avatar = snapshot.data?['avatarId'] ?? 'vel';
                return DevoteeAvatar(
                  size: 52,
                  photoPath: photo,
                  avatarId: avatar,
                  showBorder: true,
                  borderColor: AppColors.goldAccent,
                );
              },
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.isAuthenticated
                      ? (user?.name ?? 'Devotee')
                      : (isTamil ? 'வணக்கம், பக்தரே 🙏' : 'Vanakkam, Devotee 🙏'),
                  style: TextStyle(
                    fontSize: isElderly ? 18 : 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  auth.isAuthenticated
                      ? (user?.phone ?? 'Signed In')
                      : (isTamil
                          ? 'முன்பதிவு செய்ய உள்நுழையவும்'
                          : 'Sign in to access bookings'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFDE68A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AccountScreen(onToggleLocale: onToggleLocale),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              auth.isAuthenticated
                  ? (isTamil ? 'விவரம்' : 'Account')
                  : (isTamil ? 'உள்நுழை' : 'Sign In'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePassesCard(BuildContext context,
      UserActivityProvider activity, int count, bool isTamil, bool isElderly) {
    return InkWell(
      onTap: () {
        if (activity.activeShuttleBookings.isNotEmpty) {
          final b = activity.activeShuttleBookings.first;
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
        } else if (activity.darshanBookings.isNotEmpty) {
          final b = activity.darshanBookings.first;
          showTicketCarousel(
            context: context,
            tickets: b.tickets,
            type: TicketCarouselType.darshan,
            slotTime: b.slotTime,
            date: b.date,
            bookingId: b.bookingId,
            darshanType: b.darshanType,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Builder(builder: (context) {
        final isDark = AppTheme.isDark(context);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0C05) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3F2606) : const Color(0xFFFDE68A),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_2,
                    color: AppColors.goldAccent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTamil
                          ? 'செயலிலுள்ள QR பாஸ்கள் ($count)'
                          : 'Active QR Passes ($count)',
                      style: TextStyle(
                        fontSize: isElderly ? 16 : 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTamil
                          ? 'வரிசை வாயிலில் காட்ட தட்டவும்'
                          : 'Tap to display barcode & entry QR pass',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textSecondaryOf(context)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title - $subtitle',
      child: BouncingScaleTap(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 15, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required bool isTamil,
    required VoidCallback onToggle,
  }) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.deepSaffron.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.translate_rounded,
                  color: AppColors.deepSaffron, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTamil ? 'செயலி மொழி (Language)' : 'App Language (மொழி)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTamil
                        ? 'தற்போது: தமிழ் • மாற்ற தட்டவும்'
                        : 'Current: English • Tap to switch',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            // Segmented pill indicator
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isTamil ? AppColors.templeMaroon : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'தமிழ்',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isTamil
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: !isTamil ? AppColors.templeMaroon : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ENG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: !isTamil
                            ? Colors.white
                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeTile(
      BuildContext context, AccessibilityProvider access, bool isTamil) {
    final mode = access.themeMode;
    String modeLabel;
    if (mode == ThemeMode.light) {
      modeLabel = isTamil ? 'பகல் முறை (Light)' : 'Light Mode';
    } else if (mode == ThemeMode.dark) {
      modeLabel = isTamil ? 'இரவு முறை (Dark)' : 'Dark Mode';
    } else {
      modeLabel = isTamil ? 'கணினி இயல்பு (System)' : 'System Default';
    }

    Widget themePill({
      required String label,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.templeMaroon : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4B5563).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.palette_outlined,
                color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF374151), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil ? 'செயலி தோற்றம் (Theme)' : 'Display Theme',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  modeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          // 3-way Segmented Selector
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                themePill(
                  label: isTamil ? 'இயல்பு' : 'Auto',
                  icon: Icons.brightness_auto,
                  isSelected: mode == ThemeMode.system,
                  onTap: () => access.setThemeMode(ThemeMode.system),
                ),
                themePill(
                  label: isTamil ? 'பகல்' : 'Light',
                  icon: Icons.wb_sunny_rounded,
                  isSelected: mode == ThemeMode.light,
                  onTap: () => access.setThemeMode(ThemeMode.light),
                ),
                themePill(
                  label: isTamil ? 'இரவு' : 'Dark',
                  icon: Icons.nightlight_round,
                  isSelected: mode == ThemeMode.dark,
                  onTap: () => access.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityTile(
      BuildContext context, AccessibilityProvider access, bool isTamil) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: access.isElderlyMode
              ? AppTheme.accentColor
              : AppTheme.borderColor(context),
          width: access.isElderlyMode ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.accessibility_new,
                color: AppTheme.accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTamil
                      ? 'முதியோர் பார்வை முறை (A+ பெரிய எழுத்து)'
                      : 'Elderly Friendly Mode (Large Text)',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTamil
                      ? 'பெரிய எழுத்துரு & அதிக தொடு பரப்பளவு'
                      : 'Larger text, high contrast & comfortable buttons',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: access.isElderlyMode,
            activeThumbColor: AppTheme.accentColor,
            onChanged: (val) {
              access.toggle();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String phone,
  }) {
    Future<void> makeCall() async {
      final Uri uri =
          Uri.parse('tel:${phone.replaceAll('-', '').replaceAll(' ', '')}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (_) {}
    }

    return InkWell(
      onTap: makeCall,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryOf(context),
                    ),
                  ),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: AppColors.success),
              onPressed: makeCall,
              tooltip: 'Call $phone',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendConfigTile(BuildContext context, bool isTamil) {
    final auth = context.watch<AuthProvider>();
    final currentUrl = AuthProvider.backendUrl;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.dns_rounded, color: Color(0xFF0284C7), size: 22),
        ),
        title: Text(
          isTamil ? 'பின்னணி API சேவையக இணைப்பு' : 'Backend API Server URL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryOf(context),
          ),
        ),
        subtitle: Text(
          currentUrl,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0284C7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.edit_outlined, size: 20),
        onTap: () => _showEditBackendUrlDialog(context, auth, currentUrl, isTamil),
      ),
    );
  }

  void _showEditBackendUrlDialog(
    BuildContext context,
    AuthProvider auth,
    String currentUrl,
    bool isTamil,
  ) {
    final controller = TextEditingController(text: currentUrl);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.dns_rounded, color: Color(0xFF0284C7)),
            const SizedBox(width: 8),
            Text(
              isTamil ? 'API முகவரியை மாற்றவும்' : 'Edit Backend Server URL',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTamil
                  ? 'உங்கள் கணினியின் தற்போதைய IP முகவரியை உள்ளிடவும் (எ.கா: http://192.168.1.3:3000):'
                  : 'Enter the backend IP/host (e.g. http://192.168.1.3:3000):',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.3:3000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.link, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(isTamil ? 'ரத்து' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await auth.setBackendUrl(newUrl);
                if (context.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTamil ? 'சேவையக முகவரி புதுப்பிக்கப்பட்டது' : 'Backend URL updated to $newUrl',
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              }
            },
            child: Text(isTamil ? 'சேமி' : 'Save'),
          ),
        ],
      ),
    );
  }
}
