enum OrderDeliveryStatus {
  created,
  searchingDriver,
  assigned,
  arrivedAtPickup,
  inTransit,
  delivered,
  cancelled,
}

class OrderEntity {
  final String id;
  final String? tenantId;
  final String? driverId;
  final String? merchantReference;
  final OrderDeliveryStatus status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final double price;
  final double driverPayout;
  final String? packageNotes;
  final String trackingToken;
  final String? estimatedTime;
  final double? estimatedDistanceKm;
  final DateTime createdAt;

  OrderEntity({
    required this.id,
    this.tenantId,
    this.driverId,
    this.merchantReference,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.price,
    required this.driverPayout,
    this.packageNotes,
    required this.trackingToken,
    this.estimatedTime,
    this.estimatedDistanceKm,
    required this.createdAt,
  });
}
