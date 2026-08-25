import '../../domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getAvailableFeed(String driverId);
  Future<OrderEntity?> getActiveOrder(String driverId);
  Future<bool> acceptOrder(String orderId, String driverId);
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? proofUrl,
    String? signatureSvg,
  });
}
