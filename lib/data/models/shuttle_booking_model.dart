class ShuttleBookingModel {
  final String id;
  final String date;
  final String time;
  final String status;
  final String pickupLocation;
  final String dropLocation;
  final int seats;
  final double price;
  
  ShuttleBookingModel({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    required this.pickupLocation,
    required this.dropLocation,
    required this.seats,
    required this.price,
  });
  
  factory ShuttleBookingModel.fromJson(Map<String, dynamic> json) {
    return ShuttleBookingModel(
      id: json['id'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      status: json['status'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropLocation: json['drop_location'] as String,
      seats: json['seats'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'status': status,
      'pickup_location': pickupLocation,
      'drop_location': dropLocation,
      'seats': seats,
      'price': price,
    };
  }
  
  ShuttleBookingModel copyWith({
    String? id,
    String? date,
    String? time,
    String? status,
    String? pickupLocation,
    String? dropLocation,
    int? seats,
    double? price,
  }) {
    return ShuttleBookingModel(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropLocation: dropLocation ?? this.dropLocation,
      seats: seats ?? this.seats,
      price: price ?? this.price,
    );
  }
}
