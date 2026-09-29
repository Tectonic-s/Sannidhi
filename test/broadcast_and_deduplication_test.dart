import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/core/services/firebase_service.dart';
import 'package:sannidhi/core/services/geofence_service.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';
import 'package:sannidhi/presentation/views/account/account_screen.dart';
import 'package:sannidhi/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:sannidhi/presentation/views/auth/login_screen.dart';
import 'package:sannidhi/presentation/views/bookings/bookings_screen.dart';
import 'package:sannidhi/presentation/views/home/home_screen.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/bulletin_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';

void main() {
  group('1. Slot Picker: Remove Passed Times (Not Just Striking Off)', () {
    testWidgets('Renders only active future slots without lineThrough styling', (tester) async {
      final auth = AuthProvider();
      final crowd = MockCrowdRepository();
      final shuttle = MockShuttleRepository();
      final activity = UserActivityProvider();
      final access = AccessibilityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<MockCrowdRepository>.value(value: crowd),
            ChangeNotifierProvider<MockShuttleRepository>.value(value: shuttle),
            ChangeNotifierProvider<UserActivityProvider>.value(value: activity),
            ChangeNotifierProvider<AccessibilityProvider>.value(value: access),
          ],
          child: MaterialApp(
            localizationsDelegates: const [AppLocalizations.delegate],
            home: Scaffold(
              body: BookingsScreen(
                initialSubPage: 0,
                onToggleLocale: _dummyVoid,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Any rendered text should NOT have TextDecoration.lineThrough
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final text in textWidgets) {
        if (text.style?.decoration == TextDecoration.lineThrough) {
          fail('Found text with lineThrough decoration: ${text.data}');
        }
      }
    });
  });

  group('2. Immediate Sign In Prompt On Sign Out', () {
    testWidgets('Tapping Sign Out in AccountScreen immediately pushes LoginScreen', (tester) async {
      final auth = AuthProvider();
      await auth.login('devotee@sannidhi.org', 'Pass123!@#');
      final access = AccessibilityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<AccessibilityProvider>.value(value: access),
          ],
          child: const MaterialApp(
            localizationsDelegates: [AppLocalizations.delegate],
            home: AccountScreen(
              onToggleLocale: _dummyVoid,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Sign Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify that LoginScreen is presented immediately
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('3. Broadcast Dialog Layout & Overflow Prevention', () {
    testWidgets('Broadcast popup renders without letter or button overflow in narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(380, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final crowdRepo = MockCrowdRepository();
      final shuttleRepo = MockShuttleRepository();
      final activityProvider = UserActivityProvider();
      final festivalRepo = MockFestivalRepository(autoSync: false);
      final bulletinProvider = BulletinProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockCrowdRepository>.value(value: crowdRepo),
            ChangeNotifierProvider<MockShuttleRepository>.value(value: shuttleRepo),
            ChangeNotifierProvider<UserActivityProvider>.value(value: activityProvider),
            ChangeNotifierProvider<MockFestivalRepository>.value(value: festivalRepo),
            ChangeNotifierProvider<BulletinProvider>.value(value: bulletinProvider),
          ],
          child: const MaterialApp(
            locale: Locale('ta'),
            localizationsDelegates: [AppLocalizations.delegate],
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find the broadcast trigger banner
      final broadcastShortcut = find.byIcon(Icons.campaign);
      expect(broadcastShortcut, findsWidgets);

      await tester.tap(broadcastShortcut.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify broadcast dialog renders title and actions cleanly
      expect(find.text('அவசர அறிவிப்பு மையம்'), findsOneWidget);
      expect(find.text('ஒளிபரப்பு செய்'), findsOneWidget);
      expect(find.text('ரத்து'), findsOneWidget);

      // Verify no overflow errors were thrown
      expect(tester.takeException(), isNull);
    });
  });

  group('4. Dual-Source Crowd Deduplication (Geofencing vs Ticket Scans)', () {
    test('Prevents double-counting when a devotee is detected via both Geofence and Ticket Scan', () {
      final repo = MockCrowdRepository();
      final initialCount = repo.getCrowdData().currentVisitors;

      // 1. Devotee enters GPS geofence
      repo.recordGeofenceEvent(GeofenceEvent.enter, 'devotee_murugan_01');
      expect(repo.getCrowdData().currentVisitors, initialCount + 1);
      expect(repo.overlapDeduplicatedCount, 0);

      // 2. Same devotee has ticket scanned at gate
      repo.recordTicketVerification('devotee_murugan_01');
      // Count must REMAIN initialCount + 1 (NOT incremented twice)
      expect(repo.getCrowdData().currentVisitors, initialCount + 1);
      // Deduplicated overlap must be recorded
      expect(repo.overlapDeduplicatedCount, 1);

      // 3. A second devotee (paper ticket / offline) is scanned without previous geofence
      repo.recordTicketVerification('devotee_karthik_02');
      expect(repo.getCrowdData().currentVisitors, initialCount + 2);

      // 4. Second devotee now enters deeper into the geofence perimeter
      repo.recordGeofenceEvent(GeofenceEvent.enter, 'devotee_karthik_02');
      // Count must still remain initialCount + 2
      expect(repo.getCrowdData().currentVisitors, initialCount + 2);
      expect(repo.overlapDeduplicatedCount, 2);
    });
  });

  group('5. Firebase Live Broadcast Sync to Devotee Account', () {
    testWidgets('Live broadcast travelling through Firebase renders on Devotee HomeScreen in real-time', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final crowdRepo = MockCrowdRepository();
      final festivalRepo = MockFestivalRepository(autoSync: false);
      final accessProvider = AccessibilityProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockCrowdRepository>.value(value: crowdRepo),
            ChangeNotifierProvider<MockFestivalRepository>.value(value: festivalRepo),
            ChangeNotifierProvider<AccessibilityProvider>.value(value: accessProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [AppLocalizations.delegate],
            home: HomeScreen(
              onToggleLocale: _dummyVoid,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initially no active broadcast
      expect(find.text('TEMPLE LIVE BROADCAST'), findsNothing);

      // Admin publishes a live emergency advisory through FirebaseService
      await FirebaseService.instance.publishBroadcast(
        message: 'Hilltop Ghat Road: Queue moving smoothly. Free Annadhanam open.',
        isActive: true,
        messageTa: 'மலைப்பாதை தரிசனம் சீராக நடைபெறுகிறது. இலவச அன்னதானம் வழங்கப்படுகிறது.',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Devotee HomeScreen now reflects the live Firebase broadcast
      expect(find.text('TEMPLE LIVE BROADCAST'), findsOneWidget);
      expect(find.text('Hilltop Ghat Road: Queue moving smoothly. Free Annadhanam open.'), findsOneWidget);

      // Admin clears the broadcast
      await FirebaseService.instance.publishBroadcast(
        message: '',
        isActive: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Banner disappears
      expect(find.text('TEMPLE LIVE BROADCAST'), findsNothing);
    });
  });
}

void _dummyVoid() {}
