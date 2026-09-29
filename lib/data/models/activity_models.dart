import '../../core/utils/booking_utils.dart';

// Individual ticket — one QR per seat/devotee (BookMyShow style)
class IndividualTicket {
  final String ticketId;      // e.g. MRD-BUS-8491-1
  final String qrPayload;
  final String ticketLabel;   // e.g. "Ticket 1 of 3"
  bool isUsed;
  DateTime? usedAt;
  String? verifiedBy;
  String? slotTime;
  String? date;

  IndividualTicket({
    required this.ticketId,
    required this.qrPayload,
    required this.ticketLabel,
    this.isUsed = false,
    this.usedAt,
    this.verifiedBy,
    this.slotTime,
    this.date,
  });

  bool isExpired({String? fallbackSlot, String? fallbackDate, DateTime? now}) {
    if (isUsed) return false;
    final s = slotTime ?? fallbackSlot;
    final d = date ?? fallbackDate;
    if (s == null && d == null) return false;
    return isBookingExpired(slotTime: s, date: d, now: now);
  }

  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'qrPayload': qrPayload,
    'ticketLabel': ticketLabel,
    'isUsed': isUsed,
    'usedAt': usedAt?.toIso8601String(),
    'verifiedBy': verifiedBy,
    'slotTime': slotTime,
    'date': date,
  };

  factory IndividualTicket.fromJson(Map<String, dynamic> json) => IndividualTicket(
    ticketId: json['ticketId'] ?? json['id'] ?? '',
    qrPayload: json['qrPayload'] ?? json['qr_payload'] ?? '',
    ticketLabel: json['ticketLabel'] ?? json['ticket_label'] ?? '',
    isUsed: json['isUsed'] == true || json['status'] == 'USED',
    usedAt: json['usedAt'] != null
        ? DateTime.tryParse(json['usedAt'])
        : (json['verified_at'] != null ? DateTime.tryParse(json['verified_at']) : null),
    verifiedBy: json['verifiedBy'] ?? json['verified_by'],
    slotTime: json['slotTime'] ?? json['slot_time'],
    date: json['date'],
  );
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

  bool get isAllUsed => tickets.isNotEmpty && tickets.every((t) => t.isUsed);
  bool get isPartiallyUsed => tickets.any((t) => t.isUsed) && !isAllUsed;
  int get usedCount => tickets.where((t) => t.isUsed).length;
  bool get isExpired => !isAllUsed && isBookingExpired(slotTime: slotTime, date: date);
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

  DarshanBooking({
    required this.bookingId,
    required this.darshanType,
    required this.slotTime,
    required this.totalAmount,
    required this.ticketCount,
    required this.tickets,
    required this.timestamp,
    required this.date,
  });

  bool get isAllUsed => tickets.isNotEmpty && tickets.every((t) => t.isUsed);
  bool get isPartiallyUsed => tickets.any((t) => t.isUsed) && !isAllUsed;
  int get usedCount => tickets.where((t) => t.isUsed).length;
  bool get isExpired => !isAllUsed && isBookingExpired(slotTime: slotTime, date: date);
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
