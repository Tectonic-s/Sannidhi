import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/core/widgets/announcement_ticker.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';
import 'package:sannidhi/presentation/views/bookings/bookings_screen.dart';
import 'package:sannidhi/presentation/views/facility/facility_locator_screen.dart';

void main() {
  Widget buildTestApp({required Widget child, String locale = 'ta'}) {
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
        locale: Locale(locale),
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
        home: child,
      ),
    );
  }

  group('Tamil Mode Truncation & Localization Tests', () {
    testWidgets('AnnouncementTicker displays complete Tamil text in live feed without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(child: const Scaffold(body: AnnouncementTicker()), locale: 'ta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Tamil bulletin header tag and first bulletin content
      expect(find.text('நேரலைச் செய்தி'), findsOneWidget);
      expect(find.text('பாதுகாப்பு எச்சரிக்கை'), findsOneWidget);
      expect(
        find.textContaining('மாலை 5:00 மணிக்கு மேல் இருசக்கர வாகனங்கள்'),
        findsOneWidget,
      );
    });

    testWidgets('FacilityLocatorScreen displays Tamil categories and parking facilities in Tamil mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(
        child: FacilityLocatorScreen(onToggleLocale: () {}),
        locale: 'ta',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Tamil filter chips
      expect(find.text('அனைத்தும்'), findsOneWidget);
      expect(find.text('வாகனம்'), findsWidgets);
      expect(find.text('குடிநீர்'), findsWidgets);
      expect(find.text('மருத்துவம்'), findsWidgets);
      expect(find.text('உணவு'), findsWidgets);
      expect(find.text('வசதிகள்'), findsWidgets);

      // Verify Parking facility card appears with Tamil name & description
      expect(
        find.textContaining('அடிவாரம் பிரதான வாகன நிறுத்துமிடம்'),
        findsOneWidget,
      );
      expect(
        find.textContaining('24 மணி நேரமும் திறந்திருக்கும்'),
        findsOneWidget,
      );
    });

    testWidgets('BookingsScreen displays FittedBox tabs in Tamil mode without truncation', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestApp(
        child: BookingsScreen(onToggleLocale: () {}),
        locale: 'ta',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Tamil TabBar labels
      expect(find.text('டிக்கெட் முன்பதிவு'), findsOneWidget);
      expect(find.text('என் பாஸ்கள் (செயலில்)'), findsOneWidget);

      // Switch to the Active Passes Tab
      await tester.tap(find.text('என் பாஸ்கள் (செயலில்)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // In unauthenticated mode, it should display Tamil login prompt
      expect(find.text('பாஸ்களைக் காண உள்நுழையவும்'), findsOneWidget);
      expect(find.text('இப்போது உள்நுழையவும்'), findsOneWidget);
    });
  });
}
