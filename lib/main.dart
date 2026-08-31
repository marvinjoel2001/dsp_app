import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/network/api_client.dart';
import 'app/data/repositories/driver_repository_impl.dart';
import 'app/data/repositories/order_repository_impl.dart';
import 'app/ui/controllers/auth_controller.dart';
import 'app/ui/controllers/orders_feed_controller.dart';
import 'app/ui/controllers/active_ride_controller.dart';
import 'app/ui/views/auth/splash_screen.dart';
import 'app/ui/views/auth/welcome_onboarding_screen.dart';
import 'app/ui/views/auth/login_screen.dart';
import 'app/ui/views/auth/register_driver_screen.dart';
import 'app/ui/views/feed/all_orders_feed_screen.dart';
import 'app/ui/views/wallet/earnings_wallet_screen.dart';
import 'app/ui/views/auth/driver_verification_pending_screen.dart';

import 'app/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Habilitar árbol semántico accesible continuo para pruebas automatizadas (Playwright / TestSprite)
  RendererBinding.instance.ensureSemantics();

  // Bloquear orientación exclusivamente en modo vertical (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final apiClient = ApiClient();
  final driverRepo = DriverRepositoryImpl(apiClient: apiClient);
  final orderRepo = OrderRepositoryImpl(apiClient: apiClient);

  // Inicializar Notificaciones Push (FCM) y canal de alta prioridad con sonido de sirena
  try {
    await PushNotificationService().initialize(driverRepo: driverRepo);
  } catch (e) {
    debugPrint('Inicialización push silenciosa: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(driverRepository: driverRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => OrdersFeedController(orderRepository: orderRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ActiveRideController(orderRepository: orderRepo),
        ),
      ],
      child: const OpenDspDriverApp(),
    ),
  );
}

class OpenDspDriverApp extends StatelessWidget {
  const OpenDspDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chiringuito Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeOnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterDriverScreen(),
        '/feed': (context) => const AllOrdersFeedScreen(),
        '/wallet': (context) => const EarningsWalletScreen(),
        '/verification': (context) => const DriverVerificationPendingScreen(),
      },
    );
  }
}
