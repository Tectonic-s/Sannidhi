import 'package:flutter/material.dart';
import '../data/models/activity_models.dart';

class UserActivityProvider extends ChangeNotifier {
  // New booking lists
  final List<ShuttleBooking> _shuttleBookings = [];
  final List<DarshanBooking> _darshanBookings = [];
  final List<DonationReceipt> _donationReceipts = [];

  // Legacy lists (kept for backward compat with tax_receipt_service etc.)
  final List<ShuttleTicketModel> _shuttleTickets = [];
  final List<DarshanTicketModel> _darshanTickets = [];
  final List<DonationReceiptModel> _donations = [];

  // ── New getters ─────────────────────────────────────────────────────────────

  List<ShuttleBooking> get shuttleBookings =>
      List.unmodifiable(_shuttleBookings);

  List<ShuttleBooking> get activeShuttleBookings =>
      _shuttleBookings.where((b) => !b.isCancelled).toList();

  List<DarshanBooking> get darshanBookings =>
      List.unmodifiable(_darshanBookings);

  List<DonationReceipt> get donationReceipts =>
      List.unmodifiable(_donationReceipts);

  // ── Legacy getters (used by existing screens) ───────────────────────────────

  List<ShuttleTicketModel> get shuttleTickets =>
      List.unmodifiable(_shuttleTickets);

  List<ShuttleTicketModel> get activeShuttleTickets =>
      _shuttleTickets.where((t) => !t.isCancelled).toList();

  List<DarshanTicketModel> get darshanTickets =>
      List.unmodifiable(_darshanTickets);

  List<DonationReceiptModel> get donations => List.unmodifiable(_donations);

  // ── New add methods ─────────────────────────────────────────────────────────

  void addShuttleBooking(ShuttleBooking booking) {
    _shuttleBookings.insert(0, booking);
    notifyListeners();
  }

  void addDarshanBooking(DarshanBooking booking) {
    _darshanBookings.insert(0, booking);
    notifyListeners();
  }

  void addDonationReceipt(DonationReceipt receipt) {
    _donationReceipts.insert(0, receipt);
    notifyListeners();
  }

  void cancelShuttleBooking(String bookingId) {
    final idx = _shuttleBookings.indexWhere((b) => b.bookingId == bookingId);
    if (idx != -1) {
      _shuttleBookings[idx].isCancelled = true;
      notifyListeners();
    }
  }

  // ── Legacy add methods (kept for donation_screen, tax_receipt_service) ──────

  void addDonation(DonationReceiptModel receipt) {
    _donations.insert(0, receipt);
    notifyListeners();
  }

  // ── Computed ────────────────────────────────────────────────────────────────

  int get totalDonated =>
      _donationReceipts.fold(0, (s, d) => s + d.amount) +
      _donations.fold(0, (s, d) => s + d.amount);

  int get activePassCount =>
      activeShuttleBookings.length + _darshanBookings.length;

  // ── Ticket ID generator ─────────────────────────────────────────────────────

  static String generateBookingId(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final suffix = (ts % 10000).toString().padLeft(4, '0');
    return '$prefix-$suffix';
  }

  static List<IndividualTicket> generateTickets({
    required String bookingId,
    required int count,
    required String type,
    required String slot,
    required String date,
  }) {
    return List.generate(count, (i) {
      final id = 'MRD-$type-${bookingId.split('-').last}-${i + 1}';
      final qr = 'SANNIDHI|$type|$id|$slot|$date|${i + 1}of$count';
      return IndividualTicket(
        ticketId: id,
        qrPayload: qr,
        ticketLabel: 'Ticket ${i + 1} of $count',
      );
    });
  }
}
