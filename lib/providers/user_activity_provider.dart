import 'package:flutter/material.dart';
import '../data/models/activity_models.dart';

class UserActivityProvider extends ChangeNotifier {
  final List<ShuttleTicketModel> _shuttleTickets = [];
  final List<DarshanTicketModel> _darshanTickets = [];
  final List<DonationReceiptModel> _donations = [];

  List<ShuttleTicketModel> get shuttleTickets =>
      List.unmodifiable(_shuttleTickets);
  List<ShuttleTicketModel> get activeShuttleTickets =>
      _shuttleTickets.where((t) => !t.isCancelled).toList();
  List<DarshanTicketModel> get darshanTickets =>
      List.unmodifiable(_darshanTickets);
  List<DonationReceiptModel> get donations => List.unmodifiable(_donations);

  void addShuttleBooking(ShuttleTicketModel ticket) {
    _shuttleTickets.insert(0, ticket);
    notifyListeners();
  }

  void cancelShuttleBooking(String ticketId) {
    final idx = _shuttleTickets.indexWhere((t) => t.ticketId == ticketId);
    if (idx != -1) {
      _shuttleTickets[idx].isCancelled = true;
      notifyListeners();
    }
  }

  void addDarshanBooking(DarshanTicketModel ticket) {
    _darshanTickets.insert(0, ticket);
    notifyListeners();
  }

  void addDonation(DonationReceiptModel receipt) {
    _donations.insert(0, receipt);
    notifyListeners();
  }

  int get totalDonated =>
      _donations.fold(0, (sum, d) => sum + d.amount);

  int get activePassCount =>
      activeShuttleTickets.length + _darshanTickets.length;
}
