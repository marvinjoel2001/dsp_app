import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/socket_service.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';

enum FeedTab { pickupRequest, deliveryRequest }

class OrdersFeedController extends ChangeNotifier {
  final OrderRepository orderRepository;

  FeedTab _selectedTab = FeedTab.pickupRequest;
  List<OrderEntity> _orders = [];
  bool _isLoading = false;
  StreamSubscription? _socketSubscription;

  // Stream que notifica a la pantalla principal cuando llega una orden en tiempo real
  final StreamController<OrderEntity> _incomingOfferStream = StreamController<OrderEntity>.broadcast();
  Stream<OrderEntity> get onIncomingOffer => _incomingOfferStream.stream;

  FeedTab get selectedTab => _selectedTab;
  List<OrderEntity> get orders => _orders;
  bool get isLoading => _isLoading;

  OrdersFeedController({required this.orderRepository}) {
    _listenToIncomingOrders();
  }

  void _listenToIncomingOrders() {
    _socketSubscription = SocketService().onOrderEvent.listen((data) {
      if (data == null) return;
      try {
        OrderEntity order;
        if (data is OrderEntity) {
          order = data;
        } else if (data is Map<String, dynamic>) {
          order = OrderModel.fromJson(data);
        } else if (data is Map) {
          order = OrderModel.fromJson(Map<String, dynamic>.from(data));
        } else {
          return;
        }

        // Agregar a la lista de órdenes si no existe
        if (!_orders.any((o) => o.id == order.id)) {
          _orders.insert(0, order);
          notifyListeners();
        }

        // Emitir oferta para que abra el modal emergente con sonido y vibración
        _incomingOfferStream.add(order);
      } catch (e) {
        debugPrint('Error al procesar orden de socket: $e');
      }
    });
  }

  void setTab(FeedTab tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  Future<void> fetchOrders(String driverId) async {
    _isLoading = true;
    notifyListeners();

    _orders = await orderRepository.getAvailableFeed(driverId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> acceptOrder(String orderId, String driverId) async {
    final success = await orderRepository.acceptOrder(orderId, driverId);
    if (success) {
      _orders.removeWhere((o) => o.id == orderId);
      notifyListeners();
    }
    return success;
  }

  /// Método para disparar una orden de prueba y verificar sonido, vibración y modal
  void simulateOrderOfferForTesting() {
    final mockOrder = OrderModel(
      id: 'ord_demo_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      merchantReference: 'REST-POLLO-09',
      status: OrderDeliveryStatus.searchingDriver,
      pickupAddress: 'Pollos Copacabana - Av. Monseñor Rivero #320',
      pickupLat: -17.7833,
      pickupLng: -63.1821,
      dropoffAddress: 'Condominio Sevilla Real, Torre A Dpto 402',
      dropoffLat: -17.7920,
      dropoffLng: -63.1720,
      price: 55.0,
      driverPayout: 45.0,
      packageNotes: 'Pedido frágil con 2 combos familiares y gaseosas. Cobro exacto en destino.',
      trackingToken: 'TRK-DEMO-TEST',
      estimatedDistanceKm: 3.8,
      estimatedTime: '18 min',
      createdAt: DateTime.now(),
    );

    if (!_orders.any((o) => o.id == mockOrder.id)) {
      _orders.insert(0, mockOrder);
      notifyListeners();
    }
    _incomingOfferStream.add(mockOrder);
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _incomingOfferStream.close();
    super.dispose();
  }
}
