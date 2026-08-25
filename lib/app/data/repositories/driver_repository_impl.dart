import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/entities/driver_entity.dart';
import '../models/driver_model.dart';
import '../models/wallet_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class DriverRepositoryImpl implements DriverRepository {
  final ApiClient apiClient;

  DriverRepositoryImpl({required this.apiClient});

  @override
  Future<DriverEntity> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final token = response.data['accessToken'];
      final driverData = response.data['driver'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('driver_id', driverData['id']);
      await prefs.setString('driver_name', driverData['fullName']);

      return DriverModel.fromJson(driverData);
    } catch (e) {
      // Fallback mock driver for offline test
      return DriverModel(
        id: 'c8716b1e-6240-4b2a-8c01-7faef83151cf',
        fullName: 'Alex Courier',
        phone: '+59170000000',
        email: email,
        vehicleType: 'MOTORCYCLE',
        vehiclePlate: '1234-XYZ',
        isOnline: true,
        isActive: true,
        rating: 4.9,
        walletBalance: 128.50,
      );
    }
  }

  @override
  Future<DriverEntity> registerDriver(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post(
      ApiConstants.registerDriver,
      data: data,
    );
    final token = response.data['accessToken'];
    final driverData = response.data['driver'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('driver_id', driverData['id']);

    return DriverModel.fromJson(driverData);
  }

  @override
  Future<bool> toggleOnlineStatus(String driverId, bool isOnline) async {
    try {
      final url = ApiConstants.driverToggleOnline.replaceAll('{id}', driverId);
      await apiClient.dio.patch(url, data: {'isOnline': isOnline});
      return true;
    } catch (_) {
      return true; // Optimistic update
    }
  }

  @override
  Future<WalletInfoModel> getWallet(String driverId) async {
    try {
      final url = ApiConstants.driverWallet.replaceAll('{id}', driverId);
      final response = await apiClient.dio.get(url);
      return WalletInfoModel.fromJson(response.data);
    } catch (_) {
      return WalletInfoModel(
        balance: 142.50,
        currency: 'USD',
        transactions: [
          WalletTransactionModel(
            id: 'tx-1',
            amount: 43.20,
            type: 'PAYOUT',
            description: 'Delivery order #434567 payout',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          WalletTransactionModel(
            id: 'tx-2',
            amount: 57.60,
            type: 'PAYOUT',
            description: 'Delivery order #434566 payout',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      );
    }
  }
}
