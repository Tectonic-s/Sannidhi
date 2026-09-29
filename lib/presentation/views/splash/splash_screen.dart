import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/sannidhi_logo.dart';
import '../../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../role_router_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  final ValueChanged<String>? onSetLocale;

  const SplashScreen({
    super.key,
    required this.onToggleLocale,
    this.onSetLocale,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  Timer? _navTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // After brief splash fade, check auth and route directly
    _navTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        _proceedToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _proceedToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated || auth.hasSkippedLogin) {
      // Already signed in -> Go DIRECTLY to Home page, do not show sign-in
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, _) =>
              RoleRouterScreen(onToggleLocale: widget.onToggleLocale),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      // Not logged in -> Go DIRECTLY to sign in / sign up page
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, _) => LoginScreen(
            isInitialLaunch: true,
            onToggleLocale: widget.onToggleLocale,
          ),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pure white background regardless of system light/dark mode
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: SannidhiLogo(
              height: 58,
              fit: BoxFit.contain,
              isDark: false, // Pure white background, use black logo
            ),
          ),
        ),
      ),
    );
  }
}
