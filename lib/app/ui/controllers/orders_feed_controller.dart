import 'package:flutter/material.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';

enum FeedTab { pickupRequest, deliveryRequest }

class OrdersFeedController extends ChangeNotifier {
  final OrderRepository orderRepository;

  FeedTab _selectedTab = FeedTab.pickupRequest;
  List<OrderEntity> _orders = [];
  bool _isLoading = false;

  FeedTab get selectedTab => _selectedTab;
  List<OrderEntity> get orders => _orders;
  bool get isLoading => _isLoading;

  OrdersFeedController({required this.orderRepository});

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
}
