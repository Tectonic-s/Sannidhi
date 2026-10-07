import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'core/widgets/micro_animations.dart';
import 'data/repositories/mock_crowd_repository.dart';
import 'data/repositories/mock_festival_repository.dart';
import 'data/repositories/mock_shuttle_repository.dart';
import 'presentation/views/ai_assistant_dialog.dart';
import 'presentation/views/bookings/bookings_screen.dart';
import 'presentation/views/festivals/festivals_screen.dart';
import 'presentation/views/home/home_screen.dart';
import 'presentation/views/more/more_screen.dart';
import 'presentation/views/splash/splash_screen.dart';
import 'core/services/firebase_service.dart';
import 'core/services/geofence_service.dart';
import 'core/services/notification_service.dart';
import 'providers/accessibility_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bulletin_provider.dart';
import 'providers/user_activity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.instance.init();
  } catch (e) {
    debugPrint('[main] FirebaseService init error: $e');
  }
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('[main] NotificationService init error: $e');
  }
  try {
    await GeofenceService.instance.init();
  } catch (e) {
    debugPrint('[main] GeofenceService init error: $e');
  }

  final authProvider = AuthProvider();
  await authProvider.restoreSession();

  runApp(SannidhiApp(authProvider: authProvider));
  Future.microtask(() => GeofenceService.instance.startMonitoring());
}

class SannidhiApp extends StatefulWidget {
  final AuthProvider? authProvider;
  const SannidhiApp({super.key, this.authProvider});

  @override
  State<SannidhiApp> createState() => _SannidhiAppState();
}

class _SannidhiAppState extends State<SannidhiApp> {
  Locale _locale = const Locale('en');
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider ?? (AuthProvider()..restoreSession());
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('preferred_language');
    if (saved != null && (saved == 'ta' || saved == 'en')) {
      setState(() {
        _locale = Locale(saved);
      });
    }
  }

  void _setLocale(String langCode) {
    setState(() {
      _locale = Locale(langCode);
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('preferred_language', langCode);
    });
  }

  void _toggleLocale() {
    final nextCode = _locale.languageCode == 'en' ? 'ta' : 'en';
    _setLocale(nextCode);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final repo = MockCrowdRepository();
          repo.initGeofence();
          return repo;
        }),
        ChangeNotifierProvider(create: (_) => MockFestivalRepository()),
        ChangeNotifierProvider(create: (_) => MockShuttleRepository()),
        ChangeNotifierProvider(create: (_) => UserActivityProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ChangeNotifierProvider(create: (_) => BulletinProvider()..init()),
        ChangeNotifierProvider.value(value: _authProvider),
      ],
      child: Consumer2<AccessibilityProvider, AuthProvider>(
        builder: (ctx, access, auth, child) => MaterialApp(
          title: 'Sannidhi',
          debugShowCheckedModeBanner: false,
          themeMode: access.themeMode,
          theme: access.isElderlyMode
              ? _elderlyTheme(access)
              : AppTheme.lightTheme,
          darkTheme: access.isElderlyMode
              ? _elderlyDarkTheme(access)
              : AppTheme.darkTheme,
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ta')],
          home: SplashScreen(
            onToggleLocale: _toggleLocale,
            onSetLocale: _setLocale,
          ),
        ),
      ),
    );
  }

  ThemeData _elderlyDarkTheme(AccessibilityProvider access) {
    return AppTheme.darkTheme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB91C1C),
          foregroundColor: Colors.white,
          minimumSize: Size(0, access.minTouchTarget),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  ThemeData _elderlyTheme(AccessibilityProvider access) {
    return AppTheme.lightTheme.copyWith(
      scaffoldBackgroundColor: access.backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: access.primaryColor,
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: access.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(0, access.minTouchTarget),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final VoidCallback onToggleLocale;
  const MainNavigationScreen({super.key, required this.onToggleLocale});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _bookingSubPage = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    final screens = [
      HomeScreen(
        onToggleLocale: widget.onToggleLocale,
        onNavigateTab: (index) => setState(() => _currentIndex = index),
        onNavigateBookingSubPage: (subPage) => setState(() {
          _bookingSubPage = subPage;
          _currentIndex = 1;
        }),
      ),
      BookingsScreen(
        key: ValueKey('bookings_tab_$_bookingSubPage'),
        onToggleLocale: widget.onToggleLocale,
        initialSubPage: _bookingSubPage,
      ),
      FestivalsScreen(onToggleLocale: widget.onToggleLocale),
      MoreScreen(onToggleLocale: widget.onToggleLocale),
    ];

    final access = Provider.of<AccessibilityProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: _currentIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: BreathingGlow(
                glowColor: AppTheme.primaryColor,
                minBlur: 4,
                maxBlur: 12,
                child: FloatingActionButton.extended(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AiAssistantDialog(isTamil: isTamil),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 6,
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                  label: Text(
                    isTamil ? 'துணை AI • கேளுங்கள்' : 'Thunai AI • Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: access.isElderlyMode ? 15 : 13.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          bottomInset > 0 ? bottomInset + 4 : 14,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: (access.isElderlyMode || isTamil) ? 76 : 66,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF000000).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF222222)
                      : Colors.white.withValues(alpha: 0.90),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: (isDark ? const Color(0xFFD97706) : AppTheme.primaryColor)
                        .withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: isTamil ? 'முகப்பு' : 'Home',
                    isElderly: access.isElderlyMode,
                    isTamil: isTamil,
                    isDark: isDark,
                  ),
                  _navItem(
                    index: 1,
                    icon: Icons.confirmation_num_outlined,
                    activeIcon: Icons.confirmation_num_rounded,
                    label: isTamil ? 'முன்பதிவு' : 'Bookings',
                    isElderly: access.isElderlyMode,
                    isTamil: isTamil,
                    isDark: isDark,
                  ),
                  _navItem(
                    index: 2,
                    icon: Icons.explore_outlined,
                    activeIcon: Icons.explore_rounded,
                    label: isTamil ? 'திருவிழா' : 'Explore',
                    isElderly: access.isElderlyMode,
                    isTamil: isTamil,
                    isDark: isDark,
                  ),
                  _navItem(
                    index: 3,
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: isTamil ? 'மேலும்' : 'More',
                    isElderly: access.isElderlyMode,
                    isTamil: isTamil,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isElderly,
    required bool isTamil,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFFFDE68A) : AppTheme.primaryColor;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(28),
          splashColor: AppTheme.accentColor.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.symmetric(
              vertical: (isElderly || isTamil) ? 5 : 4,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: isSelected
                  ? (isDark
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF7F1D1D).withValues(alpha: 0.60),
                            const Color(0xFF450A0A).withValues(alpha: 0.45),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white,
                            const Color(0xFFFFFBEB).withValues(alpha: 0.90),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ))
                  : null,
              border: isSelected
                  ? Border.all(
                      color: isDark
                          ? const Color(0xFFFDE68A).withValues(alpha: 0.40)
                          : AppTheme.primaryColor.withValues(alpha: 0.22),
                      width: 1.2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFFD97706).withValues(alpha: 0.20)
                            : AppTheme.primaryColor.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      if (!isDark)
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                        ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: (isElderly || isTamil) ? 25 : 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: (isElderly || isTamil) ? 12 : 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? activeColor : inactiveColor,
                    letterSpacing: isTamil ? 0.0 : 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
