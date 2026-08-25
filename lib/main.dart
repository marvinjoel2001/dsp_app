import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/network/api_client.dart';
import 'app/data/repositories/driver_repository_impl.dart';
import 'app/data/repositories/order_repository_impl.dart';
import 'app/ui/controllers/auth_controller.dart';
import 'app/ui/controllers/orders_feed_controller.dart';
import 'app/ui/controllers/active_ride_controller.dart';
import 'app/ui/views/auth/welcome_onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final driverRepo = DriverRepositoryImpl(apiClient: apiClient);
  final orderRepo = OrderRepositoryImpl(apiClient: apiClient);

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
      title: 'Food Drive - Courier',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeOnboardingScreen(),
    );
  }
}
