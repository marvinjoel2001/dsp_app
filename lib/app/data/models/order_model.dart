import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  OrderModel({
    required super.id,
    super.tenantId,
    super.driverId,
    super.merchantReference,
    required super.status,
    required super.pickupAddress,
    required super.pickupLat,
    required super.pickupLng,
    required super.dropoffAddress,
    required super.dropoffLat,
    required super.dropoffLng,
    required super.price,
    required super.driverPayout,
    super.packageNotes,
    required super.trackingToken,
    super.estimatedTime,
    super.estimatedDistanceKm,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderDeliveryStatus parseStatus(String? s) {
      switch (s) {
        case 'CREATED':
          return OrderDeliveryStatus.created;
        case 'SEARCHING_DRIVER':
          return OrderDeliveryStatus.searchingDriver;
        case 'ASSIGNED':
          return OrderDeliveryStatus.assigned;
        case 'ARRIVED_AT_PICKUP':
          return OrderDeliveryStatus.arrivedAtPickup;
        case 'IN_TRANSIT':
          return OrderDeliveryStatus.inTransit;
        case 'DELIVERED':
          return OrderDeliveryStatus.delivered;
        case 'CANCELLED':
          return OrderDeliveryStatus.cancelled;
        default:
          return OrderDeliveryStatus.created;
      }
    }

    return OrderModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'],
      driverId: json['driverId'],
      merchantReference: json['merchantReference'] ?? 'REF-1001',
      status: parseStatus(json['status']),
      pickupAddress: json['pickupAddress'] ?? '062 Kuhn Plains Suite 793',
      pickupLat: (json['pickupLat'] != null) ? double.parse(json['pickupLat'].toString()) : -17.7833,
      pickupLng: (json['pickupLng'] != null) ? double.parse(json['pickupLng'].toString()) : -63.1821,
      dropoffAddress: json['dropoffAddress'] ?? '922 Wilfredo Tunnel',
      dropoffLat: (json['dropoffLat'] != null) ? double.parse(json['dropoffLat'].toString()) : -17.7950,
      dropoffLng: (json['dropoffLng'] != null) ? double.parse(json['dropoffLng'].toString()) : -63.1700,
      price: (json['price'] != null) ? double.parse(json['price'].toString()) : 54.0,
      driverPayout: (json['driverPayout'] != null) ? double.parse(json['driverPayout'].toString()) : 43.2,
      packageNotes: json['packageNotes'] ?? 'Call when you will be near entrance',
      trackingToken: json['trackingToken'] ?? '',
      estimatedTime: '12:35',
      estimatedDistanceKm: 1.5,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
