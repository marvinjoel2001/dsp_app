import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/services/app_audio_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../controllers/active_ride_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/turn_guidance_card.dart';
import '../../widgets/waze_speedometer.dart';
import '../../widgets/waze_3d_puck.dart';
import '../../widgets/proof_of_delivery_dialog.dart';
import '../../widgets/cancel_order_dialog.dart';

class LiveMapNavigationScreen extends StatefulWidget {
  const LiveMapNavigationScreen({super.key});

  @override
  State<LiveMapNavigationScreen> createState() => _LiveMapNavigationScreenState();
}

class _LiveMapNavigationScreenState extends State<LiveMapNavigationScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  final AppAudioService _audioService = AppAudioService();
  bool _autoFollowDriver = true;
  bool _isVoiceEnabled = true;
  bool _isActionPanelExpanded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isVoiceEnabled = _audioService.isVoiceGuidanceEnabled;
  }

  /// Calcula el punto focal de la cámara hacia adelante según el rumbo (Heading),
  /// colocando al vehículo en el 30% inferior de la pantalla para máxima visibilidad de ruta.
  LatLng _calculateChaseCameraCenter(LatLng driverPos, double headingDeg, bool is3D) {
    if (!is3D) return driverPos;
    // Desplazar la cámara ~180 metros adelante a lo largo del vector de avance
    const double distanceMeters = 180.0;
    const double earthRadius = 6378137.0;
    final rad = headingDeg * (pi / 180.0);
    final dLat = (distanceMeters * cos(rad)) / earthRadius;
    final dLng = (distanceMeters * sin(rad)) / (earthRadius * cos(driverPos.latitude * (pi / 180.0)));
    return LatLng(
      driverPos.latitude + (dLat * (180.0 / pi)),
      driverPos.longitude + (dLng * (180.0 / pi)),
    );
  }

  void _recenterOnDriver(LatLng driverLocation, double heading, bool is3D) {
    setState(() => _autoFollowDriver = true);
    final target = _calculateChaseCameraCenter(driverLocation, heading, is3D);
    _animatedMapMove(target, is3D ? 17.2 : 15.5, is3D ? -heading : 0.0);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎯 Centrado en perspectiva Waze • Siguiendo avance'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  void _fitRouteBounds(ActiveRideController rideCtrl, LatLng driverPos, LatLng targetPoint) {
    setState(() => _autoFollowDriver = false);
    final points = <LatLng>[
      driverPos,
      targetPoint,
      ...rideCtrl.routePolyline,
    ];
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.rotate(0.0);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 200, bottom: 280, left: 50, right: 50),
      ),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗺️ Vista general 2D de la ruta completa'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
  }

  void _animatedMapMove(LatLng destLocation, double destZoom, double destRotation) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _mapController.rotate(destRotation);

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _showHelpMenu(BuildContext context) {
    final rideCtrl = context.read<ActiveRideController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CancelOrderDialog(
        orderId: rideCtrl.activeOrder?.id ?? '',
        onConfirmCancel: (reason) async {
          await rideCtrl.cancelActiveOrder(reason);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Orden cancelada: $reason'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideCtrl = context.watch<ActiveRideController>();
    final authCtrl = context.watch<AuthController>();
    final order = rideCtrl.activeOrder;

    final driverPos = rideCtrl.driverLocation;
    final driverHeading = rideCtrl.driverHeading;
    final is3D = rideCtrl.is3DView;
    final isDelivering = rideCtrl.currentStage == RideStage.inTransit || rideCtrl.currentStage == RideStage.delivered;

    final pickupPoint = LatLng(order?.pickupLat ?? -17.7833, order?.pickupLng ?? -63.1821);
    final dropoffPoint = LatLng(order?.dropoffLat ?? -17.7950, order?.dropoffLng ?? -63.1700);

    final currentStep = (rideCtrl.routeSteps.isNotEmpty && rideCtrl.currentStepIndex < rideCtrl.routeSteps.length)
        ? rideCtrl.routeSteps[rideCtrl.currentStepIndex]
        : null;

    // Auto-seguimiento suave: centrar la cámara por delante del conductor y rotar hacia el rumbo
    if (_autoFollowDriver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final target = _calculateChaseCameraCenter(driverPos, driverHeading, is3D);
          _mapController.move(target, is3D ? 17.2 : 15.5);
          if (is3D) {
            _mapController.rotate(-driverHeading);
          } else {
            _mapController.rotate(0.0);
          }
        }
      });
    }

    // Hora estimada de llegada (ETA)
    final now = DateTime.now();
    final etaTime = now.add(Duration(minutes: rideCtrl.routeDurationMin));
    final etaString =
        '${etaTime.hour.toString().padLeft(2, '0')}:${etaTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. Motor de Mapas con Transformación de Perspectiva 3D Waze
          Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Profundidad de fuga de perspectiva 3D
              ..rotateX(is3D ? 0.72 : 0.0), // Inclinación hacia adelante de ~41°
            alignment: const FractionalOffset(0.5, 0.70), // Pivote centrado en la moto/auto del conductor
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _calculateChaseCameraCenter(driverPos, driverHeading, is3D),
                initialZoom: is3D ? 17.2 : 15.5,
                initialRotation: is3D ? -driverHeading : 0.0,
                onPositionChanged: (pos, hasGesture) {
                  if (hasGesture && _autoFollowDriver) {
                    setState(() => _autoFollowDriver = false);
                  }
                },
              ),
              children: [
                // Capa de Mosaicos Vectoriales Mapbox Light / Carto Voyager
                TileLayer(
                  urlTemplate: ApiConstants.mapboxLightStyleUrl.contains('access_token=') &&
                          !ApiConstants.mapboxLightStyleUrl.contains('access_token=pk.your_')
                      ? ApiConstants.mapboxLightStyleUrl
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.chiringuito.driver',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),

                // Capa de Polilínea de Ruta estilo Waze (Púrpura / Azul Eléctrico con Borde)
                if (rideCtrl.routePolyline.isNotEmpty) ...[
                  PolylineLayer(
                    polylines: [
                      // Capa Sombra / Borde Oscuro Waze
                      Polyline(
                        points: rideCtrl.routePolyline,
                        strokeWidth: 10.0,
                        color: const Color(0xFF312E81).withValues(alpha: 0.35),
                      ),
                      // Borde Blanco de Alto Contraste
                      Polyline(
                        points: rideCtrl.routePolyline,
                        strokeWidth: 7.5,
                        color: Colors.white,
                      ),
                      // Capa Central Púrpura Eléctrico Waze
                      Polyline(
                        points: rideCtrl.routePolyline,
                        strokeWidth: 5.5,
                        color: isDelivering ? const Color(0xFF6366F1) : const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                ],

                // Capa de Radios Circulares de Geocerca
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: isDelivering ? dropoffPoint : pickupPoint,
                      radius: 150,
                      useRadiusInMeter: true,
                      color: (isDelivering ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.15),
                      borderColor: isDelivering ? AppColors.primary : AppColors.secondary,
                      borderStrokeWidth: 2.5,
                    ),
                  ],
                ),

                // Marcadores SVG y Puntero Waze 3D
                MarkerLayer(
                  markers: [
                    // Marcador de Comercio
                    Marker(
                      point: pickupPoint,
                      width: 48,
                      height: 58,
                      child: AppSvgIcons.storePickupMarker(size: 48),
                    ),

                    // Marcador de Destino
                    Marker(
                      point: dropoffPoint,
                      width: 48,
                      height: 58,
                      child: AppSvgIcons.customerDropoffMarker(size: 48),
                    ),

                    // Píldoras de Nombre de Calle en la Ruta (Estilo Waze)
                    if (rideCtrl.routeSteps.isNotEmpty)
                      for (int i = 0; i < min(3, rideCtrl.routeSteps.length); i++)
                        Marker(
                          point: rideCtrl.routeSteps[i].location,
                          width: 120,
                          height: 30,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1), // Waze Purple Pill
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                rideCtrl.routeSteps[i].instruction.split(' en ').last.split(',').first,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                    // Marcador del Repartidor (Puck 3D Waze o Vehículo Top-Down)
                    Marker(
                      point: driverPos,
                      width: 64,
                      height: 64,
                      child: is3D
                          ? Waze3DPuck(
                              heading: driverHeading,
                              is3D: is3D,
                              vehicleType: authCtrl.currentDriver?.vehicleType ?? 'MOTORCYCLE',
                            )
                          : Transform.rotate(
                              angle: driverHeading * (pi / 180.0),
                              child: AppSvgIcons.vehicleNavMarker(
                                vehicleType: authCtrl.currentDriver?.vehicleType ?? 'MOTORCYCLE',
                                width: 50,
                                height: 50,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Encabezado de Navegación Flotante con HUD Waze (Maneuver Card)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila Superior de Controles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Minimizar / Volver al Inicio
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172A)),
                        ),
                      ),

                      // Botones Superiores (Voz, 3D Waze, Ayuda)
                      Row(
                        children: [
                          // Botón Toggle Voz TTS
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isVoiceEnabled = !_isVoiceEnabled;
                                _audioService.isVoiceGuidanceEnabled = _isVoiceEnabled;
                              });
                              if (_isVoiceEnabled) {
                                _audioService.speakInstruction(rideCtrl.turnGuidance);
                              } else {
                                _audioService.stopSpeech();
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _isVoiceEnabled ? const Color(0xFFECFDF5) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _isVoiceEnabled ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12),
                                ],
                              ),
                              child: Icon(
                                _isVoiceEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                                size: 18,
                                color: _isVoiceEnabled ? const Color(0xFF047857) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón 2D / 3D Waze
                          InkWell(
                            onTap: () {
                              rideCtrl.toggle3D();
                              _recenterOnDriver(driverPos, driverHeading, rideCtrl.is3DView);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: is3D ? const Color(0xFF0284C7) : Colors.white, // Sky Blue Waze
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: is3D ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: is3D ? const Color(0xFF0284C7).withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    is3D ? Icons.view_in_ar_rounded : Icons.map_outlined,
                                    size: 16,
                                    color: is3D ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    is3D ? '3D WAZE' : '2D PLANO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: is3D ? Colors.white : const Color(0xFF0F172A),
                                      letterSpacing: 0.5,
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
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.help_outline, size: 16, color: Color(0xFF0F172A)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ayuda',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 3. HUD Superior Waze: TurnGuidanceCard
                  InkWell(
                    onTap: () {
                      _recenterOnDriver(driverPos, driverHeading, is3D);
                      _audioService.speakInstruction(rideCtrl.turnGuidance);
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: TurnGuidanceCard(
                      instruction: rideCtrl.turnGuidance,
                      modifier: currentStep?.modifier,
                      distanceMeters: currentStep?.distanceMeters ?? (rideCtrl.routeDistanceKm * 1000),
                      durationMinutes: rideCtrl.routeDurationMin,
                      speedKmh: rideCtrl.driverSpeedKmh,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Velocímetro Circular Waze Flotante en Esquina Inferior Izquierda
          Positioned(
            left: 20,
            bottom: _isActionPanelExpanded ? 340 : 130,
            child: WazeSpeedometer(speedKmh: rideCtrl.driverSpeedKmh),
          ),

          // 4. Botones Flotantes de Navegación (Centrar y Vista Completa)
          Positioned(
            right: 16,
            bottom: _isActionPanelExpanded ? 340 : 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Recentrar Modo Waze Chase
                InkWell(
                  onTap: () => _recenterOnDriver(driverPos, driverHeading, is3D),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _autoFollowDriver ? const Color(0xFF0284C7) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _autoFollowDriver
                              ? const Color(0xFF0284C7).withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.navigation_rounded,
                      size: 22,
                      color: _autoFollowDriver ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón Ruta Completa
                InkWell(
                  onTap: () => _fitRouteBounds(rideCtrl, driverPos, isDelivering ? dropoffPoint : pickupPoint),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.alt_route_rounded, size: 22, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
          ),

          // 5. Barra Inferior Estilo Waze (ETA, Tiempo, Kilómetros y Acciones)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila Principal Estilo Waze
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Buscar / Vista de Ruta
                      InkWell(
                        onTap: () => _fitRouteBounds(rideCtrl, driverPos, isDelivering ? dropoffPoint : pickupPoint),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.search, size: 22, color: Color(0xFF475569)),
                        ),
                      ),

                      // Bloque Central: ETA y Tiempo/Distancia
                      InkWell(
                        onTap: () {
                          setState(() => _isActionPanelExpanded = !_isActionPanelExpanded);
                        },
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  etaString,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                                  size: 18,
                                  color: const Color(0xFF64748B),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${rideCtrl.routeDurationMin} min',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                                const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                                Text(
                                  '${rideCtrl.routeDistanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Botón Flecha Desplegable para Ver Detalles de Entrega
                      InkWell(
                        onTap: () {
                          setState(() => _isActionPanelExpanded = !_isActionPanelExpanded);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7), // Sky Blue Waze Button
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isActionPanelExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Panel Extendido de Entrega / Contacto
                  if (_isActionPanelExpanded) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Dirección de la parada actual
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDelivering ? AppColors.primaryLight : AppColors.secondaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDelivering ? Icons.location_on : Icons.storefront,
                            size: 18,
                            color: isDelivering ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isDelivering ? 'ENTREGA AL CLIENTE' : 'RECOGIDA EN COMERCIO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isDelivering ? AppColors.primaryDark : AppColors.secondaryDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDelivering
                                    ? (order?.dropoffAddress ?? 'Av. Las Palmas #420')
                                    : (order?.pickupAddress ?? 'Restaurante Central'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fila de Acciones de Contacto Rápido
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final phone = isDelivering ? rideCtrl.customerPhone : rideCtrl.merchantPhone;
                              final url = Uri.parse('tel:${phone.replaceAll(' ', '')}');
                              try {
                                if (await canLaunchUrl(url)) await launchUrl(url);
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.phone, size: 16, color: Color(0xFF0F172A)),
                            label: const Text('Llamar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final phone = isDelivering ? rideCtrl.customerPhone : rideCtrl.merchantPhone;
                              final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
                              final text = Uri.encodeComponent('Hola, soy tu repartidor de Chiringuito con la orden #${order?.id ?? ""}');
                              final waUrl = Uri.parse('https://wa.me/$cleanPhone?text=$text');
                              try {
                                if (await canLaunchUrl(waUrl)) await launchUrl(waUrl, mode: LaunchMode.externalApplication);
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF059669)),
                            label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botón de Acción Principal (Confirmar Llegada / Entrega)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (rideCtrl.currentStage == RideStage.delivered || rideCtrl.activeOrder == null) {
                            rideCtrl.completeAndClearRide();
                            Navigator.of(context).pop();
                            return;
                          }

                          if (!rideCtrl.isWithinGeofence) {
                            _showOutOfRangeDialog(context, rideCtrl, rideCtrl.distanceToCurrentTargetMeters, isDelivering);
                            return;
                          }

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
                                      barrierDismissible: false,
                                      builder: (dialogCtx) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        title: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
                                            SizedBox(width: 10),
                                            Expanded(child: Text('¡Entrega Completada!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                          ],
                                        ),
                                        content: Text(
                                          '🎉 ¡Excelente trabajo, ${authCtrl.currentDriver?.fullName ?? "Alex"}!\n\nHas ganado +Bs. ${payout.toStringAsFixed(2)} por esta entrega.',
                                          style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              rideCtrl.completeAndClearRide();
                                              Navigator.of(dialogCtx).pop();
                                              if (context.mounted) Navigator.of(context).pop();
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
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
                          backgroundColor: rideCtrl.isWithinGeofence
                              ? (isDelivering ? const Color(0xFF059669) : const Color(0xFFD97706))
                              : const Color(0xFF94A3B8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getActionIcon(rideCtrl.currentStage), size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _getActionLabel(rideCtrl.currentStage),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOutOfRangeDialog(
    BuildContext context,
    ActiveRideController rideCtrl,
    double distanceMeters,
    bool isDelivering,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fuera del Radio de Ubicación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          'Te encuentras a ${distanceMeters >= 1000 ? "${(distanceMeters / 1000).toStringAsFixed(1)} km" : "${distanceMeters.round()} metros"} del punto.\n\nDebes estar a menos de 150 metros del destino para confirmar este paso.',
          style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
        ),
        actions: [
          if (kDebugMode)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                rideCtrl.snapDriverToDestination();
              },
              child: const Text('Simular Llegada (QA)', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuar Conduciendo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(RideStage stage) {
    switch (stage) {
      case RideStage.assigned:
        return Icons.storefront_outlined;
      case RideStage.arrivedAtPickup:
        return Icons.inventory_2_outlined;
      case RideStage.inTransit:
        return Icons.verified_outlined;
      case RideStage.delivered:
        return Icons.check_circle_outline;
    }
  }

  String _getActionLabel(RideStage stage) {
    switch (stage) {
      case RideStage.assigned:
        return '1. CONFIRMAR LLEGADA AL COMERCIO';
      case RideStage.arrivedAtPickup:
        return '2. CONFIRMAR RECOGIDA (INICIAR RUTA)';
      case RideStage.inTransit:
        return '3. CONFIRMAR LLEGADA Y ENTREGA';
      case RideStage.delivered:
        return 'ORDEN COMPLETADA';
    }
  }
}
