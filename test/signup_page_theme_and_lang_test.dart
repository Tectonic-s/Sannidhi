import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/presentation/views/auth/login_screen.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Login/Sign Up Page UI & Controls Tests', () {
    late AuthProvider mockAuth;
    late AccessibilityProvider accessibilityProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockAuth = AuthProvider();
      accessibilityProvider = AccessibilityProvider();
    });

    Widget createTestWidget({VoidCallback? onToggleLocale, Locale locale = const Locale('en')}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
          ChangeNotifierProvider<AccessibilityProvider>.value(value: accessibilityProvider),
        ],
        child: Consumer<AccessibilityProvider>(
          builder: (context, a11y, _) {
            return MaterialApp(
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('ta'),
              ],
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: a11y.themeMode,
              home: LoginScreen(
                isInitialLaunch: true,
                onToggleLocale: onToggleLocale,
              ),
            );
          },
        ),
      );
    }

    testWidgets('Verify top maroon bar (AppBar) is completely removed', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // No AppBar widget should exist in the LoginScreen
      expect(find.byType(AppBar), findsNothing);

      // Sannidhi logo and greeting header should be in body
      expect(find.text('Marudamalai Murugan Devasthanam'), findsOneWidget);
      expect(find.text('Welcome, Sign In'), findsOneWidget);
    });

    testWidgets('Verify language selection and theme toggle appear after Skip Login button', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the Skip Login button at the bottom of the form
      final skipBtn = find.text('Skip Login & Continue to Home (Devotee)');
      expect(skipBtn, findsOneWidget);

      // Find language selection options
      final englishOption = find.text('English');
      final tamilOption = find.text('தமிழ்');
      expect(englishOption, findsOneWidget);
      expect(tamilOption, findsOneWidget);

      // Find theme toggle
      final lightModeText = find.text('Light Mode');
      expect(lightModeText, findsOneWidget);

      // Verify layout ordering (vertical Y positions):
      // Skip Button Y < Language Selector Y < Theme Toggle Y
      final skipY = tester.getBottomLeft(skipBtn).dy;
      final langY = tester.getTopLeft(englishOption).dy;
      final themeY = tester.getTopLeft(lightModeText).dy;

      expect(langY, greaterThan(skipY), reason: 'Language option should be placed after Skip Login button');
      expect(themeY, greaterThan(langY), reason: 'Theme toggle should be placed below language options');
    });

    testWidgets('Tapping theme toggle smoothly changes theme mode to Dark and updates UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsNothing);

      // Tap the theme toggle widget
      await tester.ensureVisible(find.text('Light Mode'));
      await tester.tap(find.text('Light Mode'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(accessibilityProvider.themeMode, ThemeMode.dark);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Light Mode'), findsNothing);
    });

    testWidgets('Tapping Tamil language option calls onToggleLocale callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool toggleCalled = false;
      await tester.pumpWidget(createTestWidget(onToggleLocale: () {
        toggleCalled = true;
      }));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('தமிழ்'));
      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      expect(toggleCalled, isTrue);
    });
  });
}
