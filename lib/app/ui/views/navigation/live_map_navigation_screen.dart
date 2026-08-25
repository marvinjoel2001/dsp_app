import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../controllers/active_ride_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/turn_guidance_card.dart';
import '../../widgets/proof_of_delivery_dialog.dart';

class LiveMapNavigationScreen extends StatefulWidget {
  const LiveMapNavigationScreen({super.key});

  @override
  State<LiveMapNavigationScreen> createState() => _LiveMapNavigationScreenState();
}

class _LiveMapNavigationScreenState extends State<LiveMapNavigationScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final rideCtrl = context.watch<ActiveRideController>();
    final authCtrl = context.watch<AuthController>();
    final order = rideCtrl.activeOrder;

    // Coordenadas de la ruta (Recogida -> Entrega)
    final pickupPoint = LatLng(order?.pickupLat ?? -17.7833, order?.pickupLng ?? -63.1821);
    final dropoffPoint = LatLng(order?.dropoffLat ?? -17.7950, order?.dropoffLng ?? -63.1700);
    final midpoint = LatLng(
      (pickupPoint.latitude + dropoffPoint.latitude) / 2,
      (pickupPoint.longitude + dropoffPoint.longitude) / 2,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. Capa de Mapa Vectorial/Raster Mapbox (¡SIN GOOGLE MAPS!)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: midpoint,
              initialZoom: rideCtrl.is3DView ? 16.0 : 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Tiles de Mapbox Light
              TileLayer(
                urlTemplate: ApiConstants.mapboxLightStyleUrl,
                userAgentPackageName: 'com.opendsp.driver',
                maxZoom: 19,
                subdomains: const ['a', 'b', 'c', 'd'],
              ),

              // Línea de Ruta en Verde Esmeralda Vibrante
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      pickupPoint,
                      LatLng(pickupPoint.latitude - 0.003, pickupPoint.longitude + 0.002),
                      LatLng(pickupPoint.latitude - 0.006, pickupPoint.longitude + 0.006),
                      dropoffPoint,
                    ],
                    strokeWidth: 5.5,
                    color: AppColors.primary,
                  ),
                ],
              ),

              // Marcadores: Recogida (Ámbar), Entrega (Casa Verde), Repartidor en Vivo
              MarkerLayer(
                markers: [
                  // Marcador de Recogida
                  Marker(
                    point: pickupPoint,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),

                  // Marcador de Entrega
                  Marker(
                    point: dropoffPoint,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 20),
                    ),
                  ),

                  // Pin en Vivo del Repartidor
                  Marker(
                    point: LatLng(pickupPoint.latitude - 0.003, pickupPoint.longitude + 0.002),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Encabezado de Navegación Superior
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Volver
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),

                  // Conmutador 2D / 3D
                  InkWell(
                    onTap: () {
                      rideCtrl.toggle3D();
                      _mapController.move(midpoint, rideCtrl.is3DView ? 16.0 : 14.5);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: rideCtrl.is3DView ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: rideCtrl.is3DView ? AppColors.primary : const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                          ),
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
                ],
              ),
            ),
          ),

          // 3. Tarjeta Flotante Superior de Guía de Giros
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Center(
              child: TurnGuidanceCard(
                instruction: rideCtrl.turnGuidance,
              ),
            ),
          ),

          // 4. Tarjeta Inferior de Control Contextual
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila de Recogida
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PUNTO DE RECOGIDA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              order?.pickupAddress ?? '062 Kuhn Plains Suite 793',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila de Entrega
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.home,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PUNTO DE ENTREGA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              order?.dropoffAddress ?? '922 Wilfredo Tunnel',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Botón Dinámico Contextual
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (rideCtrl.currentStage == RideStage.inTransit) {
                          // Modal de Prueba de Entrega
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ProofOfDeliveryDialog(
                              onConfirmed: () async {
                                final payout = order?.driverPayout ?? 43.20;
                                await rideCtrl.advanceNextStage();
                                if (mounted) {
                                  // Diálogo Celebratorio de Payout
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      title: Row(
                                        children: const [
                                          Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                                          SizedBox(width: 10),
                                          Text('¡Entrega Completada!'),
                                        ],
                                      ),
                                      content: Text(
                                        '🎉 ¡Excelente trabajo, ${authCtrl.currentDriver?.fullName ?? "Alex"}!\n\nHas ganado +\$${payout.toStringAsFixed(2)} USD por esta entrega. Tu saldo en billetera ha sido actualizado.',
                                        style: const TextStyle(fontSize: 14, height: 1.5),
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                          child: const Text('Volver al Feed'),
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
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getActionLabel(rideCtrl.currentStage),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
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
        return 'LLEGADA AL LOCAL DE RECOGIDA';
      case RideStage.arrivedAtPickup:
        return 'CONFIRMAR RECOGIDA (EN CAMINO)';
      case RideStage.inTransit:
        return 'ENTREGADO';
      case RideStage.delivered:
        return 'COMPLETADO';
    }
  }
}
