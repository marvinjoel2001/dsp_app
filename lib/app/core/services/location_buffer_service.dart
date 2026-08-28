import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../network/socket_service.dart';

class LocationPing {
  final String driverId;
  final double lat;
  final double lng;
  final double heading;
  final double speed;
  final String? orderId;
  final DateTime timestamp;

  LocationPing({
    required this.driverId,
    required this.lat,
    required this.lng,
    this.heading = 0,
    this.speed = 0,
    this.orderId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speed': speed,
        'orderId': orderId,
        'timestamp': timestamp.toIso8601String(),
      };
}

class LocationBufferService {
  static final List<LocationPing> _buffer = [];
  static StreamSubscription<Position>? _positionSubscription;
  static Timer? _fallbackTimer;

  // Notificadores reactivos para que el mapa de inicio y navegación sigan la posición GPS real
  static final ValueNotifier<LatLng?> currentPositionNotifier = ValueNotifier<LatLng?>(null);
  static final ValueNotifier<double> currentHeadingNotifier = ValueNotifier<double>(0.0);
  static final ValueNotifier<double> currentSpeedNotifier = ValueNotifier<double>(0.0);

  /// Inicia el rastreo satelital GPS y transmisión de telemetría por WebSockets
  static Future<void> startTelemetrySync(String driverId, {String? activeOrderId}) async {
    stopTelemetrySync();

    // 1. Obtener la primera posición GPS inmediatamente
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      final initialLatLng = LatLng(initialPos.latitude, initialPos.longitude);
      currentPositionNotifier.value = initialLatLng;
      currentHeadingNotifier.value = initialPos.heading;
      currentSpeedNotifier.value = initialPos.speed;

      sendOrBufferPing(LocationPing(
        driverId: driverId,
        lat: initialPos.latitude,
        lng: initialPos.longitude,
        heading: initialPos.heading,
        speed: initialPos.speed,
        orderId: activeOrderId,
        timestamp: DateTime.now(),
      ));
    } catch (_) {
      // Fallback a Santa Cruz centro si no hay fix satelital inicial
      currentPositionNotifier.value ??= const LatLng(-17.7833, -63.1821);
    }

    // 2. Escuchar stream de coordenadas continuas del dispositivo
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Actualiza cada 3 metros recorridos
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (pos) {
          final latLng = LatLng(pos.latitude, pos.longitude);
          currentPositionNotifier.value = latLng;
          currentHeadingNotifier.value = pos.heading;
          currentSpeedNotifier.value = pos.speed;

          final ping = LocationPing(
            driverId: driverId,
            lat: pos.latitude,
            lng: pos.longitude,
            heading: pos.heading,
            speed: pos.speed,
            orderId: activeOrderId,
            timestamp: DateTime.now(),
          );
          sendOrBufferPing(ping);
        },
        onError: (err) {
          debugPrint('Error en stream GPS: $err');
          _startFallbackInterval(driverId, activeOrderId);
        },
      );
    } catch (e) {
      debugPrint('No se pudo inicializar getPositionStream: $e');
      _startFallbackInterval(driverId, activeOrderId);
    }
  }

  static void _startFallbackInterval(String driverId, String? activeOrderId) {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final currentPos = currentPositionNotifier.value ?? const LatLng(-17.7833, -63.1821);
      final ping = LocationPing(
        driverId: driverId,
        lat: currentPos.latitude,
        lng: currentPos.longitude,
        heading: currentHeadingNotifier.value,
        speed: currentSpeedNotifier.value,
        orderId: activeOrderId,
        timestamp: DateTime.now(),
      );
      sendOrBufferPing(ping);
    });
  }

  static void sendOrBufferPing(LocationPing ping) {
    final socket = SocketService();
    if (socket.isConnected) {
      flushBuffer();
      socket.emitLocationPing(
        driverId: ping.driverId,
        lat: ping.lat,
        lng: ping.lng,
        heading: ping.heading,
        speed: ping.speed,
        orderId: ping.orderId,
      );
    } else {
      if (_buffer.length < 100) {
        _buffer.add(ping);
      }
    }
  }

  static void flushBuffer() {
    final socket = SocketService();
    if (_buffer.isNotEmpty && socket.isConnected) {
      for (final ping in _buffer) {
        socket.emitLocationPing(
          driverId: ping.driverId,
          lat: ping.lat,
          lng: ping.lng,
          heading: ping.heading,
          speed: ping.speed,
          orderId: ping.orderId,
        );
      }
      _buffer.clear();
    }
  }

  static void stopTelemetrySync() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }
}
