import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import '../../../core/constants/api_constants.dart';
import '../../controllers/orders_feed_controller.dart';
import '../../controllers/active_ride_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/order_feed_card.dart';
import '../../widgets/incoming_order_modal.dart';
import '../../widgets/connectivity_status_banner.dart';
import '../../widgets/active_trip_card.dart';
import '../drawer/driver_side_drawer.dart';
import '../navigation/live_map_navigation_screen.dart';
import '../wallet/earnings_wallet_screen.dart';
import '../profile/driver_documents_verification_screen.dart';
import '../profile/edit_driver_profile_screen.dart';

class AllOrdersFeedScreen extends StatefulWidget {
  const AllOrdersFeedScreen({super.key});

  @override
  State<AllOrdersFeedScreen> createState() => _AllOrdersFeedScreenState();
}

class _AllOrdersFeedScreenState extends State<AllOrdersFeedScreen> {
  int _selectedBottomNavIndex = 0;
  final MapController _homeMapController = MapController();

  void _showIncomingOrderModal(BuildContext context, dynamic order) {
    final activeRideCtrl = context.read<ActiveRideController>();
    final feedCtrl = context.read<OrdersFeedController>();
    final authCtrl = context.read<AuthController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => IncomingOrderModal(
        order: order,
        onAccept: () async {
          Navigator.pop(modalContext);
          final driverId = authCtrl.currentDriver?.id ?? 'c8716b1e-6240-4b2a-8c01-7faef83151cf';
          try {
            await feedCtrl.acceptOrder(order.id, driverId);
          } catch (_) {}
          activeRideCtrl.setActiveOrder(order);
          if (mounted) {
            context.pushAnimated(const LiveMapNavigationScreen());
          }
        },
        onDecline: () {
          Navigator.pop(modalContext);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden rechazada. Buscando nuevas solicitudes...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedCtrl = context.watch<OrdersFeedController>();
    final activeRideCtrl = context.watch<ActiveRideController>();
    final authCtrl = context.watch<AuthController>();

    final isOnline = authCtrl.currentDriver?.isOnline ?? false;
    final isVerified = authCtrl.isVerified;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const DriverSideDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcons.chiringuitoLogo(size: 26),
            const SizedBox(width: 8),
            const Text(
              'Chiringuito Driver',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Conmutador Rápido Online/Offline
          GestureDetector(
            onTap: () {
              final nextState = !isOnline;
              authCtrl.toggleOnline(nextState);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nextState
                        ? '🟢 Ahora estás EN LÍNEA y recibiendo pedidos de Chiringuito.'
                        : '⚪ Has pasado a estado FUERA DE LÍNEA.',
                  ),
                  backgroundColor: nextState ? AppColors.primaryDark : AppColors.textPrimary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOnline ? AppColors.primary : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.primary : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isOnline ? AppColors.primaryDark : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de Conectividad si está offline
            ConnectivityStatusBanner(isOnline: isOnline),

            // Banner de Advertencia si no está verificado
            if (!isVerified) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cuenta en revisión. Sube tus documentos para aceptar órdenes.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushAnimated(const DriverDocumentsVerificationScreen()),
                      child: const Text('Subir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.warning)),
                    ),
                  ],
                ),
              ),
            ],

            // Contenido Principal Según Tab Seleccionado
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildSelectedTabContent(feedCtrl, activeRideCtrl, authCtrl, isOnline),
              ),
            ),
          ],
        ),
      ),

      // Barra de Navegación Inferior Limpia
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.map_outlined, label: 'Inicio', index: 0),
                _buildNavItem(icon: Icons.list_alt, label: 'Órdenes', index: 1),
                _buildNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Billetera', index: 2),
                _buildNavItem(icon: Icons.person_outline, label: 'Perfil', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(
    OrdersFeedController feedCtrl,
    ActiveRideController activeRideCtrl,
    AuthController authCtrl,
    bool isOnline,
  ) {
    switch (_selectedBottomNavIndex) {
      case 0:
        return _buildHomeMapShell(feedCtrl, activeRideCtrl, authCtrl, isOnline);
      case 1:
        return _buildOrdersListTab(feedCtrl, activeRideCtrl, authCtrl);
      case 2:
        return const EarningsWalletScreen(showAppBarLeading: false);
      case 3:
        return _buildProfileTab(authCtrl);
      default:
        return _buildHomeMapShell(feedCtrl, activeRideCtrl, authCtrl, isOnline);
    }
  }

  Widget _buildHomeMapShell(
    OrdersFeedController feedCtrl,
    ActiveRideController activeRideCtrl,
    AuthController authCtrl,
    bool isOnline,
  ) {
    const driverLocation = LatLng(-17.7833, -63.1821);
    final hasActiveOrder = activeRideCtrl.activeOrder != null;

    return Stack(
      key: const ValueKey('home_map_shell'),
      children: [
        // Mapa Mapbox Light Base
        FlutterMap(
          mapController: _homeMapController,
          options: const MapOptions(
            initialCenter: driverLocation,
            initialZoom: 14.5,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: ApiConstants.mapboxLightStyleUrl,
              userAgentPackageName: 'com.chiringuito.driver',
              maxZoom: 19,
              subdomains: const ['a', 'b', 'c', 'd'],
            ),

            // Marcador SVG del Repartidor en Vivo (Píldora de Navegación)
            MarkerLayer(
              markers: [
                Marker(
                  point: driverLocation,
                  width: 44,
                  height: 70,
                  child: AppSvgIcons.vehicleNavMarker(
                    vehicleType: authCtrl.currentDriver?.vehicleType ?? 'MOTORCYCLE',
                    width: 44,
                    height: 70,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Panel Inferior Dinámico
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: hasActiveOrder
              // Tarjeta de Viaje Activo con diseño nativo y estadísticas completas
              ? ActiveTripCard(
                  order: activeRideCtrl.activeOrder,
                  driver: authCtrl.currentDriver,
                  onContinueGps: () {
                    context.pushAnimated(const LiveMapNavigationScreen());
                  },
                )
              : isOnline
                  // Estado Online: Radar y Órdenes Disponibles
                  ? Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Buscando ofertas de despacho cercanas...',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (feedCtrl.orders.isNotEmpty) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () => _showIncomingOrderModal(context, feedCtrl.orders.first),
                                icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
                                label: Text(
                                  'Ver Nueva Oferta (+Bs. ${feedCtrl.orders.first.driverPayout.toStringAsFixed(2)})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Te alertaremos automáticamente cuando entre un pedido.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    )
                  // Estado Offline: Tarjeta de descanso
                  : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Estás Fuera de Línea',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Conéctate a tu turno para empezar a recibir solicitudes de despacho en tiempo real.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => authCtrl.toggleOnline(true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text(
                                'CONECTARME AHORA',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildOrdersListTab(
    OrdersFeedController feedCtrl,
    ActiveRideController activeRideCtrl,
    AuthController authCtrl,
  ) {
    return Padding(
      key: const ValueKey('orders_list_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Órdenes Disponibles',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => feedCtrl.fetchOrders(authCtrl.currentDriver?.id ?? 'c8716b1e-6240-4b2a-8c01-7faef83151cf'),
              child: feedCtrl.orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 10),
                          Text('No hay órdenes en espera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: feedCtrl.orders.length,
                      itemBuilder: (context, index) {
                        final order = feedCtrl.orders[index];
                        return OrderFeedCard(
                          order: order,
                          onPickOrder: () async {
                            _showIncomingOrderModal(context, order);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AuthController authCtrl) {
    final driver = authCtrl.currentDriver;
    final isVerified = authCtrl.isVerified;

    return SingleChildScrollView(
      key: const ValueKey('profile_tab'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            child: const Icon(Icons.person, size: 44, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 10),
          Text(
            driver?.fullName ?? 'Alex Repartidor',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('${driver?.rating ?? 4.9} • Conductor Chiringuito', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.primaryLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isVerified ? 'VERIFICADO' : 'PENDIENTE',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: isVerified ? AppColors.primaryDark : AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Acciones de Perfil
          _buildProfileOption(
            icon: Icons.verified_user_outlined,
            title: 'Documentos y Verificación',
            subtitle: isVerified ? 'Documentación aprobada ✅' : 'Subir DNI, Licencia y SOAT ⏳',
            onTap: () => context.pushAnimated(const DriverDocumentsVerificationScreen()),
          ),
          const SizedBox(height: 10),

          _buildProfileOption(
            icon: Icons.edit_note,
            title: 'Editar Perfil y Vehículo',
            subtitle: 'Nombre, teléfono y placa de matrícula',
            onTap: () => context.pushAnimated(const EditDriverProfileScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.primaryDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedBottomNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedBottomNavIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isSelected ? AppColors.primary : AppColors.textMuted),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
