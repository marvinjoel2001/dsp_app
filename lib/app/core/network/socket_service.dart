import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  String? _joinedDriverId;

  // Stream broadcast para eventos de órdenes en tiempo real
  final StreamController<dynamic> _orderEventStream = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onOrderEvent => _orderEventStream.stream;

  bool get isConnected => _isConnected;

  void initSocket() {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('⚡ WebSocket connected to OpenDSP Tracking Gateway');

      // Si el conductor ya había iniciado sesión, suscribirse automáticamente a su canal
      if (_joinedDriverId != null) {
        joinDriver(_joinedDriverId!);
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('⚠️ WebSocket disconnected');
    });

    _socket!.onConnectError((data) => debugPrint('Socket connection error: $data'));

    // Escuchas de eventos de órdenes en vivo
    _socket!.on('order:offer', (data) {
      debugPrint('📦 [Socket] Oferta de orden recibida: $data');
      _orderEventStream.add(data);
    });

    _socket!.on('order:broadcast', (data) {
      debugPrint('📢 [Socket] Orden broadcast recibida: $data');
      _orderEventStream.add(data);
    });

    _socket!.on('order:new', (data) {
      debugPrint('🆕 [Socket] Nueva orden global: $data');
      _orderEventStream.add(data);
    });
  }

  /// Suscribe al conductor a su sala privada en el gateway de despacho
  void joinDriver(String driverId) {
    _joinedDriverId = driverId;
    if (_socket != null && _isConnected) {
      _socket!.emit('driver:join', {'driverId': driverId});
      debugPrint('🚀 [Socket] driver:join emitido para: $driverId');
    }
  }

  /// Transmite el ping de telemetría GPS del repartidor
  void emitLocationPing({
    required String driverId,
    required double lat,
    required double lng,
    double heading = 0,
    double speed = 0,
    String? orderId,
  }) {
    if (_socket != null && _isConnected) {
      _socket!.emit('tracking:ping', {
        'driverId': driverId,
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'speed': speed,
        'orderId': orderId,
      });
    }
  }

  /// Suscribe a las actualizaciones en vivo de una orden específica
  void subscribeToOrder(String orderId, Function(dynamic) onUpdate) {
    if (_socket != null) {
      _socket!.emit('order:subscribe', {'orderId': orderId});
      _socket!.on('order:location_update', onUpdate);
    }
  }

  /// Método para simular o testear una orden entrante manualmente
  void simulateIncomingOrderForTesting(dynamic orderData) {
    _orderEventStream.add(orderData);
  }

  void disconnect() {
    if (_joinedDriverId != null && _socket != null && _isConnected) {
      _socket!.emit('driver:leave', {'driverId': _joinedDriverId});
    }
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    _joinedDriverId = null;
  }
}
