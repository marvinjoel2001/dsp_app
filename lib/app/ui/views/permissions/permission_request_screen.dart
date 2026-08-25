import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import '../../../core/services/app_permissions_service.dart';
import '../feed/all_orders_feed_screen.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  final AppPermissionsService _permissionsService = AppPermissionsService();
  bool _isLoading = false;

  Future<void> _handleGrantPermissions() async {
    setState(() => _isLoading = true);

    final results = await _permissionsService.requestAllPermissions();

    setState(() => _isLoading = false);

    if (mounted) {
      final locationOk = results['location'] ?? false;
      if (locationOk) {
        context.pushReplacementAnimated(const AllOrdersFeedScreen());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '⚠️ La ubicación GPS es obligatoria para recibir pedidos y navegar.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'AJUSTES',
              textColor: Colors.white,
              onPressed: () => _permissionsService.openSettings(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Logo de Chiringuito Driver
              Row(
                children: [
                  AppSvgIcons.chiringuitoLogo(size: 32),
                  const SizedBox(width: 10),
                  const Text(
                    'CHIRINGUITO DRIVER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Permisos necesarios para repartir',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para garantizar entregas rápidas, seguras y acreditar tus pagos, Chiringuito necesita acceso a:',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Tarjetas de Permisos Explicativas
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionCard(
                      icon: Icons.location_on,
                      iconColor: AppColors.primary,
                      title: 'Ubicación Satelital GPS (Siempre activa)',
                      description:
                          'Permite al motor de despacho asignarte los pedidos más cercanos a tu posición y guiarte con navegación giro a giro.',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),

                    _buildPermissionCard(
                      icon: Icons.camera_alt,
                      iconColor: AppColors.secondary,
                      title: 'Cámara Fotográfica',
                      description:
                          'Requerido para tomar la foto del Comprobante de Entrega (POD) en el destino y subir tus documentos de verificación.',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),

                    _buildPermissionCard(
                      icon: Icons.notifications_active,
                      iconColor: const Color(0xFF2563EB),
                      title: 'Notificaciones de Alta Prioridad',
                      description:
                          'Te avisa al instante con sonido y vibración cuando entre una nueva orden con el temporizador de 30 segundos.',
                      isRequired: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Botón Principal de Conceder Permisos
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleGrantPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Conceder Permisos y Continuar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Omitir (para pruebas en desarrollo)
              Center(
                child: TextButton(
                  onPressed: () {
                    context.pushReplacementAnimated(const AllOrdersFeedScreen());
                  },
                  child: const Text(
                    'Continuar al mapa principal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isRequired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OBLIGATORIO',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
