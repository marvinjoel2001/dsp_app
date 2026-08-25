import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../../core/services/mapbox_routing_service.dart';

enum RideStage {
  assigned, // Etapa 1: En ruta al comercio
  arrivedAtPickup, // Etapa 2: Esperando / Retirando paquete en comercio
  inTransit, // Etapa 3: En camino al cliente final
  delivered, // Etapa 4: Completado y acreditado
}

class ActiveRideController extends ChangeNotifier {
  final OrderRepository orderRepository;
  final MapboxRoutingService _routingService = MapboxRoutingService();

  OrderEntity? _activeOrder;
  RideStage _currentStage = RideStage.assigned;
  bool _is3DView = true;
  String _turnGuidance = "Calculando ruta óptima por calles...";
  String _merchantPhone = "+591 700-11223";
  String _customerPhone = "+591 755-44332";

  // Telemetría y Navegación GPS en Tiempo Real
  LatLng _driverLocation = const LatLng(-17.7810, -63.1800);
  double _driverHeading = 180.0;
  double _driverSpeedKmh = 35.0;
  bool _isNavigating = true;
  bool _isLoadingRoute = false;

  // Ruta Vectorial Mapbox
  List<LatLng> _routePolyline = [];
  double _routeDistanceKm = 1.5;
  int _routeDurationMin = 12;
  List<RouteStep> _routeSteps = [];
  int _currentStepIndex = 0;

  Timer? _simulationTimer;
  int _simulationPolylineIndex = 0;

  OrderEntity? get activeOrder => _activeOrder;
  RideStage get currentStage => _currentStage;
  bool get is3DView => _is3DView;
  String get turnGuidance => _turnGuidance;
  String get merchantPhone => _merchantPhone;
  String get customerPhone => _customerPhone;

  LatLng get driverLocation => _driverLocation;
  double get driverHeading => _driverHeading;
  double get driverSpeedKmh => _driverSpeedKmh;
  bool get isNavigating => _isNavigating;
  bool get isLoadingRoute => _isLoadingRoute;
  List<LatLng> get routePolyline => _routePolyline;
  double get routeDistanceKm => _routeDistanceKm;
  int get routeDurationMin => _routeDurationMin;
  List<RouteStep> get routeSteps => _routeSteps;
  int get currentStepIndex => _currentStepIndex;

  ActiveRideController({required this.orderRepository}) {
    // Orden de demostración inicial
    _activeOrder = OrderEntity(
      id: '434567',
      status: OrderDeliveryStatus.assigned,
      pickupAddress: 'Restaurante El Chiringuito Central',
      pickupLat: -17.7833,
      pickupLng: -63.1821,
      dropoffAddress: 'Av. Las Palmas #420, Condominio El Bosque',
      dropoffLat: -17.7950,
      dropoffLng: -63.1700,
      price: 54.0,
      driverPayout: 43.20,
      packageNotes: 'Tocar timbre 3B al llegar',
      trackingToken: 'track-434567',
      estimatedTime: '12 min',
      estimatedDistanceKm: 1.5,
      createdAt: DateTime.now(),
    );

    // Cargar ruta inicial
    calculateCurrentRoute();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void toggle3D() {
    _is3DView = !_is3DView;
    notifyListeners();
  }

  void toggleNavigationMode() {
    _isNavigating = !_isNavigating;
    notifyListeners();
  }

  void setActiveOrder(OrderEntity order) {
    _activeOrder = order;
    _currentStage = RideStage.assigned;
    _simulationPolylineIndex = 0;
    calculateCurrentRoute();
    notifyListeners();
  }

  /// Calcula la ruta real por calles utilizando Mapbox Directions API
  Future<void> calculateCurrentRoute() async {
    if (_activeOrder == null) return;

    _isLoadingRoute = true;
    notifyListeners();

    final pickup = LatLng(_activeOrder!.pickupLat, _activeOrder!.pickupLng);
    final dropoff = LatLng(_activeOrder!.dropoffLat, _activeOrder!.dropoffLng);

    LatLng origin;
    LatLng destination;

    if (_currentStage == RideStage.assigned || _currentStage == RideStage.arrivedAtPickup) {
      origin = _driverLocation;
      destination = pickup;
    } else {
      origin = pickup;
      destination = dropoff;
    }

    final result = await _routingService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (result != null && result.polyline.isNotEmpty) {
      _routePolyline = result.polyline;
      _routeDistanceKm = result.distanceKm;
      _routeDurationMin = result.durationMinutes;
      _routeSteps = result.steps;
      _currentStepIndex = 0;

      if (_routeSteps.isNotEmpty) {
        _turnGuidance = _routeSteps[0].instruction;
      } else {
        _turnGuidance = _currentStage == RideStage.assigned
            ? "Dirígete hacia ${_activeOrder!.pickupAddress.split(',')[0]}"
            : "Dirígete hacia ${_activeOrder!.dropoffAddress.split(',')[0]}";
      }
    }

    _isLoadingRoute = false;
    _startOrRestartSimulation();
    notifyListeners();
  }

  void _startOrRestartSimulation() {
    _simulationTimer?.cancel();
    if (_routePolyline.isEmpty) return;

    _simulationPolylineIndex = 0;
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_routePolyline.isEmpty) return;

      if (_simulationPolylineIndex < _routePolyline.length - 1) {
        _simulationPolylineIndex++;
        final currentPoint = _routePolyline[_simulationPolylineIndex];
        final prevPoint = _routePolyline[_simulationPolylineIndex - 1];

        _driverLocation = currentPoint;
        _driverHeading = _calculateBearing(prevPoint, currentPoint);
        _driverSpeedKmh = 28.0 + Random().nextInt(14); // 28 - 42 km/h

        // Actualizar paso de giro si nos acercamos a un waypoint
        if (_routeSteps.isNotEmpty && _currentStepIndex < _routeSteps.length - 1) {
          final nextStep = _routeSteps[_currentStepIndex + 1];
          final distToNext = const Distance().as(LengthUnit.Meter, currentPoint, nextStep.location);
          if (distToNext < 60) {
            _currentStepIndex++;
            _turnGuidance = _routeSteps[_currentStepIndex].instruction;
          }
        }

        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * pi / 180;
    final lon1 = from.longitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final lon2 = to.longitude * pi / 180;

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final radians = atan2(y, x);
    final degrees = radians * 180 / pi;
    return (degrees + 360) % 360;
  }

  Future<void> cancelActiveOrder(String reason) async {
    if (_activeOrder == null) return;
    _simulationTimer?.cancel();
    try {
      await orderRepository.updateOrderStatus(_activeOrder!.id, 'CANCELLED');
    } catch (_) {}
    _activeOrder = null;
    _currentStage = RideStage.assigned;
    notifyListeners();
  }

  Future<void> advanceNextStage({
    String? proofPhotoUrl,
    String? signatureSvg,
    String? notes,
  }) async {
    if (_activeOrder == null) return;

    switch (_currentStage) {
      case RideStage.assigned:
        _currentStage = RideStage.arrivedAtPickup;
        _turnGuidance = "Has llegado al Comercio. Solicita y verifica el pedido #${_activeOrder!.id}.";
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'ARRIVED_AT_PICKUP');
        break;
      case RideStage.arrivedAtPickup:
        _currentStage = RideStage.inTransit;
        _driverLocation = LatLng(_activeOrder!.pickupLat, _activeOrder!.pickupLng);
        await orderRepository.updateOrderStatus(_activeOrder!.id, 'IN_TRANSIT');
        calculateCurrentRoute();
        break;
      case RideStage.inTransit:
        _currentStage = RideStage.delivered;
        _turnGuidance = "¡Entrega completada! Comprobante POD registrado en Cloudinary.";
        _simulationTimer?.cancel();
        await orderRepository.updateOrderStatus(
          _activeOrder!.id,
          'DELIVERED',
          proofUrl: proofPhotoUrl,
          signatureSvg: signatureSvg,
        );
        break;
      case RideStage.delivered:
        _simulationTimer?.cancel();
        _activeOrder = null;
        break;
    }
    notifyListeners();
  }
}
