import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/constants/api_constants.dart';
import '../../controllers/active_ride_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/turn_guidance_card.dart';
import '../../widgets/proof_of_delivery_dialog.dart';
import '../../widgets/cancel_order_dialog.dart';

class LiveMapNavigationScreen extends StatefulWidget {
  const LiveMapNavigationScreen({super.key});

  @override
  State<LiveMapNavigationScreen> createState() => _LiveMapNavigationScreenState();
}

class _LiveMapNavigationScreenState extends State<LiveMapNavigationScreen> {
  final MapController _mapController = MapController();
  bool _autoFollowDriver = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rideCtrl = context.read<ActiveRideController>();
      rideCtrl.calculateCurrentRoute();
    });
  }

  void _recenterOnDriver(LatLng driverPos, double zoom) {
    setState(() => _autoFollowDriver = true);
    _mapController.move(driverPos, zoom);
  }

  void _showHelpMenu(BuildContext context) {
    final rideCtrl = context.read<ActiveRideController>();
    final order = rideCtrl.activeOrder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Opciones de Asistencia y Ruta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // 1. Recalcular Ruta Mapbox
            _buildHelpOption(
              icon: Icons.alt_route,
              color: AppColors.primary,
              title: 'Recalcular Ruta por Calles',
              subtitle: 'Consultar tráfico y trayecto óptimo en Mapbox',
              onTap: () {
                Navigator.pop(context);
                rideCtrl.calculateCurrentRoute();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗺️ Ruta recalculada con tráfico en tiempo real.'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 2. Central de Despacho
            _buildHelpOption(
              icon: Icons.support_agent,
              color: AppColors.primary,
              title: 'Central de Despacho Chiringuito',
              subtitle: 'Línea de soporte operativo (+591 700-00000)',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📞 Conectando con la Central de Despacho...'),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // 3. Cancelar Orden Segura
            if (order != null)
              _buildHelpOption(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                title: 'Cancelar Orden',
                subtitle: 'Comercio cerrado, avería de vehículo o emergencia',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => CancelOrderDialog(
                      orderId: order.id,
                      onConfirmCancel: (reason) async {
                        await rideCtrl.cancelActiveOrder(reason);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🚫 Orden cancelada y reasignada a la central.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required Color color,
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideCtrl = context.watch<ActiveRideController>();
    final authCtrl = context.watch<AuthController>();
    final order = rideCtrl.activeOrder;

    final pickupPoint = LatLng(order?.pickupLat ?? -17.7833, order?.pickupLng ?? -63.1821);
    final dropoffPoint = LatLng(order?.dropoffLat ?? -17.7950, order?.dropoffLng ?? -63.1700);

    final isDelivering = rideCtrl.currentStage == RideStage.inTransit;
    final driverPos = rideCtrl.driverLocation;

    // Auto-centrar si está activado el seguimiento
    if (_autoFollowDriver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(driverPos, rideCtrl.is3DView ? 16.8 : 15.5);
        } catch (_) {}
      });
    }

    final currentStep = (rideCtrl.routeSteps.isNotEmpty && rideCtrl.currentStepIndex < rideCtrl.routeSteps.length)
        ? rideCtrl.routeSteps[rideCtrl.currentStepIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Capa de Mapa Vectorial Mapbox Light con Rutas Reales por Calles
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverPos,
              initialZoom: rideCtrl.is3DView ? 16.8 : 15.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _autoFollowDriver) {
                  setState(() => _autoFollowDriver = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: ApiConstants.mapboxLightStyleUrl,
                userAgentPackageName: 'com.chiringuito.driver',
                maxZoom: 19,
                subdomains: const ['a', 'b', 'c', 'd'],
              ),

              // Capa de Ruta con Borde Casing (Máxima Visibilidad en Carreteras)
              if (rideCtrl.routePolyline.isNotEmpty) ...[
                // Línea de fondo (Borde oscuro para alto contraste)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: rideCtrl.routePolyline,
                      strokeWidth: 8.0,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                    ),
                  ],
                ),
                // Línea principal (Verde Esmeralda o Ámbar brillante)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: rideCtrl.routePolyline,
                      strokeWidth: 5.5,
                      color: isDelivering ? AppColors.primary : AppColors.secondary,
                    ),
                  ],
                ),
              ],

              // Marcadores Vectoriales SVG Reales
              MarkerLayer(
                markers: [
                  // Marcador SVG de Comercio (Punto de Recogida)
                  Marker(
                    point: pickupPoint,
                    width: 48,
                    height: 58,
                    child: AppSvgIcons.storePickupMarker(size: 48),
                  ),

                  // Marcador SVG de Destino (Cliente Final)
                  Marker(
                    point: dropoffPoint,
                    width: 48,
                    height: 58,
                    child: AppSvgIcons.customerDropoffMarker(size: 48),
                  ),

                  // Marcador SVG del Repartidor en Vivo (Píldora con Moto/Vehículo y Rumbo)
                  Marker(
                    point: driverPos,
                    width: 44,
                    height: 70,
                    child: Transform.rotate(
                      angle: rideCtrl.driverHeading * (pi / 180.0),
                      child: AppSvgIcons.vehicleNavMarker(
                        vehicleType: authCtrl.currentDriver?.vehicleType ?? 'MOTORCYCLE',
                        width: 44,
                        height: 70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Encabezado de Navegación Flotante
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Minimizar / Volver al Inicio
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ),

                  Row(
                    children: [
                      // Botón 2D / 3D
                      InkWell(
                        onTap: () {
                          rideCtrl.toggle3D();
                          _mapController.move(driverPos, rideCtrl.is3DView ? 16.8 : 15.5);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: rideCtrl.is3DView ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: rideCtrl.is3DView ? AppColors.primary : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                            ],
                          ),
                          child: Text(
                            rideCtrl.is3DView ? '3D' : '2D',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: rideCtrl.is3DView ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón Recentrar Conductor
                      InkWell(
                        onTap: () => _recenterOnDriver(driverPos, rideCtrl.is3DView ? 16.8 : 15.5),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _autoFollowDriver ? AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _autoFollowDriver ? AppColors.primary : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 16,
                                color: _autoFollowDriver ? AppColors.primaryDark : AppColors.textPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GPS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _autoFollowDriver ? AppColors.primaryDark : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón Ayuda / Cancelación
                      InkWell(
                        onTap: () => _showHelpMenu(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.help_outline, size: 16, color: AppColors.textPrimary),
                              SizedBox(width: 4),
                              Text(
                                'Ayuda',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. HUD Superior de Navegación Turn-By-Turn (Modo Giro a Giro Profesional)
          Positioned(
            top: 72,
            left: 16,
            right: 16,
            child: TurnGuidanceCard(
              instruction: rideCtrl.turnGuidance,
              modifier: currentStep?.modifier,
              distanceMeters: currentStep?.distanceMeters ?? (rideCtrl.routeDistanceKm * 1000),
              durationMinutes: rideCtrl.routeDurationMin,
              speedKmh: rideCtrl.driverSpeedKmh,
            ),
          ),

          // 4. Panel Inferior Bottom Sheet Contextual
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta del Paso Actual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDelivering ? AppColors.primaryLight : AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDelivering ? 'PASO 2 DE 2: ENTREGA AL CLIENTE' : 'PASO 1 DE 2: RECOGIDA EN COMERCIO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isDelivering ? AppColors.primaryDark : AppColors.secondaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${rideCtrl.routeDistanceKm.toStringAsFixed(1)} km • ${rideCtrl.routeDurationMin} min',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Dirección Destacada
                  Text(
                    isDelivering
                        ? (order?.dropoffAddress ?? 'Av. Las Palmas #420')
                        : (order?.pickupAddress ?? 'Restaurante El Chiringuito Central'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Fila de Acciones de Contacto Rápido
                  Row(
                    children: [
                      // Botón Llamar
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final phone = isDelivering ? rideCtrl.customerPhone : rideCtrl.merchantPhone;
                            final url = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                            try {
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('📞 Llamando al ${isDelivering ? "Cliente" : "Comercio"}: $phone'),
                                      backgroundColor: AppColors.primaryDark,
                                    ),
                                  );
                                }
                              }
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.phone, size: 16, color: AppColors.textPrimary),
                          label: const Text('Llamar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón WhatsApp / Chat
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final phone = isDelivering ? rideCtrl.customerPhone : rideCtrl.merchantPhone;
                            final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                            final text = Uri.encodeComponent('Hola, soy tu repartidor de Chiringuito con la orden #${order?.id ?? ""}');
                            final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=$text');
                            try {
                              if (await canLaunchUrl(waUrl)) {
                                await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('💬 Abriendo chat con el cliente...'),
                                      backgroundColor: AppColors.primaryDark,
                                    ),
                                  );
                                }
                              }
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primaryDark),
                          label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón Navegación Externa (Google Maps / Waze)
                      IconButton(
                        onPressed: () async {
                          final destLat = isDelivering ? dropoffPoint.latitude : pickupPoint.latitude;
                          final destLng = isDelivering ? dropoffPoint.longitude : pickupPoint.longitude;
                          final mapUrl = Uri.parse('geo:$destLat,$destLng?q=$destLat,$destLng');
                          try {
                            if (await canLaunchUrl(mapUrl)) {
                              await launchUrl(mapUrl);
                            } else {
                              final webMapUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$destLat,$destLng');
                              await launchUrl(webMapUrl, mode: LaunchMode.externalApplication);
                            }
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF64748B)),
                        tooltip: 'Abrir en Google Maps / Waze',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Botón de Acción Principal (CTA Masivo para Uso con una Sola Mano)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (rideCtrl.currentStage == RideStage.inTransit) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ProofOfDeliveryDialog(
                              onConfirmed: ({proofUrl, signatureSvg, notes}) async {
                                final payout = order?.driverPayout ?? 43.20;
                                await rideCtrl.advanceNextStage(
                                  proofPhotoUrl: proofUrl,
                                  signatureSvg: signatureSvg,
                                  notes: notes,
                                );
                                if (context.mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                                          SizedBox(width: 10),
                                          Text('¡Entrega Completada!'),
                                        ],
                                      ),
                                      content: Text(
                                        '🎉 ¡Excelente trabajo, ${authCtrl.currentDriver?.fullName ?? "Alex"}!\n\nHas ganado +\$${payout.toStringAsFixed(2)} USD por esta entrega. El comprobante POD fue respaldado en Cloudinary y tu saldo ha sido acreditado en Chiringuito.',
                                        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                          child: const Text('Volver al Mapa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        } else {
                          rideCtrl.advanceNextStage();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDelivering ? AppColors.primary : AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _getActionLabel(rideCtrl.currentStage),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(RideStage stage) {
    switch (stage) {
      case RideStage.assigned:
        return '1. LLEGADA AL COMERCIO (RECOGIDA)';
      case RideStage.arrivedAtPickup:
        return '2. CONFIRMAR RECOGIDA DE PEDIDO';
      case RideStage.inTransit:
        return '3. LLEGADA AL DESTINO (ENTREGAR)';
      case RideStage.delivered:
        return 'ORDEN COMPLETADA';
    }
  }
}
