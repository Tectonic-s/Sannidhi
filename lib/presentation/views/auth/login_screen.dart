import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/micro_animations.dart';
import '../../../core/widgets/sannidhi_logo.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../providers/auth_provider.dart';
import '../role_router_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isInitialLaunch;
  final VoidCallback? onToggleLocale;

  const LoginScreen({
    super.key,
    this.isInitialLaunch = false,
    this.onToggleLocale,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  bool _isOtpMode = false;
  bool _isOtpSent = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpPhoneController = TextEditingController();
  final _otpCodeController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpPhoneController.dispose();
    _otpCodeController.dispose();
    super.dispose();
  }

  int _devTapCount = 0;
  DateTime? _lastTapTime;
  bool _showDevOptions = false;

  void _onLogoTapped() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _devTapCount = 1;
    } else {
      _devTapCount++;
    }
    _lastTapTime = now;

    if (_devTapCount >= 5) {
      _devTapCount = 0;
      setState(() {
        _showDevOptions = !_showDevOptions;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _showDevOptions
                ? '🛠️ Developer Settings: Demo Accounts Unlocked'
                : '🔒 Developer Settings: Hidden',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.templeMaroon,
        ),
      );
    }
  }

  void _fillDemoCredentials(String email, String password, String role) {
    setState(() {
      _isRegister = false;
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  void _skipLogin() {
    context.read<AuthProvider>().skipLogin();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoleRouterScreen(onToggleLocale: widget.onToggleLocale ?? () {}),
      ),
      (route) => false,
    );
  }

  void _toggleTheme(bool isDark) {
    HapticFeedback.lightImpact();
    final nextMode = isDark ? ThemeMode.light : ThemeMode.dark;
    try {
      context.read<AccessibilityProvider>().setThemeMode(nextMode);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    bool success;
    if (_isRegister) {
      success = await auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoleRouterScreen(onToggleLocale: widget.onToggleLocale ?? () {}),
        ),
        (route) => false,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleSendOtp() async {
    final phone = _otpPhoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).currentLocale == 'ta'
                ? 'தயவுசெய்து சரியான 10 இலக்க மொபைல் எண்ணை உள்ளிடவும்'
                : 'Please enter a valid 10-digit mobile number',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.sendOtp(phone: phone);

    if (!mounted) return;
    if (success) {
      setState(() {
        _isOtpSent = true;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).currentLocale == 'ta'
                ? '✅ OTP வெற்றிகரமாக அனுப்பப்பட்டது! மாதிரி குறியீடு: 1234'
                : '✅ OTP Sent successfully! Test Code: 1234',
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final phone = _otpPhoneController.text.trim();
    final otp = _otpCodeController.text.trim();

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).currentLocale == 'ta'
                ? '4 இலக்க OTP குறியீட்டை உள்ளிடவும்'
                : 'Please enter the 4-digit OTP code',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtpAndLogin(phone: phone, otp: otp);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoleRouterScreen(onToggleLocale: widget.onToggleLocale ?? () {}),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'OTP verification failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final isTamil = AppLocalizations.of(context).currentLocale == 'ta';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resetIdentifierController = TextEditingController(text: _emailController.text.trim());
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final resetOtpController = TextEditingController();
    bool isResetCodeSent = false;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: Color(0xFFD97706),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTamil ? 'கடவுச்சொல்லை மீட்டமைக்க' : 'Reset Your Password',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryOf(context),
                                ),
                              ),
                              Text(
                                isTamil
                                    ? 'மின்னஞ்சல் அல்லது தொலைபேசி எண்ணை உள்ளிடவும்'
                                    : 'Enter your registered email or phone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: resetIdentifierController,
                      enabled: !isResetCodeSent,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'மின்னஞ்சல் / தொலைபேசி எண்' : 'Email or 10-digit Phone',
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (!isResetCodeSent) ...[
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final target = resetIdentifierController.text.trim();
                            if (target.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isTamil ? 'விவரங்களை உள்ளிடவும்' : 'Please enter email or phone'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            setModalState(() {
                              isResetCodeSent = true;
                              resetOtpController.text = '1234';
                            });
                            HapticFeedback.lightImpact();
                          },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            isTamil ? 'மீட்டமைப்பு குறியீட்டை அனுப்புக' : 'Send Verification Code',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isTamil ? 'குறியீடு அனுப்பப்பட்டது! (தேர்வு குறியீடு: 1234)' : 'Code sent! Use test code: 1234',
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: resetOtpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'சரிபார்ப்பு குறியீடு (OTP)' : '4-Digit Verification Code',
                          prefixIcon: const Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'புதிய கடவுச்சொல்' : 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'கடவுச்சொல்லை உறுதி செய்க' : 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final newPass = newPasswordController.text;
                            final confirmPass = confirmPasswordController.text;
                            if (newPass.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isTamil ? 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்' : 'Password must be at least 6 characters'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            if (newPass != confirmPass) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isTamil ? 'கடவுச்சொற்கள் பொருந்தவில்லை' : 'Passwords do not match'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            final auth = context.read<AuthProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            final ok = await auth.resetPassword(
                              emailOrPhone: resetIdentifierController.text.trim(),
                              newPassword: newPass,
                              otp: resetOtpController.text.trim(),
                            );

                            if (!mounted) return;
                            if (ok) {
                              if (bottomSheetCtx.mounted) {
                                Navigator.of(bottomSheetCtx).pop();
                              }
                              _emailController.text = resetIdentifierController.text.trim();
                              _passwordController.text = newPass;
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isTamil ? '✅ கடவுச்சொல் வெற்றிகரமாக மாற்றப்பட்டது! இப்போது உள்நுழையலாம்.' : '✅ Password updated successfully! You can now sign in.',
                                  ),
                                  backgroundColor: const Color(0xFF059669),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                          child: Text(
                            isTamil ? 'கடவுச்சொல்லை மாற்றுக' : 'Update Password & Sign In',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Minimal header row (Back arrow if canPop + Skip button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (Navigator.canPop(context))
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppTheme.textPrimaryOf(context),
                          ),
                          onPressed: () => Navigator.pop(context),
                          tooltip: isTamil ? 'பின்னே' : 'Back',
                        )
                      else
                        const SizedBox(width: 40),
                      TextButton(
                        onPressed: _skipLogin,
                        child: Text(
                          isTamil ? 'தவிர் →' : 'Skip →',
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Temple Sannidhi Logo (Tapping 5 times unlocks developer demo credentials)
                  Center(
                    child: GestureDetector(
                      onTap: _onLogoTapped,
                      child: SannidhiLogo(
                        height: 56,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      isTamil
                          ? 'மருதமலை முருகன் தேவஸ்தானம்'
                          : 'Marudamalai Murugan Devasthanam',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondaryOf(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _isRegister
                          ? (isTamil ? 'புதிய கணக்கு பதிவு' : 'Create an Account')
                          : (isTamil ? 'வணக்கம், உள்நுழைக' : 'Welcome, Sign In'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryOf(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _isRegister
                          ? (isTamil
                              ? 'தரிசனம் மற்றும் பேருந்து முன்பதிவு செய்ய கணக்கைத் தொடங்குங்கள்'
                              : 'Register to book passes & view pilgrim services')
                          : (isTamil
                              ? 'தொடர உங்கள் விவரங்களை உள்ளிடவும்'
                              : 'Enter your credentials to continue'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Demo Accounts Chips (Hidden by default, unlocked via 5-tap on logo)
                  if (_showDevOptions) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1917) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.goldAccent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.developer_mode,
                                  size: 14, color: AppColors.goldAccent),
                              const SizedBox(width: 6),
                              Text(
                                isTamil
                                    ? 'டெவலப்பர் மாதிரி கணக்குகள் (Developer Mode)'
                                    : 'Developer Demo Accounts:',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _demoChip(
                                label: 'Devotee',
                                color: AppColors.info,
                                onTap: () => _fillDemoCredentials(
                                  'devotee@sannidhi.app',
                                  'Devotee@123',
                                  'devotee',
                                ),
                              ),
                              _demoChip(
                                label: 'Gate Staff',
                                color: const Color(0xFFD97706),
                                onTap: () => _fillDemoCredentials(
                                  'staff@sannidhi.app',
                                  'Staff@123',
                                  'staff',
                                ),
                              ),
                              _demoChip(
                                label: 'Admin',
                                color: AppTheme.primaryColor,
                                onTap: () => _fillDemoCredentials(
                                  'admin@sannidhi.app',
                                  'Admin@123',
                                  'admin',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Mode Selector: Password Login vs Elder OTP Login
                  if (!_isRegister)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isOtpMode = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isOtpMode
                                      ? (isDark ? const Color(0xFF27272A) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isOtpMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  isTamil ? 'கடவுச்சொல் மூலம்' : 'Password Login',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: !_isOtpMode ? FontWeight.w800 : FontWeight.w600,
                                    color: !_isOtpMode
                                        ? (isDark ? Colors.white : AppTheme.primaryColor)
                                        : AppTheme.textSecondaryOf(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _isOtpMode = true;
                                  _isRegister = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isOtpMode
                                      ? (isDark ? const Color(0xFF27272A) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isOtpMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.elderly_rounded, size: 18, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 5),
                                    Text(
                                      isTamil ? 'மூத்தோர் OTP' : 'Elder OTP Login',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: _isOtpMode ? FontWeight.w800 : FontWeight.w600,
                                        color: _isOtpMode
                                            ? (isDark ? Colors.white : const Color(0xFFB45309))
                                            : AppTheme.textSecondaryOf(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── VIEW 1: ELDER / QUICK OTP LOGIN ────────────────────────
                  if (_isOtpMode && !_isRegister) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.accessibility_new_rounded, color: Color(0xFFD97706), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isTamil
                                  ? 'கடவுச்சொல் தேவையில்லை! உங்கள் மொபைல் எண்ணை உள்ளிட்டாலே உடனடியாக உள்நுழையலாம்.'
                                  : 'Senior Friendly: No password needed! Sign in easily with your mobile number & OTP.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _otpPhoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isOtpSent,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1),
                      decoration: InputDecoration(
                        labelText: isTamil ? 'மொபைல் எண் (10 இலக்கங்கள்)' : 'Mobile Number (10 digits)',
                        prefixIcon: const Icon(Icons.phone_android_rounded),
                        prefixText: '+91 ',
                        hintText: '9876543210',
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_isOtpSent) ...[
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: auth.isLoading ? null : _handleSendOtp,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isTamil ? 'OTP குறியீடு அனுப்புக' : 'Send Instant OTP',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isTamil
                                    ? 'குறியீடு அனுப்பப்பட்டது! மாதிரி குறியீடு: 1234'
                                    : 'OTP sent! Quick test code: 1234',
                                style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _isOtpSent = false),
                              child: Text(
                                isTamil ? 'மாற்றுக' : 'Change',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _otpCodeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8),
                        decoration: InputDecoration(
                          labelText: isTamil ? 'OTP குறியீடு' : '4-Digit OTP Code',
                          hintText: '1 2 3 4',
                          prefixIcon: const Icon(Icons.password_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick 1-tap fill test OTP for elders
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _otpCodeController.text = '1234'),
                          icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFD97706)),
                          label: Text(
                            isTamil ? 'தானாக நிரப்புக (1234)' : 'Quick Auto-Fill (1234)',
                            style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: auth.isLoading ? null : _handleVerifyOtp,
                          icon: const Icon(Icons.verified_user_rounded, size: 22),
                          label: auth.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isTamil ? 'சரிபார்த்து சந்நிதிக்குச் செல்' : 'Verify & Enter Sannidhi',
                                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // ── VIEW 2: STANDARD EMAIL & PASSWORD ─────────────────────
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'முழு பெயர்' : 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: isTamil ? 'மின்னஞ்சல்' : 'Email Address',
                        hintText: 'name@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) => Validators.validateEmail(v, isTamil: isTamil),
                    ),
                    const SizedBox(height: 14),

                    if (_isRegister) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: isTamil ? 'தொலைபேசி எண் (10 இலக்கங்கள்)' : 'Phone Number (10 digits)',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          prefixText: '+91 ',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length != 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (v) {
                        if (_isRegister) setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: isTamil ? 'கடவுச்சொல்' : 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => Validators.validatePassword(
                        v,
                        isRegister: _isRegister,
                        isTamil: isTamil,
                      ),
                    ),

                    // Reset / Forgot Password Option Button
                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            isTamil ? 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?' : 'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),

                    // Dynamic Password Requirements Guide for Registration (Sign Up)
                    if (_isRegister) ...[
                      _buildPasswordRequirementsGuide(isDark, isTamil),
                    ],
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _submit,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _isRegister
                                    ? (isTamil ? 'கணக்கை உருவாக்கு' : 'Create Account')
                                    : (isTamil ? 'உள்நுழைக' : 'Sign In'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle Register / Sign In
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isRegister = !_isRegister;
                          });
                          _formKey.currentState?.reset();
                        },
                        child: Text(
                          _isRegister
                              ? (isTamil
                                  ? 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழைக'
                                  : 'Already have an account? Sign In')
                              : (isTamil
                                  ? 'புதியவரா? கணக்கை பதிவு செய்க'
                                  : "Don't have an account? Register"),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFBBF24) : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isTamil ? 'அல்லது' : 'OR',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Skip Login Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(
                      isTamil
                          ? 'உள்நுழைவைத் தவிர்த்து முகப்புக்குச் செல்'
                          : 'Skip Login & Continue to Home (Devotee)',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                      side: BorderSide(
                        color: isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.6) : const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _skipLogin,
                  ),
                  const SizedBox(height: 24),

                  // Section Divider for Preferences
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          isTamil ? 'விருப்பத்தேர்வுகள்' : 'PREFERENCES',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Language Selection Option (Placed below Skip Login)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLanguageOption(
                            label: 'English',
                            icon: Icons.language_rounded,
                            isSelected: !isTamil,
                            isDark: isDark,
                            onTap: () {
                              if (isTamil) widget.onToggleLocale?.call();
                            },
                          ),
                          _buildLanguageOption(
                            label: 'தமிழ்',
                            icon: Icons.translate_rounded,
                            isSelected: isTamil,
                            isDark: isDark,
                            onTap: () {
                              if (!isTamil) widget.onToggleLocale?.call();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Dark or Light Mode Toggle with Smooth Transition Animation
                  Center(
                    child: _buildThemeToggle(isDark, isTamil),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    return BouncingScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF27272A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? (isDark ? const Color(0xFFFBBF24) : AppTheme.primaryColor)
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : AppTheme.primaryColor)
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark, bool isTamil) {
    return BouncingScaleTap(
      onTap: () => _toggleTheme(isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFFCD34D),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFFDE68A),
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey<bool>(isDark),
                  size: 16,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF78350F),
              ),
              child: Text(
                isDark
                    ? (isTamil ? 'இருண்ட பயன்முறை' : 'Dark Mode')
                    : (isTamil ? 'வெளிச்சப் பயன்முறை' : 'Light Mode'),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              width: 38,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                  width: 1,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
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

  Widget _buildPasswordRequirementsGuide(bool isDark, bool isTamil) {
    final strength = Validators.checkPasswordStrength(_passwordController.text);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTamil ? 'கடவுச்சொல் பாதுகாப்பு:' : 'Password Requirements:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B),
                ),
              ),
              Text(
                '${strength.score}/5',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: strength.isFullStrength
                      ? AppColors.success
                      : (strength.score >= 3 ? AppColors.warning : (isDark ? Colors.white54 : AppColors.textMuted)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength.score / 5.0,
              minHeight: 4,
              backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                strength.isFullStrength
                    ? AppColors.success
                    : (strength.score >= 3 ? const Color(0xFFF59E0B) : AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _reqChip(
                label: isTamil ? '8+ எழுத்துக்கள்' : '8+ Characters',
                met: strength.hasMinLength,
                isDark: isDark,
              ),
              _reqChip(
                label: isTamil ? 'பெரிய எழுத்து (A-Z)' : 'Uppercase (A-Z)',
                met: strength.hasUppercase,
                isDark: isDark,
              ),
              _reqChip(
                label: isTamil ? 'சிறிய எழுத்து (a-z)' : 'Lowercase (a-z)',
                met: strength.hasLowercase,
                isDark: isDark,
              ),
              _reqChip(
                label: isTamil ? 'எண் (0-9)' : 'Number (0-9)',
                met: strength.hasDigit,
                isDark: isDark,
              ),
              _reqChip(
                label: isTamil ? 'சிறப்புக் குறியீடு (!@#\$)' : 'Special (!@#\$)',
                met: strength.hasSpecial,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reqChip({required String label, required bool met, required bool isDark}) {
    final activeColor = AppColors.success;
    final inactiveColor = isDark ? const Color(0xFF71717A) : const Color(0xFF94A3B8);
    final bg = met
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF27272A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: met ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: met ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: met ? FontWeight.w700 : FontWeight.w500,
              color: met
                  ? (isDark ? const Color(0xFF4ADE80) : activeColor)
                  : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(Icons.touch_app, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: onTap,
    );
  }
}
