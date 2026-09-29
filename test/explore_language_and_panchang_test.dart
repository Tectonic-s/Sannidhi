import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sannidhi/core/l10n/app_localizations.dart';
import 'package:sannidhi/core/widgets/tamil_panchang_card.dart';
import 'package:sannidhi/data/repositories/mock_festival_repository.dart';
import 'package:sannidhi/presentation/views/festivals/festivals_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Explore Page Calendar & Language Strictness Tests', () {
    testWidgets('TamilPanchangCard in English mode contains strictly English text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TamilPanchangCard(isTamil: false),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check English terms
      expect(find.textContaining('Sunrise:'), findsOneWidget);
      expect(find.textContaining('Rahu:'), findsOneWidget);
      expect(find.textContaining('Tithi:'), findsOneWidget);
      expect(find.textContaining('Nakshatra:'), findsOneWidget);
      expect(find.textContaining('View Full Panchang & Timings'), findsOneWidget);

      // Verify no Tanglish or Tamil strings leak in English mode
      expect(find.textContaining('Suuriya Udhayam'), findsNothing);
      expect(find.textContaining('Suuriya Asthamanam'), findsNothing);
      expect(find.textContaining('Natchathiram'), findsNothing);
      expect(find.textContaining('மாதம்'), findsNothing);
      expect(find.textContaining('உதயம்'), findsNothing);
    });

    testWidgets('TamilPanchangCard in Tamil mode contains strictly Tamil text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TamilPanchangCard(isTamil: true),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check Tamil terms
      expect(find.textContaining('உதயம்:'), findsOneWidget);
      expect(find.textContaining('ராகு:'), findsOneWidget);
      expect(find.textContaining('திதி:'), findsOneWidget);
      expect(find.textContaining('நட்சத்திரம்:'), findsOneWidget);
      expect(find.textContaining('மாதம்'), findsOneWidget);
      expect(find.textContaining('முழு பஞ்சாங்கம் & முகூர்த்தம்'), findsOneWidget);

      // Verify no English headers leak in Tamil mode
      expect(find.textContaining('Sunrise:'), findsNothing);
      expect(find.textContaining('View Full Panchang'), findsNothing);
    });

    testWidgets('FestivalsScreen renders correctly in English and Tamil without truncation',
        (WidgetTester tester) async {
      final repo = MockFestivalRepository();

      // English Test
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockFestivalRepository>.value(value: repo),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: const [Locale('en'), Locale('ta')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FestivalsScreen(onToggleLocale: () {}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Upcoming Temple Festivals'), findsOneWidget);
      expect(find.text('15 Upcoming'), findsOneWidget);

      // Tamil Test
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MockFestivalRepository>.value(value: repo),
          ],
          child: MaterialApp(
            locale: const Locale('ta'),
            supportedLocales: const [Locale('en'), Locale('ta')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FestivalsScreen(onToggleLocale: () {}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('வரவிருக்கும் திருவிழாக்கள்'), findsOneWidget);
      expect(find.text('15 விழாக்கள்'), findsOneWidget);
    });
  });
}
