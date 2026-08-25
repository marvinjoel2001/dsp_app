import '../../domain/entities/driver_entity.dart';
import '../../data/models/wallet_model.dart';

abstract class DriverRepository {
  Future<DriverEntity> login(String email, String password);
  Future<DriverEntity> registerDriver(Map<String, dynamic> data);
  Future<DriverEntity> getDriverProfile(String driverId);
  Future<DriverEntity> updateProfile(String driverId, Map<String, dynamic> data);
  Future<DriverEntity> uploadDocuments(String driverId, Map<String, dynamic> docs);
  Future<bool> toggleOnlineStatus(String driverId, bool isOnline);
  Future<WalletInfoModel> getWallet(String driverId);
}
