import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/devotee_avatar.dart';
import '../../../core/widgets/sannidhi_logo.dart';
import '../../../providers/accessibility_provider.dart';
import '../role_router_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  final ValueChanged<String>? onSetLocale;

  const OnboardingScreen({
    super.key,
    required this.onToggleLocale,
    this.onSetLocale,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Language defaults to English or device locale if Tamil
  late String _selectedLang;
  bool _isElderly = false;
  ThemeMode _selectedTheme = ThemeMode.system;
  String _selectedAvatarId = 'vel';
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _selectedLang = deviceLang == 'ta' ? 'ta' : 'en';
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final access = Provider.of<AccessibilityProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isElderly = access.isElderlyMode;
      _selectedTheme = access.currentThemeMode;
      _profilePhotoPath = prefs.getString('user_profile_photo_path');
      _selectedAvatarId = prefs.getString('user_profile_avatar_id') ?? 'vel';
    });
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedLang = code;
    });
    widget.onSetLocale?.call(code);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('preferred_language', code);
    });
  }

  void _selectTheme(ThemeMode mode) {
    setState(() {
      _selectedTheme = mode;
    });
    final access = Provider.of<AccessibilityProvider>(context, listen: false);
    access.setThemeMode(mode);
  }

  void _toggleElderly(bool val) {
    setState(() {
      _isElderly = val;
    });
    final access = Provider.of<AccessibilityProvider>(context, listen: false);
    if (access.isElderlyMode != val) {
      access.toggle();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('preferred_language', _selectedLang);
    await prefs.setBool('preferred_elderly_mode', _isElderly);
    if (_profilePhotoPath != null) {
      await prefs.setString('user_profile_photo_path', _profilePhotoPath!);
    }
    await prefs.setString('user_profile_avatar_id', _selectedAvatarId);

    if (!mounted) return;

    final access = Provider.of<AccessibilityProvider>(context, listen: false);
    if (access.isElderlyMode != _isElderly) {
      access.toggle();
    }
    if (access.currentThemeMode != _selectedTheme) {
      await access.setThemeMode(_selectedTheme);
    }

    widget.onSetLocale?.call(_selectedLang);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RoleRouterScreen(onToggleLocale: widget.onToggleLocale),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _profilePhotoPath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLang == 'ta'
                  ? 'புகைப்படத்தை தேர்ந்தெடுக்க முடியவில்லை: $e'
                  : 'Unable to select photo: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = _selectedLang == 'ta';
    final access = Provider.of<AccessibilityProvider>(context);
    final isDark = access.themeMode == ThemeMode.dark ||
        (access.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF140808) : const Color(0xFFFDFBF7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar: Logo & Instant Skip Setup ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SannidhiLogo(
                    height: 32,
                    isDark: isDark,
                  ),
                  InkWell(
                    onTap: _completeOnboarding,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isDark
                                  ? const Color(0xFFFCD34D)
                                  : AppColors.templeMaroon)
                              .withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isTamil ? 'நேரடியாக செல்க' : 'Skip Setup',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFCD34D)
                                  : AppColors.templeMaroon,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
                            color: isDark
                                ? const Color(0xFFFCD34D)
                                : AppColors.templeMaroon,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Single-Page Content ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Center Illuminated Sannidhi Emblem
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF2D1515)
                            : const Color(0xFFFFEDD5),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFFDE68A).withValues(alpha: 0.35)
                              : const Color(0xFFFED7AA),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark ? Colors.black : const Color(0xFFEA580C))
                                    .withValues(alpha: 0.1),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1111)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: SannidhiLogo(
                              height: 22,
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Headline & Sacred Welcome
                  Text(
                    isTamil ? 'அருள்மிகு சந்நிதி' : 'Arulmigu Sannidhi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : AppColors.templeMaroon,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTamil
                        ? 'தரிசனம், நேரலை வரிசை மற்றும் திருக்கோவில் சேவைகளுக்கான உங்களின் டிஜிட்டல் துணை'
                        : 'Your serene digital companion for darshan, live crowd telemetry & temple services',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section 1: Preferred Language ──
                  Text(
                    isTamil ? 'விருப்ப மொழி' : 'Preferred Language',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _languageOptionCard(
                          langCode: 'ta',
                          title: 'தமிழ்',
                          subtitle: 'முழுமையான தமிழ்',
                          selected: _selectedLang == 'ta',
                          isDark: isDark,
                          onTap: () => _selectLanguage('ta'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _languageOptionCard(
                          langCode: 'en',
                          title: 'English',
                          subtitle: 'Temple Services',
                          selected: _selectedLang == 'en',
                          isDark: isDark,
                          onTap: () => _selectLanguage('en'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Section 2: Profile Photo & Devotee Badge ──
                  _buildProfilePhotoSection(isTamil, isDark),
                  const SizedBox(height: 18),

                  // ── Section 3: Display Comfort (Senior Friendly View) ──
                  Text(
                    isTamil ? 'பார்வை வசதி' : 'Display Comfort',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1111) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isElderly
                            ? AppColors.deepSaffron
                            : (isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0)),
                        width: _isElderly ? 1.8 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isElderly
                              ? AppColors.deepSaffron.withValues(alpha: 0.15)
                              : const Color(0x06000000),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isElderly
                                ? const Color(0xFFFEF3C7)
                                : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.accessibility_new_rounded,
                            color: _isElderly
                                ? const Color(0xFFD97706)
                                : const Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTamil
                                    ? 'முதியோர் பார்வை முறை (A+)'
                                    : 'Senior Friendly View (A+)',
                                style: TextStyle(
                                  fontSize: _isElderly ? 15 : 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isTamil
                                    ? 'பெரிய எழுத்துகள் & தெளிவான பொத்தான்கள்'
                                    : 'Larger text, high-contrast & simpler navigation',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isElderly,
                          activeThumbColor: AppColors.deepSaffron,
                          activeTrackColor:
                              AppColors.deepSaffron.withValues(alpha: 0.4),
                          onChanged: _toggleElderly,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Section 3: Theme Selector ──
                  Text(
                    isTamil ? 'வண்ணத் தோற்றம்' : 'Theme Appearance',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _themeChip(ThemeMode.system,
                          isTamil ? '📱 கணினி' : '📱 System', isDark),
                      const SizedBox(width: 8),
                      _themeChip(ThemeMode.light,
                          isTamil ? '☀️ பகல்' : '☀️ Light', isDark),
                      const SizedBox(width: 8),
                      _themeChip(ThemeMode.dark,
                          isTamil ? '🌙 இரவு' : '🌙 Dark', isDark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Section 4: Key Features Preview ──
                  Text(
                    isTamil ? 'சிறப்பம்சங்கள்' : 'Key Highlights',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _featureTile(
                    icon: Icons.timer_rounded,
                    iconColor: const Color(0xFF16A34A),
                    iconBgColor: const Color(0xFFDCFCE7),
                    title: isTamil
                        ? 'நேரலை வரிசை & காத்திருப்பு'
                        : 'Live Queue & Crowd Status',
                    subtitle: isTamil
                        ? 'தரிசன வரிசை நிலையை முன்கூட்டியே அறிந்து திட்டமிடுங்கள்'
                        : 'Real-time wait times & occupancy updates before you arrive',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _featureTile(
                    icon: Icons.confirmation_number_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBgColor: const Color(0xFFFEF3C7),
                    title: isTamil
                        ? 'விரைவு தரிசனம் & வாகனம்'
                        : 'Direct Passes & Shuttle',
                    subtitle: isTamil
                        ? 'சிறப்பு தரிசனம் மற்றும் மின்சார வாகன முன்பதிவு ஒரு நொடியில்'
                        : 'Paperless darshan passes & electric shuttle bookings on your phone',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _featureTile(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: const Color(0xFF9333EA),
                    iconBgColor: const Color(0xFFF3E8FF),
                    title: isTamil
                        ? 'துணை AI & பஞ்சாங்கம்'
                        : 'Thunai AI & Daily Panchang',
                    subtitle: isTamil
                        ? 'குரல் வழி வழிகாட்டி, அன்னதான நேரம் & துல்லியமான திதி, நட்சத்திரம்'
                        : 'Bilingual voice guide, Annadhanam timings & live Vedic almanac',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Sticky Bottom "Enter Sannidhi" CTA Bar ──────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF140808) : const Color(0xFFFDFBF7),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.templeMaroon,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.templeMaroon.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isTamil ? 'சந்நிதிக்கு செல்க' : 'Enter Sannidhi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _featureTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1111) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
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
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
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
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageOptionCard({
    required String langCode,
    required String title,
    required String subtitle,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF331414) : const Color(0xFFFEF3C7))
              : (isDark ? const Color(0xFF1E1111) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.deepSaffron
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.deepSaffron.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? (isDark
                            ? const Color(0xFFFDE68A)
                            : AppColors.templeMaroon)
                        : (isDark ? Colors.white : AppTheme.textPrimary),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.deepSaffron, size: 20)
                else
                  Icon(Icons.radio_button_unchecked_rounded,
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      size: 20),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection(bool isTamil, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isTamil ? 'சுயவிவரப் படம் & சின்னம்' : 'Profile Photo & Devotee Badge',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            if (_profilePhotoPath != null)
              GestureDetector(
                onTap: () => setState(() => _profilePhotoPath = null),
                child: Text(
                  isTamil ? 'நீக்கு' : 'Reset Photo',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1111) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      DevoteeAvatar(
                        size: 64,
                        photoPath: _profilePhotoPath,
                        avatarId: _selectedAvatarId,
                        showBorder: true,
                        borderColor: AppColors.goldAccent,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.templeMaroon,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profilePhotoPath != null
                              ? (isTamil ? 'புகைப்படம் சேர்க்கப்பட்டது ✓' : 'Custom Photo Added ✓')
                              : (isTamil
                                  ? 'புனித சின்னம் / புகைப்படம்'
                                  : 'Sacred Avatar or Photo'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isTamil
                              ? 'கேமரா அல்லது கேலரி மூலம் படம் சேர்க்கவும்'
                              : 'Take photo or choose from sacred pilgrim badges',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _pickProfileImage(ImageSource.camera),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.templeMaroon.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.camera_alt, size: 13, color: AppColors.templeMaroon),
                                    const SizedBox(width: 4),
                                    Text(
                                      isTamil ? 'கேமரா' : 'Camera',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.templeMaroon,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _pickProfileImage(ImageSource.gallery),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.deepSaffron.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.photo_library, size: 13, color: AppColors.deepSaffron),
                                    const SizedBox(width: 4),
                                    Text(
                                      isTamil ? 'கேலரி' : 'Gallery',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.deepSaffron,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                thickness: 0.8,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 10),
              // Sacred Badges Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: kDevoteeAvatars.map((av) {
                  final isSelected = _profilePhotoPath == null && _selectedAvatarId == av.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _profilePhotoPath = null;
                        _selectedAvatarId = av.id;
                      });
                    },
                    child: Tooltip(
                      message: isTamil ? av.titleTa : av.titleEn,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.goldAccent : Colors.transparent,
                            width: 2.2,
                          ),
                        ),
                        child: DevoteeAvatar(
                          size: 38,
                          avatarId: av.id,
                          showBorder: false,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _themeChip(ThemeMode mode, String label, bool isDark) {
    final isSelected = _selectedTheme == mode;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTheme(mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.templeMaroon
                : (isDark ? const Color(0xFF1E1111) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.templeMaroon
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
