import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
  static Timer? _syncTimer;

  static void startTelemetrySync(String driverId, {String? activeOrderId}) {
    _syncTimer?.cancel();

    // Sends telemetry ping every 5 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // In production, this pulls from Geolocator.getPositionStream
      // Here we simulate subtle movement coordinates for testing
      final ping = LocationPing(
        driverId: driverId,
        lat: -17.7833 + (timer.tick * 0.0001),
        lng: -63.1821 + (timer.tick * 0.0001),
        heading: 45.0,
        speed: 28.5,
        orderId: activeOrderId,
        timestamp: DateTime.now(),
      );

      sendOrBufferPing(ping);
    });
  }

  static void sendOrBufferPing(LocationPing ping) {
    final socket = SocketService();
    if (socket.isConnected) {
      // Flush buffered items if any
      flushBuffer();
      // Send current ping
      socket.emitLocationPing(
        driverId: ping.driverId,
        lat: ping.lat,
        lng: ping.lng,
        heading: ping.heading,
        speed: ping.speed,
        orderId: ping.orderId,
      );
    } else {
      // Buffer offline ping in memory
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
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
