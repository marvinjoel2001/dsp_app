import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_transitions.dart';
import '../../controllers/auth_controller.dart';
import '../feed/all_orders_feed_screen.dart';
import 'welcome_onboarding_screen.dart';
import 'driver_verification_pending_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoFinished = false;
  bool _hasNavigated = false;

  late AnimationController _logoAnimController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;

  late AnimationController _videoFadeController;
  late Animation<double> _videoOpacity;

  @override
  void initState() {
    super.initState();

    // 1. Animaciones para el Splash del Logo
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeOutBack),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn),
    );

    // 2. Animación para desvanecer el video al terminar
    _videoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _videoOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _videoFadeController, curve: Curves.easeInOut),
    );

    // 3. Inicializar Video Player con Sonido
    _initVideoSplash();
  }

  Future<void> _initVideoSplash() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video/video_splash.mp4');
      await _videoController!.initialize();
      await _videoController!.setVolume(1.0); // Con sonido completo
      await _videoController!.play();

      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }

      _videoController!.addListener(_videoListener);
    } catch (e) {
      // Fallback si el dispositivo/emulador no soporta el formato de video
      if (mounted) {
        _onVideoFinished();
      }
    }
  }

  void _videoListener() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;

    // Detectar fin del video (con margen de 200ms)
    if (dur > Duration.zero && pos >= dur - const Duration(milliseconds: 200)) {
      _videoController!.removeListener(_videoListener);
      _onVideoFinished();
    }
  }

  void _onVideoFinished() {
    if (_isVideoFinished) return;
    _isVideoFinished = true;

    // Desvanecer video e iniciar splash con logo
    _videoFadeController.forward().then((_) {
      if (mounted) {
        setState(() {});
        _logoAnimController.forward();

        // Redirección suave al Onboarding o Feed
        Future.delayed(const Duration(milliseconds: 1600), () {
          _navigateToNextScreen();
        });
      }
    });
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final authCtrl = context.read<AuthController>();
    if (authCtrl.isAuthenticated) {
      if (authCtrl.isPendingVerification) {
        context.pushReplacementAnimated(const DriverVerificationPendingScreen());
      } else {
        context.pushReplacementAnimated(const AllOrdersFeedScreen());
      }
    } else {
      context.pushReplacementAnimated(const WelcomeOnboardingScreen());
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _logoAnimController.dispose();
    _videoFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Capa Inferior: Splash Screen con Logo Oficial Animado
          Center(
            child: FadeTransition(
              opacity: _logoFadeAnimation,
              child: ScaleTransition(
                scale: _logoScaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Oficial Chiringuito Driver
                    Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            blurRadius: 36,
                            spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/driver_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.delivery_dining,
                          size: 72,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título Oficial con Tipografía de Impacto
                    const Text(
                      'CHIRINGUITO DRIVER',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtítulo
                    const Text(
                      'Despacho Inteligente & Logística Express',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Spinner sutil
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Capa Superior: Video Splash Fullscreen con Sonido y Desvanecimiento
          if (_videoController != null && _isVideoInitialized && !_videoFadeController.isCompleted)
            Positioned.fill(
              child: FadeTransition(
                opacity: _videoOpacity,
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video ocupando toda la pantalla
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width > 0
                              ? _videoController!.value.size.width
                              : 1080,
                          height: _videoController!.value.size.height > 0
                              ? _videoController!.value.size.height
                              : 1920,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),

                      // Botón Omitir Sutil (Esquina Superior Derecha)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        right: 16,
                        child: InkWell(
                          onTap: _onVideoFinished,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Omitir',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
