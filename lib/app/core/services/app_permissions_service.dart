import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissionsService {
  static final AppPermissionsService _instance = AppPermissionsService._internal();
  factory AppPermissionsService() => _instance;
  AppPermissionsService._internal();

  /// Verifica si los permisos esenciales de conductor están concedidos
  Future<bool> hasAllRequiredPermissions() async {
    if (kIsWeb) return true;

    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;

    // La ubicación es mandataria; la notificación es crucial para órdenes
    final isLocationOk = locationStatus.isGranted || locationStatus.isLimited;
    final isNotificationOk = notificationStatus.isGranted || notificationStatus.isProvisional;

    return isLocationOk && isNotificationOk;
  }

  /// Solicita permisos de ubicación GPS
  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Solicitar activación de GPS en el dispositivo
        await Geolocator.openLocationSettings();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Permiso de rastreo en segundo plano si está disponible
      try {
        final bgStatus = await Permission.locationAlways.status;
        if (!bgStatus.isGranted) {
          await Permission.locationAlways.request();
        }
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error al solicitar permiso de ubicación: $e');
      return false;
    }
  }

  /// Solicita permisos de cámara para comprobante de entrega (POD)
  Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Solicita permisos de notificaciones push para despacho de órdenes
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.request();

    // Solicitar permiso de ignorar optimización de batería para no matar el servicio de despacho
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {}

    return status.isGranted;
  }

  /// Solicita todos los permisos requeridos en secuencia
  Future<Map<String, bool>> requestAllPermissions() async {
    final locationGranted = await requestLocationPermission();
    final cameraGranted = await requestCameraPermission();
    final notificationGranted = await requestNotificationPermission();

    return {
      'location': locationGranted,
      'camera': cameraGranted,
      'notification': notificationGranted,
    };
  }

  /// Obtiene la posición GPS real actual del conductor
  Future<LatLng?> getCurrentDriverPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('No se pudo obtener posición GPS: $e');
      return null;
    }
  }

  /// Abre los ajustes del sistema de la app si el usuario denegó permisos permanentemente
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
