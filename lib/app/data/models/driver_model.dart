import '../../domain/entities/driver_entity.dart';

class DriverModel extends DriverEntity {
  DriverModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.email,
    required super.vehicleType,
    required super.vehiclePlate,
    super.ciNumber,
    super.homeAddress,
    super.avatarUrl,
    super.verificationStatus = 'verified',
    super.idCardUrl,
    super.licenseUrl,
    super.soatUrl,
    super.vehiclePhotoUrl,
    super.contractSignatureSvg,
    super.contractAcceptedAt,
    required super.isOnline,
    required super.isActive,
    required super.rating,
    required super.walletBalance,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? 'Alex Repartidor',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      vehicleType: json['vehicleType'] ?? 'MOTORCYCLE',
      vehiclePlate: json['vehiclePlate'] ?? '1234-XYZ',
      ciNumber: json['ciNumber'],
      homeAddress: json['homeAddress'],
      avatarUrl: json['avatarUrl'],
      verificationStatus: json['verificationStatus'] ?? 'verified',
      idCardUrl: json['idCardUrl'],
      licenseUrl: json['licenseUrl'],
      soatUrl: json['soatUrl'],
      vehiclePhotoUrl: json['vehiclePhotoUrl'],
      contractSignatureSvg: json['contractSignatureSvg'],
      contractAcceptedAt: json['contractAcceptedAt'] != null
          ? DateTime.tryParse(json['contractAcceptedAt'].toString())
          : null,
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
        'ciNumber': ciNumber,
        'homeAddress': homeAddress,
        'avatarUrl': avatarUrl,
        'verificationStatus': verificationStatus,
        'idCardUrl': idCardUrl,
        'licenseUrl': licenseUrl,
        'soatUrl': soatUrl,
        'vehiclePhotoUrl': vehiclePhotoUrl,
        'contractSignatureSvg': contractSignatureSvg,
        'contractAcceptedAt': contractAcceptedAt?.toIso8601String(),
        'isOnline': isOnline,
        'isActive': isActive,
        'rating': rating,
        'walletBalance': walletBalance,
      };
}
