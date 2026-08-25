import 'package:flutter/material.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';

enum RideStage {
  assigned,          // Stage 1: Heading to pickup -> Button: "ARRIVED AT PICKUP"
  arrivedAtPickup,   // Stage 2: At merchant -> Button: "CONFIRM PICKUP (IN TRANSIT)"
  inTransit,         // Stage 3: On the way to customer -> Button: "DELIVERED"
  delivered,         // Stage 4: Completed
}

class ActiveRideController extends ChangeNotifier {
  final OrderRepository orderRepository;

  OrderEntity? _activeOrder;
  RideStage _currentStage = RideStage.assigned;
  bool _is3DView = false;
  String _turnGuidance = "After 500m, turn left into Av. San Martín";

  OrderEntity? get activeOrder => _activeOrder;
  RideStage get currentStage => _currentStage;
  bool get is3DView => _is3DView;
  String get turnGuidance => _turnGuidance;

  ActiveRideController({required this.orderRepository}) {
    // Initialize with active order matching user's design reference (#434567)
    _activeOrder = OrderEntity(
      id: '434567',
      status: OrderDeliveryStatus.assigned,
      pickupAddress: '062 Kuhn Plains Suite 793',
      pickupLat: -17.7833,
      pickupLng: -63.1821,
      dropoffAddress: '922 Wilfredo Tunnel',
      dropoffLat: -17.7950,
      dropoffLng: -63.1700,
      price: 54.0,
      driverPayout: 43.20,
      packageNotes: 'Call when you will be near entrance',
      trackingToken: 'track-434567',
      estimatedTime: '12:35',
      estimatedDistanceKm: 1.5,
      createdAt: DateTime.now(),
    );
  }

  void toggle3D() {
    _is3DView = !_is3DView;
    notifyListeners();
  }

  void setActiveOrder(OrderEntity order) {
    _activeOrder = order;
    _currentStage = RideStage.assigned;
    _turnGuidance = "Head North towards ${order.pickupAddress.split(' ')[0]}";
    notifyListeners();
  }

  Future<void> advanceNextStage() async {
    if (_activeOrder == null) return;

    switch (_currentStage) {
      case RideStage.assigned:
        _currentStage = RideStage.arrivedAtPickup;
        _turnGuidance = "You have arrived at Pickup Location";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'ARRIVED_AT_PICKUP');
        break;
      case RideStage.arrivedAtPickup:
        _currentStage = RideStage.inTransit;
        _turnGuidance = "In Transit: Head towards ${_activeOrder!.dropoffAddress}";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'IN_TRANSIT');
        break;
      case RideStage.inTransit:
        _currentStage = RideStage.delivered;
        _turnGuidance = "Delivered successfully! Proof confirmed.";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'DELIVERED');
        break;
      case RideStage.delivered:
        _activeOrder = null;
        break;
    }
    notifyListeners();
  }
}
