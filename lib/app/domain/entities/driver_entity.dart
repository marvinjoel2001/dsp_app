class DriverEntity {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehiclePlate;
  final String? avatarUrl;
  final String verificationStatus; // 'pending' | 'verified' | 'rejected'
  final String? idCardUrl;
  final String? licenseUrl;
  final String? soatUrl;
  final String? vehiclePhotoUrl;
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
    this.avatarUrl,
    this.verificationStatus = 'verified',
    this.idCardUrl,
    this.licenseUrl,
    this.soatUrl,
    this.vehiclePhotoUrl,
    required this.isOnline,
    required this.isActive,
    required this.rating,
    required this.walletBalance,
  });

  bool get isVerified => verificationStatus == 'verified';
  bool get isPendingVerification => verificationStatus == 'pending';
  bool get isRejectedVerification => verificationStatus == 'rejected';
}
