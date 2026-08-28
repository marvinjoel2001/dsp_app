import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/order_entity.dart';
import '../models/order_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient apiClient;

  OrderRepositoryImpl({required this.apiClient});

  @override
  Future<List<OrderEntity>> getAvailableFeed(String driverId) async {
    try {
      final url = ApiConstants.driverFeed.replaceAll('{id}', driverId);
      final response = await apiClient.dio.get(url);
      if (response.data is List) {
        return (response.data as List<dynamic>)
            .map((item) => OrderModel.fromJson(item))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<OrderEntity?> getActiveOrder(String driverId) async {
    try {
      final url = ApiConstants.driverActiveOrder.replaceAll('{id}', driverId);
      final response = await apiClient.dio.get(url);
      if (response.data != null) {
        return OrderModel.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> acceptOrder(String orderId, String driverId) async {
    try {
      await apiClient.dio.post(
        ApiConstants.acceptOrder,
        data: {'orderId': orderId, 'driverId': driverId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? proofUrl,
    String? signatureSvg,
  }) async {
    try {
      final url = ApiConstants.updateOrderStatus.replaceAll('{id}', orderId);
      await apiClient.dio.patch(
        url,
        data: {
          'status': status,
          'proofPhotoUrl': proofUrl,
          'signatureSvg': signatureSvg,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
