import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sannidhi/core/widgets/announcement_ticker.dart';
import 'package:sannidhi/providers/bulletin_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BulletinProvider & Live Bulletins Tests', () {
    test('initializes with the 2 required core bulletins', () async {
      final provider = BulletinProvider();
      await provider.init();

      expect(provider.items.length, 2);
      expect(provider.coreBulletins.length, 2);
      expect(provider.customBulletins.length, 0);

      // Verify Bulletin 1: Two-wheeler safety cutoff after 5pm
      final b1 = provider.items[0];
      expect(b1.categoryEn, 'SAFETY ADVISORY');
      expect(b1.categoryTa, 'பாதுகாப்பு எச்சரிக்கை');
      expect(b1.textEn, 'Two-wheelers are not allowed for travel to the hilltop after 5:00 PM for safety purposes.');
      expect(b1.textTa, 'பாதுகாப்பு காரணங்களுக்காக மாலை 5:00 மணிக்கு மேல் இருசக்கர வாகனங்கள் மலைப்பாதையில் செல்ல அனுமதி இல்லை.');
      expect(b1.icon, Icons.two_wheeler_rounded);

      // Verify Bulletin 2: Special recitations everyday at 6pm
      final b2 = provider.items[1];
      expect(b2.categoryEn, 'DAILY RECITATION');
      expect(b2.categoryTa, 'தினசரி பாராயணம்');
      expect(b2.textEn, 'Special recitations everyday at 6:00 PM at the temple.');
      expect(b2.textTa, 'திருக்கோயிலில் தினமும் மாலை 6:00 மணிக்கு சிறப்பு கூட்டுப் பாராயணம் நடைபெறும்.');
      expect(b2.icon, Icons.auto_stories_rounded);
    });

    test('admin can dynamically add 2 or more custom live bulletins', () async {
      final provider = BulletinProvider();
      await provider.init();

      // Admin adds custom bulletin 1
      await provider.addBulletin(
        categoryEn: 'SPECIAL DARSHAN',
        categoryTa: 'சிறப்பு தரிசனம்',
        textEn: 'Golden chariot procession will take place at 7:30 PM today.',
        textTa: 'இன்று மாலை 7:30 மணிக்கு தங்கத் தேர் புறப்பாடு நடைபெறும்.',
        icon: Icons.auto_awesome,
        accentColor: const Color(0xFFD97706),
      );

      // Admin adds custom bulletin 2
      await provider.addBulletin(
        categoryEn: 'WEATHER ADVISORY',
        categoryTa: 'வானிலை எச்சரிக்கை',
        textEn: 'Pleasant hilltop breeze and clear steps for climbing.',
        textTa: 'மலைப்பாதையில் இதமான காற்று வீசுகிறது, படிகள் ஏறுவதற்கு ஏற்ற வானிலை.',
        icon: Icons.wb_sunny_rounded,
        accentColor: const Color(0xFF2563EB),
      );

      // Total bulletins is now 4 (2 core + 2 custom)
      expect(provider.items.length, 4);
      expect(provider.coreBulletins.length, 2);
      expect(provider.customBulletins.length, 2);

      // Verify custom bulletins have isCustom = true
      expect(provider.customBulletins[0].isCustom, isTrue);
      expect(provider.customBulletins[1].isCustom, isTrue);
      expect(provider.customBulletins[0].categoryEn, 'WEATHER ADVISORY');
      expect(provider.customBulletins[1].categoryEn, 'SPECIAL DARSHAN');

      // Admin can remove a custom bulletin
      final toRemoveId = provider.customBulletins[0].id;
      await provider.removeBulletin(toRemoveId);

      expect(provider.items.length, 3);
      expect(provider.customBulletins.length, 1);
    });

    testWidgets('AnnouncementTicker renders the 2 core bulletins and updates when admin adds a bulletin', (tester) async {
      final provider = BulletinProvider();
      await provider.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnouncementTicker(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LIVE BULLETIN'), findsOneWidget);
      expect(find.text('SAFETY ADVISORY'), findsOneWidget);
      expect(find.textContaining('Two-wheelers are not allowed for travel to the hilltop after 5:00 PM'), findsOneWidget);
    });
  });
}
