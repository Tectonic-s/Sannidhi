import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/data/models/festival_model.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';
import 'package:sannidhi/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';

void main() {
  group('MockFestivalRepository Unit & API Sync Tests', () {
    test('Initializes with 15 verified festivals', () {
      final repo = MockFestivalRepository(autoSync: false);
      expect(repo.festivals.length, 15);

      final navaratri = repo.festivals.firstWhere((f) => f.id == '1');
      expect(navaratri.name, contains('Navaratri'));
      expect(navaratri.tamilName, 'நவராத்திரி தொடக்கம்');
      expect(navaratri.date, '2026-10-11');
      expect(navaratri.isSpecial, true);
    });

    test('getUpcomingFestivals returns upcoming list', () {
      final repo = MockFestivalRepository(autoSync: false);
      final upcoming = repo.getUpcomingFestivals(limit: 5);
      expect(upcoming.isNotEmpty, true);
      expect(upcoming.length <= 5, true);
    });

    test('getFestivals returns all master festivals', () {
      final repo = MockFestivalRepository(autoSync: false);
      final list = repo.getFestivals();
      expect(list.length, 15);
    });

    test('updateFestivalDate updates local state optimistically and notifies listeners', () async {
      final repo = MockFestivalRepository(autoSync: false);
      bool notified = false;
      repo.addListener(() {
        notified = true;
      });

      const updatedDate = '2026-10-15';
      await repo.updateFestivalDate('1', updatedDate);

      final updatedFestival = repo.festivals.firstWhere((f) => f.id == '1');
      expect(updatedFestival.date, updatedDate);
      expect(notified, true);
    });

    test('createCustomFestival adds festival to list and notifies listeners', () async {
      final repo = MockFestivalRepository(autoSync: false);
      bool notified = false;
      repo.addListener(() {
        notified = true;
      });

      final custom = FestivalModel(
        id: 'special_kumbhabhishekam',
        name: 'Maha Kumbhabhishekam 2027',
        tamilName: 'மகா கும்பாபிஷேகம் 2027',
        date: '2027-02-12',
        description: 'Consecration ceremony of the Rajagopuram and sanctum.',
        tamilDescription: 'ராஜகோபுரம் மற்றும் மூலவர் சந்நிதி கும்பாபிஷேக திருவிழா.',
        imageUrl: '',
        isSpecial: true,
      );

      await repo.createCustomFestival(custom);

      expect(repo.festivals.any((f) => f.id == 'special_kumbhabhishekam'), true);
      final retrieved = repo.festivals.firstWhere((f) => f.id == 'special_kumbhabhishekam');
      expect(retrieved.tamilName, 'மகா கும்பாபிஷேகம் 2027');
      expect(retrieved.date, '2027-02-12');
      expect(notified, true);
    });
  });

  group('AdminDashboardScreen Festival Management Widget Tests', () {
    testWidgets('Renders Festival Calendar & Schedule Control section in Admin Dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final crowdRepo = MockCrowdRepository();
      final shuttleRepo = MockShuttleRepository();
      final activityProvider = UserActivityProvider();
      final festivalRepo = MockFestivalRepository(autoSync: false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockCrowdRepository>.value(value: crowdRepo),
            ChangeNotifierProvider<MockShuttleRepository>.value(value: shuttleRepo),
            ChangeNotifierProvider<UserActivityProvider>.value(value: activityProvider),
            ChangeNotifierProvider<MockFestivalRepository>.value(value: festivalRepo),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
            ],
            home: AdminDashboardScreen(),
          ),
        ),
      );

      // Pump initial frames (avoid pumpAndSettle due to continuous animations)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the festival schedule section title is rendered
      expect(find.text('Temple Festival Schedule & Date Control'), findsOneWidget);
      expect(find.text('Master Festival Calendar'), findsOneWidget);

      // Verify that festivals like Navaratri and Deepavali are displayed in the list
      expect(find.textContaining('Navaratri'), findsWidgets);
      expect(find.text('2026-10-11'), findsWidgets);

      // Verify Edit Date action button is present
      expect(find.text('Edit Date'), findsWidgets);
    });

    testWidgets('Tapping Edit Date opens the edit dialog with DatePicker', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authProvider = AuthProvider();
      final crowdRepo = MockCrowdRepository();
      final shuttleRepo = MockShuttleRepository();
      final activityProvider = UserActivityProvider();
      final festivalRepo = MockFestivalRepository(autoSync: false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<MockCrowdRepository>.value(value: crowdRepo),
            ChangeNotifierProvider<MockShuttleRepository>.value(value: shuttleRepo),
            ChangeNotifierProvider<UserActivityProvider>.value(value: activityProvider),
            ChangeNotifierProvider<MockFestivalRepository>.value(value: festivalRepo),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
            ],
            home: AdminDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the first Edit Date button
      final editButtons = find.text('Edit Date');
      expect(editButtons, findsWidgets);

      await tester.tap(editButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the dialog popped up
      expect(find.text('Update Festival Date'), findsOneWidget);
      expect(find.text('Save Date'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Update Festival Date'), findsNothing);
    });
  });
}
