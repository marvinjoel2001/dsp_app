class DriverEntity {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehiclePlate;
  final bool isOnline;
  final bool isActive;
  final double rating;
  final double walletBalance;

  DriverEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.isOnline,
    required this.isActive,
    required this.rating,
    required this.walletBalance,
  });
}
