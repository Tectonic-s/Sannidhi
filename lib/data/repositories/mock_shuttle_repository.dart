import 'package:flutter/material.dart';
import '../../domain/repositories/shuttle_repository.dart';
import '../models/shuttle_booking_model.dart';

class MockShuttleRepository with ChangeNotifier implements ShuttleRepository {
  final List<ShuttleBookingModel> _bookings = [
    ShuttleBookingModel(
      id: 'SB001',
      date: '2025-03-15',
      time: '06:00 AM',
      status: 'Confirmed',
      pickupLocation: 'Main Bus Stand',
      dropLocation: 'Temple Entrance',
      seats: 45,
      price: 50.0,
    ),
    ShuttleBookingModel(
      id: 'SB002',
      date: '2025-03-15',
      time: '08:00 AM',
      status: 'Available',
      pickupLocation: 'City Center',
      dropLocation: 'Temple Entrance',
      seats: 38,
      price: 75.0,
    ),
    ShuttleBookingModel(
      id: 'SB003',
      date: '2025-03-15',
      time: '10:00 AM',
      status: 'Available',
      pickupLocation: 'Main Bus Stand',
      dropLocation: 'Temple Entrance',
      seats: 45,
      price: 50.0,
    ),
  ];

  @override
  List<ShuttleBookingModel> getBookings() => _bookings;

  @override
  List<ShuttleBookingModel> getAvailableBookings() =>
      _bookings.where((b) => b.status == 'Available').toList();

  @override
  ShuttleBookingModel? getBookingById(String id) {
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void bookShuttle(ShuttleBookingModel booking) {
    _bookings.add(booking);
    notifyListeners();
  }

  @override
  void cancelBooking(String id) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bookings[index] = _bookings[index].copyWith(status: 'Cancelled');
      notifyListeners();
    }
  }

  @override
  int getAvailableSeats(String bookingId) =>
      getBookingById(bookingId)?.seats ?? 0;
}
