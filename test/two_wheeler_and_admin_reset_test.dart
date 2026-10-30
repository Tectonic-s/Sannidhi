import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sannidhi/data/models/activity_models.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';
import 'package:sannidhi/presentation/views/bookings/bookings_screen.dart';
import 'package:sannidhi/presentation/views/home/home_screen.dart';
import 'package:sannidhi/presentation/views/more/more_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Two-Wheeler Booking Tests', () {
    test('TwoWheelerBooking model fields and ticket status operate correctly', () {
      final ticket = UserActivityProvider.generateTickets(
        bookingId: 'TW-TEST-001',
        count: 1,
        type: 'BIKE',
        slot: '09:00 AM',
        date: '2026-10-22',
      );

      final booking = TwoWheelerBooking(
        bookingId: 'TW-TEST-001',
        slotTime: '09:00 AM',
        totalFare: 20.0,
        vehicleCount: 1,
        vehicleNumber: 'TN38AB1234',
        tickets: ticket,
        timestamp: DateTime.now(),
        date: '2026-10-22',
      );

      expect(booking.bookingId, 'TW-TEST-001');
      expect(booking.slotTime, '09:00 AM');
      expect(booking.totalFare, 20.0);
      expect(booking.vehicleCount, 1);
      expect(booking.vehicleNumber, 'TN38AB1234');
      expect(booking.tickets.length, 1);
      expect(booking.tickets.first.ticketId.isNotEmpty, true);
      expect(booking.date, '2026-10-22');
      expect(booking.isAllUsed, false);
      expect(booking.usedCount, 0);
    });

    test('UserActivityProvider supports Two-Wheeler bookings, usage, and counting', () async {
      final provider = UserActivityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.twoWheelerBookings.length, 0);
      expect(provider.activePassCount, 0);

      final tickets = UserActivityProvider.generateTickets(
        bookingId: 'TW-TEST-002',
        count: 2,
        type: 'BIKE',
        slot: '10:00 AM',
        date: '2026-10-22',
      );

      final booking = TwoWheelerBooking(
        bookingId: 'TW-TEST-002',
        slotTime: '10:00 AM',
        totalFare: 40.0,
        vehicleCount: 2,
        vehicleNumber: 'TN38CD5678',
        tickets: tickets,
        timestamp: DateTime.now(),
        date: '2026-10-22',
      );

      provider.addTwoWheelerBooking(booking);

      expect(provider.twoWheelerBookings.length, 1);
      expect(provider.activeTwoWheelerBookings.length, 1);
      expect(provider.activePassCount, 1);

      // Verify ticket scan and usage
      final ticketId = tickets.first.ticketId;
      expect(provider.isTicketUsed(ticketId), false);

      final marked = await provider.markTicketUsed(ticketId);
      expect(marked, true);
      expect(provider.isTicketUsed(ticketId), true);
    });
  });

  group('Admin Panel Fresh Start & Reset Tests', () {
    test('MockCrowdRepository resetForFreshStart sets footfall to 0 and status to low', () {
      final repo = MockCrowdRepository();
      repo.resetForFreshStart();

      final data = repo.getCrowdData();
      expect(data.currentVisitors, 0);
      expect(data.status, 'low');
      expect(data.estimatedWaitMinutes, 5);
    });

    test('UserActivityProvider clearAllActivities clears all passes', () async {
      final provider = UserActivityProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final tickets = UserActivityProvider.generateTickets(
        bookingId: 'TW-TEST-003',
        count: 1,
        type: 'BIKE',
        slot: '08:00 AM',
        date: '2026-10-22',
      );

      provider.addTwoWheelerBooking(TwoWheelerBooking(
        bookingId: 'TW-TEST-003',
        slotTime: '08:00 AM',
        totalFare: 20.0,
        vehicleCount: 1,
        vehicleNumber: 'TN38XY9999',
        tickets: tickets,
        timestamp: DateTime.now(),
        date: '2026-10-22',
      ));

      expect(provider.twoWheelerBookings.length, 1);
      await provider.clearAllActivities();
      expect(provider.twoWheelerBookings.length, 0);
      expect(provider.activePassCount, 0);
    });
  });

  group('Feature Cleanup & Removal Verification', () {
    testWidgets('Visiting with family and kids is completely removed from HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
            ChangeNotifierProvider(create: (_) => UserActivityProvider()),
            ChangeNotifierProvider(create: (_) => MockCrowdRepository()),
            ChangeNotifierProvider(create: (_) => MockFestivalRepository()),
            ChangeNotifierProvider(create: (_) => MockShuttleRepository()),
          ],
          child: MaterialApp(
            home: HomeScreen(
              onToggleLocale: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Visiting with family'), findsNothing);
      expect(find.textContaining('குழந்தைகளுடன் வருகிறீர்களா'), findsNothing);
    });

    testWidgets('Backend API URL is completely removed from MoreScreen UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
            ChangeNotifierProvider(create: (_) => UserActivityProvider()),
            ChangeNotifierProvider(create: (_) => MockCrowdRepository()),
            ChangeNotifierProvider(create: (_) => MockFestivalRepository()),
            ChangeNotifierProvider(create: (_) => MockShuttleRepository()),
          ],
          child: MaterialApp(
            home: MoreScreen(
              onToggleLocale: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Backend Server'), findsNothing);
      expect(find.textContaining('API URL'), findsNothing);
      expect(find.textContaining('http://'), findsNothing);
    });

    testWidgets('BookingsScreen displays all three booking tabs including Two-Wheeler', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
            ChangeNotifierProvider(create: (_) => UserActivityProvider()),
            ChangeNotifierProvider(create: (_) => MockCrowdRepository()),
            ChangeNotifierProvider(create: (_) => MockFestivalRepository()),
            ChangeNotifierProvider(create: (_) => MockShuttleRepository()),
          ],
          child: MaterialApp(
            home: BookingsScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify 3 tabs are present
      expect(find.text('Bus Booking'), findsWidgets);
      expect(find.text('Darshan Booking'), findsWidgets);
      expect(find.text('Two-Wheeler Booking'), findsWidgets);

      // Tap on Two-Wheeler tab
      final twoWheelerTab = find.text('Two-Wheeler Booking');
      await tester.tap(twoWheelerTab.first);
      await tester.pumpAndSettle();

      // Verify Two-Wheeler booking subpage content
      expect(find.text('Two-Wheeler Parking & Pass'), findsOneWidget);
      expect(find.text('Adivaram Covered Bay & Hilltop Road Pass'), findsOneWidget);
      expect(find.text('Helmet Locker Bay'), findsOneWidget);
      expect(find.text('Vehicle Reg. Number (Optional)'), findsOneWidget);

      await tester.drag(find.byKey(const ValueKey('two_wheeler_booking_sub_page')), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.textContaining('Book Two-Wheeler Pass'), findsOneWidget);
    });
  });
}
