// Individual ticket — one QR per seat/devotee (BookMyShow style)
class IndividualTicket {
  final String ticketId;      // e.g. MRD-BUS-8491-1
  final String qrPayload;
  final String ticketLabel;   // e.g. "Ticket 1 of 3"

  const IndividualTicket({
    required this.ticketId,
    required this.qrPayload,
    required this.ticketLabel,
  });
}

// ── Shuttle ───────────────────────────────────────────────────────────────────

class ShuttleBooking {
  final String bookingId;
  final String slotTime;
  final double totalFare;
  final int seatCount;
  final List<IndividualTicket> tickets;
  final DateTime timestamp;
  final String date;
  bool isCancelled;

  ShuttleBooking({
    required this.bookingId,
    required this.slotTime,
    required this.totalFare,
    required this.seatCount,
    required this.tickets,
    required this.timestamp,
    required this.date,
    this.isCancelled = false,
  });
}

// ── Darshan ───────────────────────────────────────────────────────────────────

class DarshanBooking {
  final String bookingId;
  final String darshanType;   // Normal / Special / VIP
  final String slotTime;
  final double totalAmount;
  final int ticketCount;
  final List<IndividualTicket> tickets;
  final DateTime timestamp;
  final String date;

  const DarshanBooking({
    required this.bookingId,
    required this.darshanType,
    required this.slotTime,
    required this.totalAmount,
    required this.ticketCount,
    required this.tickets,
    required this.timestamp,
    required this.date,
  });
}

// ── Donation ──────────────────────────────────────────────────────────────────

class DonationReceipt {
  final String transactionId;
  final String causeName;
  final int amount;
  final String panNumber;
  final DateTime timestamp;
  final String qrPayload;
  final String ref80g;

  const DonationReceipt({
    required this.transactionId,
    required this.causeName,
    required this.amount,
    this.panNumber = 'AAATM1234F',
    required this.timestamp,
    required this.qrPayload,
    required this.ref80g,
  });

  String get dateStr {
    final d = timestamp;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

// ── Legacy aliases (keep old screens compiling) ───────────────────────────────

class ShuttleTicketModel {
  final String ticketId;
  final String slot;
  final int seatCount;
  final String qrPayload;
  final double fare;
  final String date;
  final String pickupLocation;
  final String dropLocation;
  bool isCancelled;

  ShuttleTicketModel({
    required this.ticketId,
    required this.slot,
    required this.seatCount,
    required this.qrPayload,
    required this.fare,
    required this.date,
    required this.pickupLocation,
    required this.dropLocation,
    this.isCancelled = false,
  });
}

class DarshanTicketModel {
  final String ticketId;
  final String darshanType;
  final String slot;
  final String devoteeName;
  final String qrPayload;
  final double fare;
  final String date;

  const DarshanTicketModel({
    required this.ticketId,
    required this.darshanType,
    required this.slot,
    required this.devoteeName,
    required this.qrPayload,
    required this.fare,
    required this.date,
  });
}

class DonationReceiptModel {
  final String transactionId;
  final String cause;
  final int amount;
  final DateTime timestamp;
  final String qrPayload;
  final String ref80g;

  const DonationReceiptModel({
    required this.transactionId,
    required this.cause,
    required this.amount,
    required this.timestamp,
    required this.qrPayload,
    required this.ref80g,
  });

  String get dateStr {
    final d = timestamp;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
