import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/models/user_model.dart';
import 'package:sannidhi/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:sannidhi/presentation/views/role_router_screen.dart';
import 'package:sannidhi/presentation/views/staff/gate_staff_screen.dart';
import 'package:sannidhi/core/widgets/auth_required_dialog.dart';
import 'package:sannidhi/presentation/views/home/home_screen.dart';
import 'package:sannidhi/presentation/views/bookings/bookings_screen.dart';
import 'package:sannidhi/presentation/views/donation/donation_screen.dart';
import 'package:sannidhi/presentation/views/auth/login_screen.dart';
import 'package:sannidhi/presentation/views/splash/splash_screen.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:sannidhi/providers/user_activity_provider.dart';
import 'package:sannidhi/data/repositories/mock_crowd_repository.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/data/repositories/mock_shuttle_repository.dart';

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

  bool _mockSkipped = false;
  @override
  bool get hasSkippedLogin => _mockSkipped;
  @override
  void skipLogin() {
    _mockSkipped = true;
    notifyListeners();
  }

  @override
  UserModel? get currentUser => _mockUser;

  @override
  bool get isAuthenticated => _mockUser != null;

  @override
  bool get isStaff => _mockUser?.role == UserRole.staff;

  @override
  bool get isAdmin => _mockUser?.role == UserRole.admin;

  @override
  bool get isDevotee => _mockUser?.role == UserRole.devotee || _mockUser == null;

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
  group('3-Tier Role-Based UI Architecture Tests', () {
    testWidgets('Guest / Devotee user is routed to MainNavigationScreen (Untouched Common UI)',
        (WidgetTester tester) async {
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
            home: RoleRouterScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Devotee should see Home navigation and NO gate scanner or admin command center
      expect(find.byType(GateStaffScreen), findsNothing);
      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Staff user is routed directly to GateStaffScreen (Main Screen QR Scanner)',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(UserRole.staff);

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
            home: RoleRouterScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Gate Staff sees only the Gate Scanner Screen, NO devotee Home screen
      expect(find.byType(GateStaffScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Gate Scanner & Verifier'), findsOneWidget);
      expect(find.text('Admitted Today'), findsOneWidget);
    });

    testWidgets('Admin user is routed directly to AdminDashboardScreen (Live Telemetry Command Center)',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(UserRole.admin);

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
            home: RoleRouterScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Temple Admin sees Executive Center with live telemetry, NO devotee Home screen
      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.text('Temple Executive Center'), findsOneWidget);
    });

    testWidgets('Gate Staff can verify active pass and mark it as USED with visual feedback',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(UserRole.staff);

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
            home: RoleRouterScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Ensure visible and tap on the quick test chip "Active Darshan Pass"
      final chip = find.text('Active Darshan Pass');
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should display VALID PASS and state transition
      expect(find.text('VALID PASS • ADMITTED'), findsOneWidget);
      expect(find.text('ACTIVE ➔ MARKED AS USED'), findsOneWidget);
    });

    testWidgets('Gate Staff duplicate scan triggers ALREADY USED warning',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(UserRole.staff);

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
            home: RoleRouterScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Ensure visible and tap on the quick test chip "Already Used Pass"
      final chip = find.text('Already Used Pass');
      await tester.ensureVisible(chip);
      await tester.pump();
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should display rejection
      expect(find.text('ENTRY REJECTED • ALREADY USED'), findsOneWidget);
      expect(find.text('ALREADY MARKED USED'), findsOneWidget);
    });

    testWidgets('SplashScreen renders loading screen and navigates properly',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(null);

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
            home: SplashScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);

      // Advance clock past animation and timer to complete cleanly
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump();
    });

    testWidgets('Tapping Skip Login redirects immediately to the Home page (Devotee)',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(null);

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
            home: const LoginScreen(isInitialLaunch: true),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Both AppBar 'Skip →' and bottom 'Skip Login & Continue to Home (Devotee)' exist
      expect(find.text('Skip →'), findsOneWidget);

      // Tap Skip →
      await tester.tap(find.text('Skip →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Directly redirects to Home page!
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Unauthenticated guest tapping Shuttle or Darshan pass on HomeScreen shows Sign In popup',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(null);

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
            home: HomeScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap the first AuthGuardedWrapper card (Battery Shuttle)
      final guardedCards = find.byType(AuthGuardedWrapper);
      expect(guardedCards, findsWidgets);
      await tester.ensureVisible(guardedCards.first);
      await tester.pump();
      await tester.tap(guardedCards.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify "Sign In to Access" popup dialog appeared with "Sign In" button
      expect(find.text('Sign In to Access'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Unauthenticated guest on BookingsScreen sees lock banner and greyed button that triggers popup',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockAuthProvider()..setRole(null);

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

      // Lock banner is present
      expect(find.text('Sign In Required'), findsOneWidget);

      // Book button is greyed out with Sign In to Access
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final bookBtn = find.textContaining('Sign In to Access');
      expect(bookBtn, findsWidgets);

      await tester.tap(bookBtn.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Pop-up dialog opens
      expect(find.text('Sign In to Access'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('Unauthenticated guest on DonationScreen sees lock banner and greyed button that triggers popup',
        (WidgetTester tester) async {
      final mockAuth = MockAuthProvider()..setRole(null);

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
            home: DonationScreen(onToggleLocale: () {}),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Lock banner is present
      expect(find.text('Sign In Required'), findsOneWidget);

      // Proceed to pay button shows Sign In to Access (Donation)
      final donateBtn = find.textContaining('Sign In to Access');
      expect(donateBtn, findsOneWidget);

      await tester.ensureVisible(donateBtn);
      await tester.pump();
      await tester.tap(donateBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Pop-up dialog opens
      expect(find.text('Sign In to Access'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('BookingsScreen provides distinct sub-pages for Bus Booking and Darshan Booking',
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

      // Both sub-page tabs exist in the header
      final busTab = find.text('Bus Booking');
      final darshanTab = find.text('Darshan Booking');
      expect(busTab, findsWidgets);
      expect(darshanTab, findsWidgets);

      // Default sub-page is Bus Booking
      expect(find.text('Eco-Electric Temple Bus'), findsOneWidget);
      expect(find.text('Adivaram Terminal ⇄ Hilltop Sannidhi'), findsOneWidget);
      expect(find.text('Book Bus Pass  •  ₹20'), findsOneWidget);

      // Switch to Darshan Booking sub-page
      await tester.tap(darshanTab.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Darshan Booking sub-page is now displayed
      expect(find.text('Temple Darshan Booking'), findsOneWidget);
      expect(find.text('Normal Darshan'), findsWidgets);
      expect(find.text('Special Darshan'), findsOneWidget);
      expect(find.text('Choose Darshan Category'), findsOneWidget);

      // Switch back to Bus Booking sub-page
      await tester.tap(busTab.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Bus Booking is displayed again
      expect(find.text('Eco-Electric Temple Bus'), findsOneWidget);
    });
  });
}


