import 'package:flutter_test/flutter_test.dart';
import 'package:sannidhi/core/utils/booking_utils.dart';
import 'package:sannidhi/data/models/activity_models.dart';

void main() {
  group('Ticket Expiration Logic Tests', () {
    test('Identifies past date as expired when not used', () {
      final now = DateTime(2026, 9, 28, 12, 0); // 12:00 PM on Sep 28
      final pastExpired = isBookingExpired(
        slotTime: '10:00 AM - 11:30 AM',
        date: '2026-09-27',
        now: now,
      );
      expect(pastExpired, isTrue);
    });

    test('Identifies future date as not expired', () {
      final now = DateTime(2026, 9, 28, 12, 0);
      final futureNotExpired = isBookingExpired(
        slotTime: '09:00 AM',
        date: '2026-09-29',
        now: now,
      );
      expect(futureNotExpired, isFalse);
    });

    test('Identifies slot on current date: past slot is expired', () {
      final now = DateTime(2026, 9, 28, 14, 0); // 2:00 PM
      final pastSlotExpired = isBookingExpired(
        slotTime: '10:00 AM - 11:30 AM', // ended at 11:30 AM
        date: '2026-09-28',
        now: now,
      );
      expect(pastSlotExpired, isTrue);
    });

    test('Identifies slot on current date: upcoming slot is not expired', () {
      final now = DateTime(2026, 9, 28, 10, 0); // 10:00 AM
      final upcomingNotExpired = isBookingExpired(
        slotTime: '11:00 AM - 12:30 PM', // ends at 12:30 PM
        date: '2026-09-28',
        now: now,
      );
      expect(upcomingNotExpired, isFalse);
    });

    test('IndividualTicket isExpired helper correctly accounts for isUsed', () {
      final now = DateTime(2026, 9, 28, 14, 0);
      final ticket = IndividualTicket(
        ticketId: 'MRD-DRS-001',
        qrPayload: 'SANNIDHI|DRS|MRD-DRS-001|10:00 AM - 11:30 AM|2026-09-28|1of1',
        ticketLabel: 'Ticket 1 of 1',
        slotTime: '10:00 AM - 11:30 AM',
        date: '2026-09-28',
        isUsed: false,
      );

      // Not used and slot is past -> expired
      expect(ticket.isExpired(now: now), isTrue);

      // Once scanned / used -> never expired
      ticket.isUsed = true;
      ticket.usedAt = now;
      expect(ticket.isExpired(now: now), isFalse);
    });

    test('ShuttleBooking and DarshanBooking isExpired getters work', () {
      final now = DateTime.now();
      final shuttle = ShuttleBooking(
        bookingId: 'BK-SH-01',
        slotTime: '01:00 AM', // Past slot
        totalFare: 20,
        seatCount: 1,
        tickets: [
          IndividualTicket(
            ticketId: 'MRD-BUS-01-1',
            qrPayload: 'SANNIDHI|BUS|MRD-BUS-01-1',
            ticketLabel: 'Ticket 1 of 1',
            slotTime: '01:00 AM',
            date: '2026-09-20', // past date
            isUsed: false,
          ),
        ],
        timestamp: now,
        date: '2026-09-20',
      );

      expect(shuttle.isExpired, isTrue);

      // If all used, not expired
      shuttle.tickets.first.isUsed = true;
      expect(shuttle.isExpired, isFalse);
    });
  });
}
