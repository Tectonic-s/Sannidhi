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
