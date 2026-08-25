import '../../domain/entities/driver_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../data/models/wallet_model.dart';

abstract class DriverRepository {
  Future<DriverEntity> login(String email, String password);
  Future<DriverEntity> registerDriver(Map<String, dynamic> data);
  Future<bool> toggleOnlineStatus(String driverId, bool isOnline);
  Future<WalletInfoModel> getWallet(String driverId);
}

abstract class OrderRepository {
  Future<List<OrderEntity>> getAvailableFeed(String driverId);
  Future<OrderEntity?> getActiveOrder(String driverId);
  Future<bool> acceptOrder(String orderId, String driverId);
  Future<bool> updateOrderStatus(String orderId, String status, {String? proofUrl, String? signatureSvg});
}
