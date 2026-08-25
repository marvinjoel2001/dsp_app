import 'package:flutter/material.dart';
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
  String? get errorMessage => _errorMessage;

  AuthController({required this.driverRepository}) {
    // Default logged-in mock driver matching user reference UI: Alex Courier (4.9 ★)
    _currentDriver = DriverEntity(
      id: 'c8716b1e-6240-4b2a-8c01-7faef83151cf',
      fullName: 'Alex Courier',
      phone: '+59170000000',
      email: 'alex.courier@fooddrive.com',
      vehicleType: 'MOTORCYCLE',
      vehiclePlate: '1234-XYZ',
      isOnline: true,
      isActive: true,
      rating: 4.9,
      walletBalance: 128.50,
    );
    // Initialize WebSockets and start location background telemetry
    SocketService().initSocket();
    LocationBufferService.startTelemetrySync(_currentDriver!.id);
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
      _errorMessage = e.toString();
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
}
