import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/socket_service.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/driver_repository.dart';

// Top-level handler para mensajes push recibidos en background o con app terminada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('🌙 [FCM Background] Notificación recibida: ${message.messageId}');
  debugPrint('🌙 [FCM Background] Data payload: ${message.data}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _cachedFcmToken;
  DriverRepository? _driverRepository;
  String? _currentDriverId;

  // Canal de notificación de alta importancia para Android
  static const AndroidNotificationChannel _highPriorityChannel = AndroidNotificationChannel(
    'chiringuito_dispatch_alerts', // id
    'Alertas de Despacho Chiringuito', // title
    description: 'Canal de máxima prioridad para asignación de pedidos urgentes y despacho',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  String? get fcmToken => _cachedFcmToken;

  /// Inicializa Firebase y los canales de notificación de forma segura (fail-safe)
  Future<void> initialize({DriverRepository? driverRepo}) async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    _driverRepository = driverRepo;

    try {
      // 1. Inicializar Firebase Core si está configurado en el proyecto
      try {
        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } catch (e) {
        debugPrint('⚠️ [PushNotificationService] Firebase no pudo inicializarse (falta google-services.json o credenciales): $e');
        debugPrint('ℹ️ La app continuará funcionando con despacho en tiempo real vía WebSockets.');
      }

      // 2. Configurar notificaciones locales para popups y alertas sonoras de alta prioridad
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response.payload);
        },
      );

      // 3. Crear el canal de alta importancia en Android
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_highPriorityChannel);
      }

      // 4. Solicitar permisos FCM y configurar listeners si Firebase está activo
      if (Firebase.apps.isNotEmpty) {
        final messaging = FirebaseMessaging.instance;

        // Solicitar permisos de notificación (sonido, badges, alertas críticas)
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: true,
          carPlay: true,
          criticalAlert: true,
          provisional: false,
        );
        debugPrint('🔔 [FCM] Permiso de notificaciones: ${settings.authorizationStatus}');

        // Obtener el FCM Token del dispositivo
        try {
          _cachedFcmToken = await messaging.getToken();
          debugPrint('🔑 [FCM Token]: $_cachedFcmToken');
          if (_cachedFcmToken != null && _currentDriverId != null && _driverRepository != null) {
            await _driverRepository!.updateFcmToken(_currentDriverId!, _cachedFcmToken!);
          }
        } catch (tokenErr) {
          debugPrint('⚠️ [FCM Token Error]: $tokenErr');
        }

        // Listener de actualización de Token FCM
        messaging.onTokenRefresh.listen((newToken) {
          _cachedFcmToken = newToken;
          debugPrint('🔄 [FCM Token Refreshed]: $newToken');
          if (_currentDriverId != null && _driverRepository != null) {
            _driverRepository!.updateFcmToken(_currentDriverId!, newToken);
          }
        });

        // 5. Escuchar notificaciones mientras la app está abierta en primer plano (Foreground)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('☀️ [FCM Foreground]: ${message.notification?.title} - ${message.notification?.body}');
          _processIncomingMessage(message);
          _showLocalNotification(message);
        });

        // 6. Escuchar cuando el usuario toca una notificación y abre la app desde segundo plano
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('📲 [FCM Clicked from background]: ${message.data}');
          _processIncomingMessage(message);
        });

        // 7. Verificar si la app fue abierta desde un estado cerrado/terminado por una notificación
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('🚀 [FCM Terminated App Launch]: ${initialMessage.data}');
          _processIncomingMessage(initialMessage);
        }
      }

      _isInitialized = true;
    } catch (err) {
      debugPrint('⚠️ [PushNotificationService Init Error]: $err');
    }
  }

  /// Vincula el conductor actual y registra su token en el backend
  Future<void> registerDriver(String driverId, {DriverRepository? driverRepo}) async {
    _currentDriverId = driverId;
    if (driverRepo != null) _driverRepository = driverRepo;

    if (_cachedFcmToken != null && _driverRepository != null) {
      await _driverRepository!.updateFcmToken(driverId, _cachedFcmToken!);
    }
  }

  /// Muestra una alerta visual y sonora local de máxima prioridad
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? '📦 ¡Nueva orden disponible!';
    final body = message.notification?.body ?? message.data['body'] ?? 'Tienes un nuevo pedido asignado. Abre la app para aceptarlo.';

    final androidDetails = AndroidNotificationDetails(
      _highPriorityChannel.id,
      _highPriorityChannel.name,
      channelDescription: _highPriorityChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Procesa los datos de la orden entrante y los inyecta al flujo en vivo
  void _processIncomingMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('orderId') || data.containsKey('id')) {
        // Enviar evento de orden simulado o parseado al SocketService para despertar la UI
        final orderMap = <String, dynamic>{
          'id': data['orderId'] ?? data['id'],
          'merchantReference': data['merchantReference'] ?? 'ORD-PUSH',
          'status': data['status'] ?? 'searching_driver',
          'pickupAddress': data['pickupAddress'] ?? 'Dirección de recogida',
          'pickupLat': double.tryParse(data['pickupLat']?.toString() ?? '0') ?? 0.0,
          'pickupLng': double.tryParse(data['pickupLng']?.toString() ?? '0') ?? 0.0,
          'dropoffAddress': data['dropoffAddress'] ?? 'Dirección de entrega',
          'dropoffLat': double.tryParse(data['dropoffLat']?.toString() ?? '0') ?? 0.0,
          'dropoffLng': double.tryParse(data['dropoffLng']?.toString() ?? '0') ?? 0.0,
          'price': double.tryParse(data['price']?.toString() ?? '0') ?? 15.0,
          'driverPayout': double.tryParse(data['driverPayout']?.toString() ?? '0') ?? 12.0,
          'packageNotes': data['packageNotes'],
          'trackingToken': data['trackingToken'],
        };
        final orderModel = OrderModel.fromJson(orderMap);
        SocketService().simulateIncomingOrderForTesting(orderModel);
      }
    } catch (e) {
      debugPrint('Error procesando payload de notificación push: $e');
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map<String, dynamic>) {
        final orderModel = OrderModel.fromJson(data);
        SocketService().simulateIncomingOrderForTesting(orderModel);
      }
    } catch (e) {
      debugPrint('Error procesando click en notificación: $e');
    }
  }
}
