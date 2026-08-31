import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/location_buffer_service.dart';
import '../../../core/services/app_audio_service.dart';
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
import '../auth/driver_verification_pending_screen.dart';

class AllOrdersFeedScreen extends StatefulWidget {
  const AllOrdersFeedScreen({super.key});

  @override
  State<AllOrdersFeedScreen> createState() => _AllOrdersFeedScreenState();
}

class _AllOrdersFeedScreenState extends State<AllOrdersFeedScreen> {
  int _selectedBottomNavIndex = 0;
  final MapController _homeMapController = MapController();
  StreamSubscription? _orderSubscription;
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedCtrl = context.read<OrdersFeedController>();
      final authCtrl = context.read<AuthController>();
      if (authCtrl.currentDriver != null) {
        feedCtrl.fetchOrders(authCtrl.currentDriver!.id);
      }

      // Escucha reactiva en tiempo real para nuevas órdenes entrantes vía WebSockets
      _orderSubscription = feedCtrl.onIncomingOffer.listen((order) {
        if (mounted) {
          _showIncomingOrderModal(context, order);
        }
      });
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _showIncomingOrderModal(BuildContext context, dynamic order) {
    if (_isModalOpen) return;
    final activeRideCtrl = context.read<ActiveRideController>();
    if (activeRideCtrl.activeOrder != null) return;

    final feedCtrl = context.read<OrdersFeedController>();
    final authCtrl = context.read<AuthController>();

    _isModalOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => IncomingOrderModal(
        order: order,
        onAccept: () async {
          _isModalOpen = false;
          Navigator.pop(modalContext);
          await AppAudioService().playOrderAccepted();
          final driverId = authCtrl.currentDriver?.id ?? '';
          if (driverId.isNotEmpty) {
            try {
              await feedCtrl.acceptOrder(order.id, driverId);
            } catch (_) {}
          }
          activeRideCtrl.setActiveOrder(order, driverId: driverId);
          if (context.mounted) {
            context.pushAnimated(const LiveMapNavigationScreen());
          }
        },
        onDecline: () {
          _isModalOpen = false;
          Navigator.pop(modalContext);
          AppAudioService().stopAlertSound();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden rechazada. Buscando nuevas solicitudes...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ).then((_) {
      _isModalOpen = false;
      AppAudioService().stopAlertSound();
    });
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
          // Conmutador Rápido Libre/Ocupado (Disponibilidad)
          GestureDetector(
            onTap: () {
              if (!isVerified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏳ Tu cuenta está en revisión por la central. No puedes recibir órdenes hasta ser aprobado.'),
                    backgroundColor: Color(0xFFD97706),
                    duration: Duration(seconds: 3),
                  ),
                );
                context.pushAnimated(const DriverVerificationPendingScreen());
                return;
              }
              final nextState = !isOnline;
              authCtrl.toggleOnline(nextState);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    nextState
                        ? '🟢 Ahora estás LIBRE y recibiendo pedidos de Chiringuito.'
                        : '⚪ Has pasado a estado OCUPADO (No recibirás alertas).',
                  ),
                  backgroundColor: nextState ? const Color(0xFF10B981) : const Color(0xFF475569),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOnline ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? 'LIBRE' : 'OCUPADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isOnline ? const Color(0xFF047857) : const Color(0xFF64748B),
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
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cuenta en revisión por la central. Debes esperar a que validen tu información para recibir órdenes.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushAnimated(const DriverVerificationPendingScreen()),
                      child: const Text('Ver Estado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.warning)),
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
    final hasActiveOrder = activeRideCtrl.activeOrder != null && activeRideCtrl.currentStage != RideStage.delivered;

    return ValueListenableBuilder<LatLng?>(
      valueListenable: LocationBufferService.currentPositionNotifier,
      builder: (context, currentPos, _) {
        final driverLocation = currentPos ?? const LatLng(-17.7833, -63.1821);

        return Stack(
          key: const ValueKey('home_map_shell'),
          children: [
            // Mapa Mapbox Light Base con Ubicación GPS Real
            FlutterMap(
              mapController: _homeMapController,
              options: MapOptions(
                initialCenter: driverLocation,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: ApiConstants.mapboxLightStyleUrl,
                  userAgentPackageName: 'com.chiringuito.driver',
                  maxZoom: 19,
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),

                // Capa de Radio / Radar Translúcido alrededor del Repartidor
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: driverLocation,
                      radius: 46,
                      useRadiusInMeter: false,
                      color: const Color(0xFF10B981).withValues(alpha: 0.26),
                      borderColor: const Color(0xFF10B981).withValues(alpha: 0.60),
                      borderStrokeWidth: 2.0,
                    ),
                    CircleMarker(
                      point: driverLocation,
                      radius: 28,
                      useRadiusInMeter: false,
                      color: const Color(0xFF34D399).withValues(alpha: 0.18),
                      borderColor: Colors.transparent,
                    ),
                  ],
                ),

                // Marcador del Repartidor en Vivo
                MarkerLayer(
                  markers: [
                    Marker(
                      point: driverLocation,
                      width: 50,
                      height: 50,
                      child: AppSvgIcons.vehicleNavMarker(
                        vehicleType: authCtrl.currentDriver?.vehicleType ?? 'MOTORCYCLE',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Botón Flotante para Re-centrar el Mapa en el GPS del Conductor
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'home_gps_recenter',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 3,
                onPressed: () {
                  final pos = LocationBufferService.currentPositionNotifier.value ?? const LatLng(-17.7833, -63.1821);
                  _homeMapController.move(pos, 16.0);
                },
                child: const Icon(Icons.my_location_rounded, size: 20),
              ),
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
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      const Text(
                                        'Buscando pedidos...',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  // Botón de prueba para probar sonido, vibración y modal
                                  InkWell(
                                    onTap: () => feedCtrl.simulateOrderOfferForTesting(),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFF59E0B)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.volume_up_rounded, size: 12, color: Color(0xFFD97706)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Probar Alerta',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                          ),
                                        ],
                                      ),
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
                                  'Te alertaremos con sonido y vibración cuando entre un pedido.',
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
                                color: Colors.black.withValues(alpha: 0.08),
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
                                      color: Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Estás en modo OCUPADO (No disponible)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Pasa a estado LIBRE arriba para recibir pedidos y generar ganancias.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        );
      },
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
              onRefresh: () {
                final driverId = authCtrl.currentDriver?.id ?? '';
                if (driverId.isNotEmpty) {
                  return feedCtrl.fetchOrders(driverId);
                }
                return Future.value();
              },
              child: feedCtrl.orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
