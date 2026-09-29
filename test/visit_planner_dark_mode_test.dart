import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';
import 'package:sannidhi/presentation/views/home/home_screen.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Visit Planner Dark Mode & Light Mode Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({required ThemeData theme, required Brightness brightness}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
          ChangeNotifierProvider(create: (_) => UserActivityProvider()),
          ChangeNotifierProvider(create: (_) => MockCrowdRepository()),
          ChangeNotifierProvider(create: (_) => MockFestivalRepository()),
          ChangeNotifierProvider(create: (_) => MockShuttleRepository()),
        ],
        child: MaterialApp(
          theme: theme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ta')],
          home: HomeScreen(onToggleLocale: () {}),
        ),
      );
    }

    testWidgets('Visit Planner card adapts properly to Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final darkTheme = ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF0A0A0A),
      );

      await tester.pumpWidget(buildTestWidget(theme: darkTheme, brightness: Brightness.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final plannerFinder = find.text('Visit Planner');
      expect(plannerFinder, findsOneWidget);

      final hourlyChartFinder = find.text('Hourly Chart');
      expect(hourlyChartFinder, findsOneWidget);

      // Verify "Hourly Chart" text color in dark mode is high-contrast gold (0xFFFBBF24)
      final hourlyChartText = tester.widget<Text>(hourlyChartFinder);
      expect(hourlyChartText.style?.color, const Color(0xFFFBBF24));

      // Tap "Hourly Chart" to open bottom sheet in dark mode
      await tester.tap(hourlyChartFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Modal bottom sheet should display CrowdForecasterChart
      expect(find.text('How Busy is the Temple?'), findsOneWidget);
    });

    testWidgets('Visit Planner card adapts properly to Light Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lightTheme = ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAF8F5),
        cardColor: Colors.white,
      );

      await tester.pumpWidget(buildTestWidget(theme: lightTheme, brightness: Brightness.light));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final plannerFinder = find.text('Visit Planner');
      expect(plannerFinder, findsOneWidget);

      final hourlyChartFinder = find.text('Hourly Chart');
      expect(hourlyChartFinder, findsOneWidget);

      // Best Time and Peak Hours are displayed
      expect(find.text('Best Time'), findsOneWidget);
      expect(find.text('Peak Hours'), findsOneWidget);
      expect(find.text('6:00 – 7:30 AM'), findsOneWidget);
      expect(find.text('10 AM – 1 PM'), findsOneWidget);
    });
  });
}
