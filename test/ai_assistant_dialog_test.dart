import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sannidhi/presentation/views/ai_assistant_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Thunai AI Assistant Knowledge & Cost Estimation Tests', () {
    testWidgets('renders AI Assistant dialog and initial greeting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Thunai'), findsOneWidget);
      expect(find.text('On-Device AI'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('accurately calculates quick visit cost for a family of 8', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'how much will it cost to quickly visit the temple for a family of 8');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Quick visit: 8 * 50 (passes) + 8 * 20 (bus) = 560
      expect(find.textContaining('Visit Cost Estimation for a family of 8'), findsOneWidget);
      expect(find.textContaining('₹560'), findsOneWidget);
      expect(find.textContaining('Special Darshan Pass (8 × ₹50): ₹400'), findsOneWidget);
      expect(find.textContaining('Electric Bus (8 × ₹20): ₹160'), findsOneWidget);
      expect(find.textContaining('VIP Direct Access Visit'), findsOneWidget);
      expect(find.textContaining('₹2160'), findsOneWidget);
    });

    testWidgets('answers festival date query for Deepavali with correct calendar data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'when is Deepavali festival?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Deepavali'), findsWidgets);
      expect(find.textContaining('2026-11-09'), findsOneWidget);
    });

    testWidgets('answers why Thaipusam is special with mythological lore and Vel significance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'why is Thaipusam special and celebrated?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verifies deep mythological answer
      expect(find.textContaining('Why Thaipusam'), findsOneWidget);
      expect(find.textContaining('Gnana Vel'), findsOneWidget);
      expect(find.textContaining('Goddess Parvati'), findsOneWidget);
      expect(find.textContaining('Kavadis'), findsOneWidget);
      expect(find.textContaining('2027-01-22'), findsOneWidget);
    });

    testWidgets('answers festival significance query in pure Tamil', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'தைப்பூசம் ஏன் சிறப்பு?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verifies Tamil cultural and theological lore
      expect(find.textContaining('ஞானவேலை'), findsOneWidget);
      expect(find.textContaining('அன்னை பராசக்தி'), findsOneWidget);
      expect(find.textContaining('காவடி'), findsOneWidget);
    });

    testWidgets('provides crowd guidance for what time to visit the temple', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'what time should i visit the temple on a specific day?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Best Time to Visit Marudamalai & Crowd Guidance'), findsOneWidget);
      expect(find.textContaining('6:00 AM – 8:30 AM'), findsOneWidget);
      expect(find.textContaining('Peak / Rush Hours'), findsOneWidget);
    });

    testWidgets('answers facility query for drinking water with step locations', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'where can i get drinking water while climbing?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Step 200'), findsOneWidget);
      expect(find.textContaining('Step 500'), findsOneWidget);
      expect(find.textContaining('Step 830'), findsOneWidget);
    });

    testWidgets('answers pooja timings with 5 Kaalam details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'what are the pooja timings today?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Daily 5 Kaalam Pooja Schedule'), findsOneWidget);
      expect(find.textContaining('Thiruvanandal Pooja'), findsOneWidget);
      expect(find.textContaining('Kalasanthi Pooja'), findsOneWidget);
      expect(find.textContaining('Uchikalam Pooja'), findsOneWidget);
      expect(find.textContaining('Sayarakshai Pooja'), findsOneWidget);
      expect(find.textContaining('Ardhajamam Pooja'), findsOneWidget);
    });

    testWidgets('answers Pambatti Siddhar history and sacred cave lore', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'tell me about pambatti siddhar cave');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Pambatti Siddhar Cave & Temple Heritage'), findsOneWidget);
      expect(find.textContaining('18 Tamil Siddhars'), findsOneWidget);
      expect(find.textContaining('Marudham trees'), findsOneWidget);
    });

    testWidgets('displays AI status badge and opens configuration dialog on key tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final keyButton = find.byIcon(Icons.key);
      expect(keyButton, findsOneWidget);

      await tester.tap(keyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Gemini AI Configuration'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('answers two-wheeler 5 PM safety restriction rule in English and Tamil', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'Are two wheelers allowed to the top after 5pm?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Two-Wheeler Hilltop Travel Restriction'), findsOneWidget);
      expect(find.textContaining('strictly NOT allowed for travel to the hilltop after 5:00 PM'), findsOneWidget);
    });

    testWidgets('answers daily 6:00 PM special recitations query', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'Tell me about the special recitations everyday at 6pm');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Temple Daily Special Recitations & Sacred Parayanam'), findsOneWidget);
      expect(find.textContaining('everyday at 6:00 PM'), findsOneWidget);
      expect(find.textContaining('Kanda Sashti Kavasam'), findsOneWidget);
    });

    testWidgets('displays quick suggestion chips and tapping sends query', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('🏍️ 2-Wheeler 5PM Rule'), findsOneWidget);
      expect(find.text('🪔 6PM Recitations'), findsOneWidget);

      await tester.tap(find.text('🏍️ 2-Wheeler 5PM Rule'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Two-Wheeler Hilltop Travel Restriction'), findsOneWidget);
    });

    testWidgets('prompting "hi" responds with welcoming greeting and NEVER festival lore', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Should contain friendly greeting & topics
      expect(find.textContaining('Vanakkam! 🙏 I am Thunai AI'), findsOneWidget);
      expect(find.textContaining('How can I help you today?'), findsOneWidget);

      // Must NOT contain festival lore or specific festival breakdown
      expect(find.textContaining('Chithirai'), findsNothing);
      expect(find.textContaining('Navaratri'), findsNothing);
      expect(find.textContaining('Deepavali'), findsNothing);
      expect(find.textContaining('Skanda Sashti'), findsNothing);
      expect(find.textContaining('Thiruvathirai'), findsNothing);
    });

    testWidgets('prompting "Hi!" with punctuation responds with welcoming greeting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: false),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'Hi!');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Vanakkam! 🙏 I am Thunai AI'), findsOneWidget);
      expect(find.textContaining('Chithirai'), findsNothing);
    });

    testWidgets('prompting "வணக்கம்" responds with warm Tamil greeting without festival details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiAssistantDialog(isTamil: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final input = find.byType(TextField);
      await tester.enterText(input, 'வணக்கம்');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('வணக்கம்! 🙏 நான் துணை AI (Thunai)'), findsOneWidget);
      expect(find.textContaining('நான் உங்களுக்கு எவ்வாறு உதவ முடியும்?'), findsOneWidget);
      expect(find.textContaining('சித்திரை'), findsNothing);
    });
  });
}
