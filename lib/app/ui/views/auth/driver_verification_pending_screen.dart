import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/page_transitions.dart';
import '../../controllers/auth_controller.dart';
import '../feed/all_orders_feed_screen.dart';
import 'welcome_onboarding_screen.dart';

class DriverVerificationPendingScreen extends StatefulWidget {
  const DriverVerificationPendingScreen({super.key});

  @override
  State<DriverVerificationPendingScreen> createState() => _DriverVerificationPendingScreenState();
}

class _DriverVerificationPendingScreenState extends State<DriverVerificationPendingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    final authCtrl = context.read<AuthController>();

    await Future.delayed(const Duration(milliseconds: 800));
    await authCtrl.refreshProfile();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (authCtrl.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Felicidades! Tu cuenta ha sido validada y activada exitosamente.'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.pushReplacementAnimated(const AllOrdersFeedScreen());
    } else if (authCtrl.isRejectedVerification) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tu documentación requiere correcciones. Por favor contacta a soporte.'),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Tu cuenta sigue en revisión. Por favor espera unos minutos más.'),
          backgroundColor: Color(0xFFD97706),
        ),
      );
    }
  }

  Future<void> _openWhatsAppSupport() async {
    final phone = '+59170000000';
    final driver = context.read<AuthController>().currentDriver;
    final text = Uri.encodeComponent(
      'Hola equipo de operaciones Chiringuito, solicito la activación de mi cuenta de conductor: ${driver?.fullName ?? ""} (CI: ${driver?.ciNumber ?? ""})',
    );
    final url = Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^\d]'), '')}?text=$text');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final driver = authCtrl.currentDriver;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () {
              context.pushReplacementAnimated(const WelcomeOnboardingScreen());
            },
            icon: const Icon(Icons.logout, size: 16, color: Color(0xFF64748B)),
            label: const Text('Salir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Escudo de Verificación Animado con Pulso
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 48,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Título Principal
              const Text(
                'Tu Cuenta está en Revisión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Mensaje Claro y Tranquilizador
              const Text(
                'Debes esperar a que nuestro equipo valide tu información. Usualmente este proceso tarda unos minutos.\n\nPor normativas de seguridad vial y legal en Bolivia, no podrás recibir órdenes hasta que tu cuenta sea aprobada por la central.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Resumen de Documentos Recibidos
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: driver?.avatarUrl != null && driver!.avatarUrl!.isNotEmpty
                              ? NetworkImage(driver!.avatarUrl!)
                              : null,
                          child: (driver?.avatarUrl == null || driver!.avatarUrl!.isEmpty)
                              ? const Icon(Icons.person, color: Color(0xFF64748B))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver?.fullName ?? 'Conductor Solicitante',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'C.I. ${driver?.ciNumber ?? "Registrado"} • ${driver?.vehicleType ?? "MOTO"}',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'EN ESPERA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 14),

                    _buildCheckItem(
                      icon: Icons.face,
                      title: 'Fotografía Facial de Seguridad',
                      subtitle: 'Capturada en vivo con cámara',
                      isCompleted: driver?.avatarUrl != null && driver!.avatarUrl!.isNotEmpty,
                    ),
                    const SizedBox(height: 10),
                    _buildCheckItem(
                      icon: Icons.badge_outlined,
                      title: 'Cédula de Identidad & Domicilio',
                      subtitle: driver?.homeAddress ?? 'Domicilio verificado',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCheckItem(
                      icon: Icons.assignment_outlined,
                      title: 'Contrato y Deslinde Legal Firmado',
                      subtitle: 'Suscrito bajo leyes bolivianas (Cód. Civil)',
                      isCompleted: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Botón Comprobar Estado
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _checkVerificationStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.sync, size: 20, color: Colors.white),
                  label: Text(
                    _isChecking ? 'Comprobando estado...' : 'Comprobar Estado de Validación',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón WhatsApp Soporte
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _openWhatsAppSupport,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF059669)),
                  label: const Text(
                    'Contactar Soporte de Activación',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6EE7B7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isCompleted ? AppColors.primary : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: isCompleted ? AppColors.primary : const Color(0xFFCBD5E1),
        ),
      ],
    );
  }
}
