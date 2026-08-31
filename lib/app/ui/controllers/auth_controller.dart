import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/entities/driver_entity.dart';
import '../../data/models/wallet_model.dart';
import '../../core/network/api_client.dart';
import '../../core/services/location_buffer_service.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/network/socket_service.dart';

class AuthController extends ChangeNotifier {
  final DriverRepository driverRepository;

  DriverEntity? _currentDriver;
  bool _isLoading = false;
  String? _errorMessage;

  DriverEntity? get currentDriver => _currentDriver;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentDriver != null;
  bool get isVerified => _currentDriver?.isVerified ?? false;
  bool get isPendingVerification => _currentDriver?.isPendingVerification ?? false;
  bool get isRejectedVerification => _currentDriver?.isRejectedVerification ?? false;
  String? get errorMessage => _errorMessage;

  AuthController({required this.driverRepository}) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverId = prefs.getString('driver_id');
      final token = prefs.getString('access_token');
      if (driverId != null && token != null && token.isNotEmpty) {
        _currentDriver = await driverRepository.getDriverProfile(driverId);
        SocketService().initSocket();
        SocketService().joinDriver(_currentDriver!.id);
        LocationBufferService.startTelemetrySync(_currentDriver!.id);
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_currentDriver == null) return;
    try {
      _currentDriver = await driverRepository.getDriverProfile(_currentDriver!.id);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDriver = await driverRepository.login(email, password);
      SocketService().initSocket();
      SocketService().joinDriver(_currentDriver!.id);
      LocationBufferService.startTelemetrySync(_currentDriver!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDriver({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehiclePlate,
    String? ciNumber,
    String? homeAddress,
    String? avatarUrl,
    String? idCardUrl,
    String? licenseUrl,
    String? soatUrl,
    String? vehiclePhotoUrl,
    String? contractSignatureSvg,
    DateTime? contractAcceptedAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Registro base en Auth (campos requeridos y validados por /v1/auth/register-driver)
      _currentDriver = await driverRepository.registerDriver({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate.isEmpty ? 'N/A' : vehiclePlate,
      });

      // 2. Asociar documentos fotográficos en /v1/drivers/:id/documents si fueron subidos
      final hasDocs = idCardUrl != null || licenseUrl != null || soatUrl != null || vehiclePhotoUrl != null;
      if (hasDocs && _currentDriver != null) {
        try {
          _currentDriver = await driverRepository.uploadDocuments(_currentDriver!.id, {
            if (idCardUrl != null) 'idCardUrl': idCardUrl,
            if (licenseUrl != null) 'licenseUrl': licenseUrl,
            if (soatUrl != null) 'soatUrl': soatUrl,
            if (vehiclePhotoUrl != null) 'vehiclePhotoUrl': vehiclePhotoUrl,
          });
        } catch (docErr) {
          debugPrint('Aviso: no se pudo sincronizar documentos secundarios: $docErr');
        }
      }

      // 3. Asociar avatar fotográfico en /v1/drivers/:id/profile si existe
      if (avatarUrl != null && _currentDriver != null) {
        try {
          _currentDriver = await driverRepository.updateProfile(_currentDriver!.id, {
            'avatarUrl': avatarUrl,
          });
        } catch (avatarErr) {
          debugPrint('Aviso: no se pudo sincronizar avatar secundario: $avatarErr');
        }
      }

      SocketService().initSocket();
      LocationBufferService.startTelemetrySync(_currentDriver!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String vehicleType,
    required String vehiclePlate,
  }) async {
    if (_currentDriver == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDriver = await driverRepository.updateProfile(_currentDriver!.id, {
        'fullName': fullName,
        'phone': phone,
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadVerificationDocuments({
    String? idCardUrl,
    String? licenseUrl,
    String? soatUrl,
    String? vehiclePhotoUrl,
  }) async {
    if (_currentDriver == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDriver = await driverRepository.uploadDocuments(_currentDriver!.id, {
        if (idCardUrl != null) 'idCardUrl': idCardUrl,
        if (licenseUrl != null) 'licenseUrl': licenseUrl,
        if (soatUrl != null) 'soatUrl': soatUrl,
        if (vehiclePhotoUrl != null) 'vehiclePhotoUrl': vehiclePhotoUrl,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleOnline(bool isOnline) async {
    if (_currentDriver == null) return;
    _currentDriver = DriverEntity(
      id: _currentDriver!.id,
      fullName: _currentDriver!.fullName,
      phone: _currentDriver!.phone,
      email: _currentDriver!.email,
      vehicleType: _currentDriver!.vehicleType,
      vehiclePlate: _currentDriver!.vehiclePlate,
      avatarUrl: _currentDriver!.avatarUrl,
      verificationStatus: _currentDriver!.verificationStatus,
      idCardUrl: _currentDriver!.idCardUrl,
      licenseUrl: _currentDriver!.licenseUrl,
      soatUrl: _currentDriver!.soatUrl,
      vehiclePhotoUrl: _currentDriver!.vehiclePhotoUrl,
      isOnline: isOnline,
      isActive: _currentDriver!.isActive,
      rating: _currentDriver!.rating,
      walletBalance: _currentDriver!.walletBalance,
    );
    notifyListeners();

    await driverRepository.toggleOnlineStatus(_currentDriver!.id, isOnline);
    if (isOnline) {
      SocketService().initSocket();
      SocketService().joinDriver(_currentDriver!.id);
      PushNotificationService().registerDriver(_currentDriver!.id, driverRepo: driverRepository);
      LocationBufferService.startTelemetrySync(_currentDriver!.id);
    } else {
      LocationBufferService.stopTelemetrySync();
    }
  }

  Future<WalletInfoModel> getWallet() async {
    if (_currentDriver == null) {
      return WalletInfoModel(balance: 0.0, currency: 'BOB', transactions: []);
    }
    final wallet = await driverRepository.getWallet(_currentDriver!.id);
    _currentDriver = DriverEntity(
      id: _currentDriver!.id,
      fullName: _currentDriver!.fullName,
      phone: _currentDriver!.phone,
      email: _currentDriver!.email,
      vehicleType: _currentDriver!.vehicleType,
      vehiclePlate: _currentDriver!.vehiclePlate,
      ciNumber: _currentDriver!.ciNumber,
      homeAddress: _currentDriver!.homeAddress,
      avatarUrl: _currentDriver!.avatarUrl,
      verificationStatus: _currentDriver!.verificationStatus,
      idCardUrl: _currentDriver!.idCardUrl,
      licenseUrl: _currentDriver!.licenseUrl,
      soatUrl: _currentDriver!.soatUrl,
      vehiclePhotoUrl: _currentDriver!.vehiclePhotoUrl,
      contractSignatureSvg: _currentDriver!.contractSignatureSvg,
      contractAcceptedAt: _currentDriver!.contractAcceptedAt,
      isOnline: _currentDriver!.isOnline,
      isActive: _currentDriver!.isActive,
      rating: _currentDriver!.rating,
      walletBalance: wallet.balance,
    );
    notifyListeners();
    return wallet;
  }

  Future<bool> requestWithdrawal({
    required double amount,
    required String method,
    required String accountHolder,
    required String accountNumberOrPhone,
  }) async {
    if (_currentDriver == null) return false;
    try {
      await ApiClient().dio.post(
        '/v1/settlements/withdrawals/request',
        data: {
          'driverId': _currentDriver!.id,
          'amount': amount,
          'method': method,
          'accountHolder': accountHolder,
          'accountNumberOrPhone': accountNumberOrPhone,
        },
      );
      await getWallet();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _currentDriver = null;
    LocationBufferService.stopTelemetrySync();
    SocketService().disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('driver_id');
    await prefs.remove('driver_name');
    notifyListeners();
  }
}
