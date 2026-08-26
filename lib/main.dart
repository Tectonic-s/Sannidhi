import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_theme.dart';
import 'core/l10n/app_localizations.dart';
import 'data/repositories/mock_crowd_repository.dart';
import 'data/repositories/mock_festival_repository.dart';
import 'data/repositories/mock_shuttle_repository.dart';
import 'presentation/views/bookings/bookings_screen.dart';
import 'presentation/views/donation/donation_screen.dart';
import 'presentation/views/festivals/festivals_screen.dart';
import 'presentation/views/home/home_screen.dart';
import 'presentation/views/services/services_screen.dart';
import 'providers/accessibility_provider.dart';
import 'providers/user_activity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SannidhiApp());
}

class SannidhiApp extends StatefulWidget {
  const SannidhiApp({super.key});

  @override
  State<SannidhiApp> createState() => _SannidhiAppState();
}

class _SannidhiAppState extends State<SannidhiApp> {
  Locale _locale = const Locale('en');

  void _toggleLocale() {
    setState(() {
      _locale =
          _locale.languageCode == 'en' ? const Locale('ta') : const Locale('en');
    });
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
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (ctx, access, child) => MaterialApp(
          title: 'Sannidhi',
          debugShowCheckedModeBanner: false,
          theme: access.isElderlyMode
              ? _elderlyTheme(access)
              : AppTheme.lightTheme,
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ta')],
          home: MainNavigationScreen(onToggleLocale: _toggleLocale),
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
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTamil = l10n.currentLocale == 'ta';

    final screens = [
      BookingsScreen(onToggleLocale: widget.onToggleLocale),
      FestivalsScreen(onToggleLocale: widget.onToggleLocale),
      HomeScreen(onToggleLocale: widget.onToggleLocale),
      ServicesScreen(onToggleLocale: widget.onToggleLocale),
      DonationScreen(onToggleLocale: widget.onToggleLocale),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          BottomNavigationBarItem(
            icon: _NavIcon(icon: Icons.directions_bus, selected: _currentIndex == 0),
            label: isTamil ? AppTheme.bookingsTamil : AppTheme.bookings,
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(icon: Icons.calendar_month, selected: _currentIndex == 1),
            label: isTamil ? AppTheme.festivalsTamil : AppTheme.festivals,
          ),
          BottomNavigationBarItem(
            icon: _CenterNavIcon(selected: _currentIndex == 2),
            label: isTamil ? AppTheme.homeTamil : AppTheme.home,
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(icon: Icons.spa, selected: _currentIndex == 3),
            label: isTamil ? AppTheme.servicesTamil : AppTheme.services,
          ),
          BottomNavigationBarItem(
            icon: _NavIcon(icon: Icons.favorite, selected: _currentIndex == 4),
            label: isTamil ? AppTheme.donationTamil : AppTheme.donation,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _NavIcon({required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryColor.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 24),
    );
  }
}

class _CenterNavIcon extends StatelessWidget {
  final bool selected;
  const _CenterNavIcon({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryColor
            : AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.home,
          size: 24,
          color: selected ? Colors.white : AppTheme.primaryColor),
    );
  }
}
