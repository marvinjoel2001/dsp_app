import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/active_ride_controller.dart';
import '../navigation/live_map_navigation_screen.dart';
import '../wallet/earnings_wallet_screen.dart';
import '../profile/driver_documents_verification_screen.dart';
import '../profile/edit_driver_profile_screen.dart';
import '../auth/welcome_onboarding_screen.dart';

class DriverSideDrawer extends StatelessWidget {
  const DriverSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final driver = authCtrl.currentDriver;
    final isVerified = authCtrl.isVerified;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Encabezado del Conductor: Avatar, Nombre, Calificación y Selector Online
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nombre y Calificación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver?.fullName ?? 'Alex Repartidor',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${driver?.rating ?? 4.9}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isVerified ? AppColors.primaryLight : AppColors.warningLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isVerified ? 'VERIFICADO' : 'PENDIENTE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: isVerified ? AppColors.primaryDark : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Interruptor Libre / Ocupado (Disponibilidad del conductor)
                  GestureDetector(
                    onTap: () {
                      final newState = !(driver?.isOnline ?? false);
                      authCtrl.toggleOnline(newState);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newState
                                ? '🟢 Ahora estás LIBRE y visible para recibir pedidos de Chiringuito'
                                : '⚪ Has pasado a estado OCUPADO (No recibirás pedidos)',
                          ),
                          backgroundColor: newState ? const Color(0xFF10B981) : const Color(0xFF475569),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (driver?.isOnline ?? false)
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (driver?.isOnline ?? false)
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (driver?.isOnline ?? false) ? 'LIBRE' : 'OCUPADO',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 14),

            // Enlaces de Navegación
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Viajes Activos
                  _buildDrawerItem(
                    icon: Icons.alt_route,
                    title: 'Viajes Activos',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                      final activeOrder = context.read<ActiveRideController>().activeOrder;
                      if (activeOrder == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ℹ️ No tienes ningún viaje activo en curso.'),
                            backgroundColor: Color(0xFF0F172A),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        context.pushAnimated(const LiveMapNavigationScreen());
                      }
                    },
                  ),
                  const SizedBox(height: 6),

                  // Ganancias y Billetera
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Ganancias y Billetera',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushAnimated(const EarningsWalletScreen());
                    },
                  ),
                  const SizedBox(height: 6),

                  // Documentos y Verificación
                  _buildDrawerItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Documentos y Verificación',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushAnimated(const DriverDocumentsVerificationScreen());
                    },
                  ),
                  const SizedBox(height: 6),

                  // Editar Perfil y Vehículo
                  _buildDrawerItem(
                    icon: Icons.edit_note_outlined,
                    title: 'Editar Perfil y Vehículo',
                    onTap: () {
                      Navigator.pop(context);
                      context.pushAnimated(const EditDriverProfileScreen());
                    },
                  ),
                  const SizedBox(height: 6),

                  // Detalles del Vehículo Modal
                  _buildDrawerItem(
                    icon: Icons.two_wheeler_outlined,
                    title: 'Detalles del Vehículo',
                    onTap: () {
                      Navigator.pop(context);
                      _showVehicleDialog(context, driver);
                    },
                  ),
                  const SizedBox(height: 6),

                  // Rendimiento
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'Rendimiento y Métricas',
                    onTap: () {
                      Navigator.pop(context);
                      _showPerformanceDialog(context);
                    },
                  ),
                  const SizedBox(height: 6),

                  // Ayuda y Soporte
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Soporte y Despacho',
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportDialog(context);
                    },
                  ),
                  const SizedBox(height: 6),

                  // Cerrar Sesión
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Cerrar Sesión',
                    customColor: AppColors.error,
                    onTap: () async {
                      Navigator.pop(context);
                      await authCtrl.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const WelcomeOnboardingScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Footer Brand con SVG Oficial
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  AppSvgIcons.chiringuitoLogo(size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'CHIRINGUITO DRIVER',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDialog(BuildContext context, dynamic driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            AppSvgIcons.motorcycleCourier(size: 24),
            const SizedBox(width: 10),
            const Text('Detalles del Vehículo', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tipo', driver?.vehicleType ?? 'MOTORCYCLE'),
            _buildDetailRow('Placa', driver?.vehiclePlate ?? '1234-XYZ'),
            _buildDetailRow('Modelo', 'Honda CB 160cc (2024)'),
            _buildDetailRow('Seguro', 'SOAT Vigente hasta Dic 2026'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showPerformanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Estadísticas de Rendimiento', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Calificación', '4.9 ★ (Top 5% de Conductores)'),
            _buildDetailRow('Tasa de Aceptación', '99.2%'),
            _buildDetailRow('Puntualidad', '98.5% a tiempo'),
            _buildDetailRow('Órdenes Completadas', '142 entregas'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Central de Despacho Chiringuito', style: TextStyle(color: AppColors.textPrimary)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Necesitas asistencia con una orden o entrega activa?', style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF334155))),
            SizedBox(height: 12),
            Text('📞 Línea de Despacho: +591 700-00000', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            SizedBox(height: 6),
            Text('💬 WhatsApp Operaciones: +591 711-22334', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    Color? customColor,
    required VoidCallback onTap,
  }) {
    final itemColor = customColor ?? (isSelected ? Colors.white : AppColors.textPrimary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: itemColor,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
