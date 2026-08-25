import 'package:flutter/material.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';

enum RideStage {
  assigned,          // Etapa 1: En ruta a recogida -> Botón: "LLEGADA AL LOCAL DE RECOGIDA"
  arrivedAtPickup,   // Etapa 2: En el comercio -> Botón: "CONFIRMAR RECOGIDA (EN CAMINO)"
  inTransit,         // Etapa 3: En camino al cliente final -> Botón: "ENTREGADO (Prueba POD)"
  delivered,         // Etapa 4: Completado y acreditado en billetera
}

class ActiveRideController extends ChangeNotifier {
  final OrderRepository orderRepository;

  OrderEntity? _activeOrder;
  RideStage _currentStage = RideStage.assigned;
  bool _is3DView = false;
  String _turnGuidance = "En 500m, gira a la izquierda hacia Av. San Martín";

  OrderEntity? get activeOrder => _activeOrder;
  RideStage get currentStage => _currentStage;
  bool get is3DView => _is3DView;
  String get turnGuidance => _turnGuidance;

  ActiveRideController({required this.orderRepository}) {
    // Inicialización con orden activa de demostración (#434567)
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
      packageNotes: 'Llamar al llegar a la entrada principal',
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
    _turnGuidance = "Dirígete hacia el punto de recogida en ${order.pickupAddress.split(' ')[0]}";
    notifyListeners();
  }

  Future<void> advanceNextStage() async {
    if (_activeOrder == null) return;

    switch (_currentStage) {
      case RideStage.assigned:
        _currentStage = RideStage.arrivedAtPickup;
        _turnGuidance = "Has llegado al punto de recogida. Solicita el paquete.";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'ARRIVED_AT_PICKUP');
        break;
      case RideStage.arrivedAtPickup:
        _currentStage = RideStage.inTransit;
        _turnGuidance = "En camino: Dirígete hacia ${_activeOrder!.dropoffAddress}";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'IN_TRANSIT');
        break;
      case RideStage.inTransit:
        _currentStage = RideStage.delivered;
        _turnGuidance = "¡Entrega completada! Comprobante POD registrado.";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'DELIVERED');
        break;
      case RideStage.delivered:
        _activeOrder = null;
        break;
    }
    notifyListeners();
  }
}
