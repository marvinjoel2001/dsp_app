import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import 'login_screen.dart';
import 'register_driver_screen.dart';

class WelcomeOnboardingScreen extends StatelessWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo Oficial SVG: CHIRINGUITO DRIVER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppSvgIcons.chiringuitoLogo(size: 34),
                  const SizedBox(width: 12),
                  const Text(
                    'CHIRINGUITO DRIVER',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Ilustración SVG de Alta Definición del Repartidor Express
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSvgIcons.motorcycleCourier(size: 110),
                          const SizedBox(height: 6),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              child: Text(
                                'REPARTIDOR EXPRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Título Principal
              const Text(
                'Entrega con Chiringuito.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Subtítulo
              const Text(
                'Gana dinero a tu manera con despacho inteligente.\nRecibe pedidos de comida y encomiendas en tiempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),

              const SizedBox(height: 36),

              // CTA 1: Empezar (Crear Cuenta)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    context.pushAnimated(const RegisterDriverScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Empezar (Crear Cuenta)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // CTA 2: Iniciar Sesión en Cuenta Existente
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    context.pushAnimated(const LoginScreen());
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión en cuenta existente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
