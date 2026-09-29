import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/core/utils/validators.dart';
import 'package:sannidhi/presentation/views/auth/login_screen.dart';
import 'package:sannidhi/providers/accessibility_provider.dart';
import 'package:sannidhi/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Validators Unit Tests - Email Validation', () {
    test('Empty or null email fails validation', () {
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('   '), isNotNull);
      expect(
        Validators.validateEmail('', isTamil: true),
        contains('மின்னஞ்சல்'),
      );
    });

    test('Email exceeding 254 characters fails validation', () {
      final longEmail = '${"a" * 245}@domain.com';
      expect(longEmail.length, greaterThan(254));
      expect(Validators.validateEmail(longEmail), contains('too long'));
      expect(Validators.validateEmail(longEmail, isTamil: true), contains('நீளமாக'));
    });

    test('Invalid email formats fail validation', () {
      expect(Validators.validateEmail('plainaddress'), isNotNull);
      expect(Validators.validateEmail('#@%^%#\$@#\$@#.com'), isNotNull);
      expect(Validators.validateEmail('@example.com'), isNotNull);
      expect(Validators.validateEmail('devotee@'), isNotNull);
      expect(Validators.validateEmail('devotee@example'), isNotNull);
      expect(Validators.validateEmail('devotee@.com'), isNotNull);
      expect(Validators.validateEmail('devotee..test@example.com'), isNotNull);
      expect(Validators.validateEmail('devotee@example..com'), isNotNull);
      expect(Validators.validateEmail('devotee@example.c'), isNotNull); // TLD must be >= 2 chars
    });

    test('Valid email formats pass validation', () {
      expect(Validators.validateEmail('devotee@sannidhi.app'), isNull);
      expect(Validators.validateEmail('staff@sannidhi.app'), isNull);
      expect(Validators.validateEmail('admin@sannidhi.app'), isNull);
      expect(Validators.validateEmail('user.name+tag@sub.domain.co.in'), isNull);
      expect(Validators.validateEmail('murugan_bhaktar108@temple.org'), isNull);
    });
  });

  group('Validators Unit Tests - Password Validation', () {
    test('Sign In: Empty or under 6 characters fails validation', () {
      expect(Validators.validatePassword(null, isRegister: false), isNotNull);
      expect(Validators.validatePassword('', isRegister: false), isNotNull);
      expect(Validators.validatePassword('12345', isRegister: false), contains('at least 6'));
      expect(
        Validators.validatePassword('12345', isRegister: false, isTamil: true),
        contains('6 எழுத்துக்கள்'),
      );
      // Valid sign in passwords
      expect(Validators.validatePassword('123456', isRegister: false), isNull);
      expect(Validators.validatePassword('Devotee@123', isRegister: false), isNull);
    });

    test('Sign Up: Requires min 8 chars, uppercase, lowercase, digit, special symbol', () {
      expect(Validators.validatePassword(null, isRegister: true), isNotNull);
      expect(Validators.validatePassword('', isRegister: true), isNotNull);
      expect(Validators.validatePassword(' Abc@123', isRegister: true), contains('spaces'));
      expect(Validators.validatePassword('Abc@123 ', isRegister: true), contains('spaces'));

      // < 8 characters
      expect(Validators.validatePassword('Ab1@', isRegister: true), contains('at least 8'));

      // Missing uppercase
      expect(Validators.validatePassword('devotee@123', isRegister: true), contains('uppercase'));

      // Missing lowercase
      expect(Validators.validatePassword('DEVOTEE@123', isRegister: true), contains('lowercase'));

      // Missing number
      expect(Validators.validatePassword('Devotee@Temple', isRegister: true), contains('number'));

      // Missing special character
      expect(Validators.validatePassword('Devotee12345', isRegister: true), contains('special'));

      // Exceeding 128 characters
      expect(Validators.validatePassword('A1@${"a" * 126}', isRegister: true), contains('128'));
    });

    test('Sign Up: Valid industry standard passwords pass', () {
      expect(Validators.validatePassword('Devotee@123', isRegister: true), isNull);
      expect(Validators.validatePassword('Staff@2026!', isRegister: true), isNull);
      expect(Validators.validatePassword('Marudamalai#108', isRegister: true), isNull);
      expect(Validators.validatePassword('Sannidhi\$Secure99', isRegister: true), isNull);
    });

    test('checkPasswordStrength computes score accurately', () {
      final s0 = Validators.checkPasswordStrength('');
      expect(s0.score, 0);
      expect(s0.isFullStrength, isFalse);

      final sPartial = Validators.checkPasswordStrength('Devotee123'); // No special char
      expect(sPartial.hasMinLength, isTrue);
      expect(sPartial.hasUppercase, isTrue);
      expect(sPartial.hasLowercase, isTrue);
      expect(sPartial.hasDigit, isTrue);
      expect(sPartial.hasSpecial, isFalse);
      expect(sPartial.score, 4);
      expect(sPartial.isFullStrength, isFalse);

      final sFull = Validators.checkPasswordStrength('Devotee@123');
      expect(sFull.score, 5);
      expect(sFull.isFullStrength, isTrue);
    });
  });

  group('LoginScreen Form Validation Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ta')],
          home: LoginScreen(isInitialLaunch: true),
        ),
      );
    }

    testWidgets('Submitting empty form triggers email and password validation errors', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Sign In button with empty fields
      final submitBtn = find.text('Sign In');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Switching to Register renders live password requirements checklist and updates on typing', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "Don't have an account? Register"
      final toggleRegister = find.text("Don't have an account? Register");
      await tester.ensureVisible(toggleRegister);
      await tester.tap(toggleRegister);
      await tester.pumpAndSettle();

      // Requirements checklist must be visible
      expect(find.text('Password Requirements:'), findsOneWidget);
      expect(find.text('8+ Characters'), findsOneWidget);
      expect(find.text('Uppercase (A-Z)'), findsOneWidget);
      expect(find.text('Lowercase (a-z)'), findsOneWidget);
      expect(find.text('Number (0-9)'), findsOneWidget);
      expect(find.text('Special (!@#\$)'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);

      // Enter password in password field
      final passwordField = find.byType(TextFormField).at(3); // Name, Email, Phone, Password
      await tester.enterText(passwordField, 'Devotee@123');
      await tester.pumpAndSettle();

      // Live strength score should update to 5/5
      expect(find.text('5/5'), findsOneWidget);
    });
  });
}
