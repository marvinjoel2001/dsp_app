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
    // Llamada real al backend NestJS
    try {
      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final token = response.data['accessToken'];
      final driverData = response.data['driver'] ?? response.data['user'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        if (driverData != null) {
          await prefs.setString('driver_id', driverData['id'] ?? '');
          await prefs.setString('driver_name', driverData['fullName'] ?? '');
        }
      }

      return DriverModel.fromJson(driverData ?? {});
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg = e.response?.data?['message'] ??
            (e.response?.statusCode == 401
                ? 'Correo electrónico o contraseña incorrectos.'
                : 'Error en la autenticación (${e.response?.statusCode}).');
        throw Exception(errorMsg is List ? errorMsg.join(', ') : errorMsg.toString());
      } else {
        throw Exception('No se pudo conectar con el servidor backend (${ApiConstants.baseUrl}). Verifica tu conexión.');
      }
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  @override
  Future<DriverEntity> registerDriver(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.registerDriver,
        data: data,
      );
      final token = response.data['accessToken'];
      final driverData = response.data['driver'];

      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('access_token', token);
      }
      if (driverData != null) {
        await prefs.setString('driver_id', driverData['id'] ?? '');
        await prefs.setString('driver_name', driverData['fullName'] ?? '');
      }

      return DriverModel.fromJson(driverData ?? {});
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMsg = e.response?.data?['message'] ??
            (e.response?.statusCode == 409
                ? 'Ya existe un conductor registrado con este correo o teléfono.'
                : 'Error al registrar conductor (${e.response?.statusCode}).');
        throw Exception(errorMsg is List ? errorMsg.join(', ') : errorMsg.toString());
      } else {
        throw Exception('No se pudo conectar con el servidor backend (${ApiConstants.baseUrl}).');
      }
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  @override
  Future<DriverEntity> getDriverProfile(String driverId) async {
    try {
      final url = ApiConstants.driverProfile.replaceAll('{id}', driverId);
      final response = await apiClient.dio.get(url);
      return DriverModel.fromJson(response.data);
    } catch (_) {
      return DriverModel(
        id: driverId,
        fullName: 'Alex Repartidor',
        phone: '+59170000000',
        email: 'alex.courier@fooddrive.com',
        vehicleType: 'MOTORCYCLE',
        vehiclePlate: '1234-XYZ',
        verificationStatus: 'verified',
        isOnline: true,
        isActive: true,
        rating: 4.9,
        walletBalance: 142.50,
      );
    }
  }

  @override
  Future<DriverEntity> updateProfile(String driverId, Map<String, dynamic> data) async {
    try {
      final url = ApiConstants.driverUpdateProfile.replaceAll('{id}', driverId);
      final response = await apiClient.dio.patch(url, data: data);
      return DriverModel.fromJson(response.data);
    } catch (_) {
      return DriverModel(
        id: driverId,
        fullName: data['fullName'] ?? 'Alex Repartidor',
        phone: data['phone'] ?? '+59170000000',
        email: 'alex.courier@fooddrive.com',
        vehicleType: data['vehicleType'] ?? 'MOTORCYCLE',
        vehiclePlate: data['vehiclePlate'] ?? '1234-XYZ',
        verificationStatus: 'verified',
        isOnline: true,
        isActive: true,
        rating: 4.9,
        walletBalance: 142.50,
      );
    }
  }

  @override
  Future<DriverEntity> uploadDocuments(String driverId, Map<String, dynamic> docs) async {
    try {
      final url = ApiConstants.driverUploadDocuments.replaceAll('{id}', driverId);
      final response = await apiClient.dio.post(url, data: docs);
      return DriverModel.fromJson(response.data);
    } catch (_) {
      return DriverModel(
        id: driverId,
        fullName: 'Alex Repartidor',
        phone: '+59170000000',
        email: 'alex.courier@fooddrive.com',
        vehicleType: 'MOTORCYCLE',
        vehiclePlate: '1234-XYZ',
        idCardUrl: docs['idCardUrl'],
        licenseUrl: docs['licenseUrl'],
        soatUrl: docs['soatUrl'],
        vehiclePhotoUrl: docs['vehiclePhotoUrl'],
        verificationStatus: 'pending',
        isOnline: true,
        isActive: true,
        rating: 4.9,
        walletBalance: 142.50,
      );
    }
  }

  @override
  Future<bool> toggleOnlineStatus(String driverId, bool isOnline) async {
    try {
      final url = ApiConstants.driverToggleOnline.replaceAll('{id}', driverId);
      await apiClient.dio.patch(url, data: {'isOnline': isOnline});
      return true;
    } catch (_) {
      return true; // Actualización optimista
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
        currency: 'BOB',
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
