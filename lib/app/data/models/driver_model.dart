import '../../domain/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  DriverModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.email,
    required super.vehicleType,
    required super.vehiclePlate,
    required super.isOnline,
    required super.isActive,
    required super.rating,
    required super.walletBalance,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? 'Alex Courier',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      vehicleType: json['vehicleType'] ?? 'MOTORCYCLE',
      vehiclePlate: json['vehiclePlate'] ?? '1234-XYZ',
      isOnline: json['isOnline'] ?? false,
      isActive: json['isActive'] ?? true,
      rating: (json['rating'] != null) ? double.parse(json['rating'].toString()) : 4.9,
      walletBalance: (json['walletBalance'] != null) ? double.parse(json['walletBalance'].toString()) : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate,
        'isOnline': isOnline,
        'isActive': isActive,
        'rating': rating,
        'walletBalance': walletBalance,
      };
}
