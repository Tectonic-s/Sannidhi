import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/models/user_model.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';
import 'package:sannidhi/presentation/views/bookings/bookings_screen.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _mockUser;

  void setRole(UserRole? role) {
    if (role == null) {
      _mockUser = null;
    } else {
      _mockUser = UserModel(
        id: 'usr-test-01',
        name: role.displayName,
        email: '${role.toDbString()}@sannidhi.app',
        phone: '9876543210',
        role: role,
        token: 'mock-token',
      );
    }
    notifyListeners();
  }

  @override
  bool get hasSkippedLogin => false;
  @override
  void skipLogin() {}
  @override
  UserModel? get currentUser => _mockUser;
  @override
  bool get isAuthenticated => _mockUser != null;
  @override
  bool get isStaff => false;
  @override
  bool get isAdmin => false;
  @override
  bool get isDevotee => true;
  @override
  String get token => _mockUser?.token ?? '';
  @override
  String? get errorMessage => null;
  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Advance Booking (1 Week in Advance) Tests', () {
    testWidgets('BookingsScreen displays 7-day advance date selector with Today and future dates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockAuthProvider()..setRole(UserRole.devotee);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
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
      await tester.pump(const Duration(milliseconds: 200));

      // Check date selector header exists
      expect(find.text('Select Date'), findsOneWidget);
      expect(find.text('7 Days Advance'), findsOneWidget);

      // Check Today pill exists
      final now = DateTime.now();
      expect(find.text('Today (${now.day})'), findsOneWidget);

      // Check summary initially shows today's travel date
      expect(find.text('Travel Date'), findsOneWidget);
      expect(find.textContaining('Today (${now.day}'), findsNWidgets(2));

      // Tap on the next day pill (tomorrow)
      final tomorrow = now.add(const Duration(days: 1));
      const daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final tomorrowLabel = '${daysEn[tomorrow.weekday - 1]} ${tomorrow.day}';
      final tomorrowPill = find.text(tomorrowLabel);
      expect(tomorrowPill, findsOneWidget);

      await tester.tap(tomorrowPill);
      await tester.pumpAndSettle();

      // Summary should now reflect tomorrow's travel date
      expect(find.textContaining('Tomorrow (${tomorrow.day}'), findsOneWidget);

      // Switch to Darshan Booking tab
      final darshanTab = find.text('Darshan Booking');
      await tester.tap(darshanTab.first);
      await tester.pumpAndSettle();

      // Scroll down to see Darshan Summary
      await tester.drag(find.byType(ListView).first, const Offset(0, -350));
      await tester.pumpAndSettle();

      // Darshan booking also displays the date selector and the chosen date
      expect(find.text('Darshan Date'), findsOneWidget);
      expect(find.textContaining('Tomorrow (${tomorrow.day}'), findsOneWidget);
    });
  });
}
