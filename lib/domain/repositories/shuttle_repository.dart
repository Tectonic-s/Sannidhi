import '../../data/models/shuttle_booking_model.dart';

abstract class ShuttleRepository {
  List<ShuttleBookingModel> getBookings();
  List<ShuttleBookingModel> getAvailableBookings();
  ShuttleBookingModel? getBookingById(String id);
  void bookShuttle(ShuttleBookingModel booking);
  void cancelBooking(String id);
  int getAvailableSeats(String bookingId);
}
