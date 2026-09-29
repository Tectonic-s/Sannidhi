import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sannidhi/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Notification & Reminders Service Tests', () {
    test('Festival reminder can be saved, checked, and cancelled persistently', () async {
      final notifService = NotificationService.instance;

      // Initially not set
      final initialCheck = await notifService.isFestivalReminderSet('fest_101');
      expect(initialCheck, isFalse);

      // Set festival reminder
      final setSuccess = await notifService.setFestivalReminder(
        festivalId: 'fest_101',
        festivalName: 'Panguni Uthiram',
        festivalDate: DateTime(2026, 10, 15),
        isTamil: false,
      );
      expect(setSuccess, isTrue);

      // Verify persistence
      final checkAfterSet = await notifService.isFestivalReminderSet('fest_101');
      expect(checkAfterSet, isTrue);

      // Cancel festival reminder
      await notifService.cancelFestivalReminder('fest_101');
      final checkAfterCancel = await notifService.isFestivalReminderSet('fest_101');
      expect(checkAfterCancel, isFalse);
    });

    test('Multiple festival reminders maintain independent states', () async {
      final notifService = NotificationService.instance;

      await notifService.setFestivalReminder(
        festivalId: 'fest_A',
        festivalName: 'Thaipusam',
        dateStr: '2026-11-01',
      );
      await notifService.setFestivalReminder(
        festivalId: 'fest_B',
        festivalName: 'Karthigai Deepam',
        dateStr: '2026-11-20',
      );

      expect(await notifService.isFestivalReminderSet('fest_A'), isTrue);
      expect(await notifService.isFestivalReminderSet('fest_B'), isTrue);
      expect(await notifService.isFestivalReminderSet('fest_C'), isFalse);

      await notifService.cancelFestivalReminder('fest_A');
      expect(await notifService.isFestivalReminderSet('fest_A'), isFalse);
      expect(await notifService.isFestivalReminderSet('fest_B'), isTrue);
    });

    test('Pass and booking notifications execute gracefully in test environment', () async {
      final notifService = NotificationService.instance;

      // Should complete without throwing unhandled exceptions
      await notifService.notifyBookingConfirmed(
        bookingId: 'BK-TEST-1234',
        title: 'Special VIP Darshan',
        slotTime: '10:00 AM - 11:30 AM',
        date: '2026-09-29',
        seatCount: 2,
      );

      await notifService.notifyPassScanned(
        ticketId: 'MRD-DRS-1234-1',
        passTitle: 'Special VIP Darshan',
        verifiedBy: 'North Gate Warden',
      );

      await notifService.notifyPassExpired(
        ticketId: 'MRD-DRS-1234-1',
        slotTime: '10:00 AM - 11:30 AM',
      );

      expect(true, isTrue);
    });
  });
}
