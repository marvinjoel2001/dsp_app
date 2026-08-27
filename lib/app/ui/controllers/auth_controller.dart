import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/entities/driver_entity.dart';
import '../../core/services/location_buffer_service.dart';
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
    // Default logged-in driver: Alex Repartidor (Chiringuito Driver)
    _currentDriver = DriverEntity(
      id: 'c8716b1e-6240-4b2a-8c01-7faef83151cf',
      fullName: 'Alex Repartidor',
      phone: '+59170000000',
      email: 'alex.courier@fooddrive.com',
      vehicleType: 'MOTORCYCLE',
      vehiclePlate: '1234-XYZ',
      verificationStatus: 'verified', // Cambiable a 'pending' o 'rejected' para pruebas
      isOnline: true,
      isActive: true,
      rating: 4.9,
      walletBalance: 142.50,
    );
    // Initialize WebSockets and start location background telemetry
    SocketService().initSocket();
    LocationBufferService.startTelemetrySync(_currentDriver!.id);
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentDriver = await driverRepository.registerDriver({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate,
      });

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
      LocationBufferService.startTelemetrySync(_currentDriver!.id);
    } else {
      LocationBufferService.stopTelemetrySync();
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
