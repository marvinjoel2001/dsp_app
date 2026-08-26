import 'dart:math';
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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _isVoiceEnabled = _audioService.isVoiceGuidanceEnabled;
  }

  void _recenterOnDriver(LatLng driverLocation, double zoom) {
    setState(() => _autoFollowDriver = true);
    _animatedMapMove(driverLocation, zoom);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

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
    final isDelivering = rideCtrl.currentStage == RideStage.inTransit || rideCtrl.currentStage == RideStage.delivered;

    final pickupPoint = LatLng(order?.pickupLat ?? -17.7833, order?.pickupLng ?? -63.1821);
    final dropoffPoint = LatLng(order?.dropoffLat ?? -17.7950, order?.dropoffLng ?? -63.1700);

    final currentStep = (rideCtrl.routeSteps.isNotEmpty && rideCtrl.currentStepIndex < rideCtrl.routeSteps.length)
        ? rideCtrl.routeSteps[rideCtrl.currentStepIndex]
        : null;

    // Auto-seguimiento suave del conductor cuando avanza
    if (_autoFollowDriver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(driverPos, rideCtrl.is3DView ? 16.8 : 15.5);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Motor de Mapas con Mapbox Vector Tiles Claros de Alta Precisión
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: driverPos,
              initialZoom: rideCtrl.is3DView ? 16.8 : 15.5,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _autoFollowDriver) {
                  setState(() => _autoFollowDriver = false);
                }
              },
            ),
            children: [
              // Capa de Mosaicos Vectoriales Mapbox Light (Blanco/Gris AAA de Alto Rendimiento)
              TileLayer(
                urlTemplate: ApiConstants.mapboxLightStyleUrl.contains('access_token=') &&
                        !ApiConstants.mapboxLightStyleUrl.contains('access_token=pk.your_')
                    ? ApiConstants.mapboxLightStyleUrl
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.chiringuito.driver',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),

              // Capa de Polilíneas de Ruta Dinámica (Se va consumiendo por detrás)
              if (rideCtrl.routePolyline.isNotEmpty) ...[
                PolylineLayer(
                  polylines: [
                    // Capa Sombra / Borde Oscuro
                    Polyline(
                      points: rideCtrl.routePolyline,
                      strokeWidth: 9.0,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                    ),
                    // Capa Central Brillante con Color de Estado
                    Polyline(
                      points: rideCtrl.routePolyline,
                      strokeWidth: 5.5,
                      color: isDelivering ? AppColors.primary : AppColors.secondary,
                    ),
                  ],
                ),
              ],

              // Capa de Radios Circulares (Aura del Conductor y Geocerca Perimetral de Destino)
              CircleLayer(
                circles: [
                  // 1. Radio Verde Translúcido de Ubicación del Repartidor (Efecto Radar GPS)
                  CircleMarker(
                    point: driverPos,
                    radius: 80,
                    useRadiusInMeter: true,
                    color: const Color(0xFF10B981).withValues(alpha: 0.24),
                    borderColor: const Color(0xFF10B981).withValues(alpha: 0.55),
                    borderStrokeWidth: 1.8,
                  ),
                  CircleMarker(
                    point: driverPos,
                    radius: 38,
                    useRadiusInMeter: true,
                    color: const Color(0xFF34D399).withValues(alpha: 0.16),
                    borderColor: Colors.transparent,
                  ),

                  // 2. Capa de Geocerca Perimetral (Radio de 150m alrededor del destino)
                  CircleMarker(
                    point: isDelivering ? dropoffPoint : pickupPoint,
                    radius: 150,
                    useRadiusInMeter: true,
                    color: (isDelivering ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.14),
                    borderColor: isDelivering ? AppColors.primary : AppColors.secondary,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),

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

                  // Marcador del Repartidor en Vivo (Moto/Vehículo con Rumbo)
                  Marker(
                    point: driverPos,
                    width: 50,
                    height: 50,
                    child: Transform.rotate(
                      angle: rideCtrl.driverHeading * (pi / 180.0),
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

          // 2. Encabezado de Navegación Flotante con TurnGuidanceCard Integrado (Cero Solapamientos)
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
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172A)),
                        ),
                      ),

                      // Botones Superiores (Voz, 3D, Ayuda)
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isVoiceEnabled ? '🔊 Instrucciones por voz activadas' : '🔇 Voz silenciada'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppColors.primaryDark,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: _isVoiceEnabled ? AppColors.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _isVoiceEnabled ? AppColors.primary : const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                                ],
                              ),
                              child: Icon(
                                _isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                                size: 18,
                                color: _isVoiceEnabled ? AppColors.primaryDark : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón 2D / 3D
                          InkWell(
                            onTap: () {
                              rideCtrl.toggle3D();
                              _mapController.move(driverPos, rideCtrl.is3DView ? 16.8 : 15.5);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: rideCtrl.is3DView ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Botón Ayuda / Cancelación
                          InkWell(
                            onTap: () => _showHelpMenu(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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

                  const SizedBox(height: 10),

                  // 3. HUD Superior Turn-By-Turn Card
                  TurnGuidanceCard(
                    instruction: rideCtrl.turnGuidance,
                    modifier: currentStep?.modifier,
                    distanceMeters: currentStep?.distanceMeters ?? (rideCtrl.routeDistanceKm * 1000),
                    durationMinutes: rideCtrl.routeDurationMin,
                    speedKmh: rideCtrl.driverSpeedKmh,
                  ),
                ],
              ),
            ),
          ),

          // 3. Botones Flotantes Laterales del Mapa (Recentrar GPS y Recalcular Ruta)
          Positioned(
            right: 16,
            bottom: 270,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Recalcular Ruta
                InkWell(
                  onTap: () async {
                    await rideCtrl.recalculateRoute();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Recalculando ruta en tiempo real por calles...'),
                          duration: Duration(seconds: 1),
                          backgroundColor: AppColors.primaryDark,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.sync, size: 20, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 10),

                // Botón Recentrar GPS
                InkWell(
                  onTap: () => _recenterOnDriver(driverPos, rideCtrl.is3DView ? 16.8 : 15.5),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _autoFollowDriver ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _autoFollowDriver ? AppColors.primary : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      size: 20,
                      color: _autoFollowDriver ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
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
                  // Insignia de Validación de Proximidad / Geocerca
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: rideCtrl.isWithinGeofence
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: rideCtrl.isWithinGeofence
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          rideCtrl.isWithinGeofence ? Icons.check_circle : Icons.location_searching,
                          size: 16,
                          color: rideCtrl.isWithinGeofence ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rideCtrl.isWithinGeofence
                                ? 'Ubicación Validada (${rideCtrl.distanceToCurrentTargetMeters.round()} m) • Dentro del radio ✅'
                                : 'A ${rideCtrl.distanceToCurrentTargetMeters >= 1000 ? (rideCtrl.distanceToCurrentTargetMeters / 1000).toStringAsFixed(1) + " km" : rideCtrl.distanceToCurrentTargetMeters.round().toString() + " m"} del destino (Radio: < 150m)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: rideCtrl.isWithinGeofence ? const Color(0xFF065F46) : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón de Acción Principal (CTA Masivo para Uso con una Sola Mano)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validación Estricta de Proximidad Geoespacial
                        if (!rideCtrl.isWithinGeofence) {
                          _showOutOfRangeDialog(
                            context,
                            rideCtrl,
                            rideCtrl.distanceToCurrentTargetMeters,
                            isDelivering,
                          );
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
                                    builder: (_) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '¡Entrega Completada!',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Text(
                                        '🎉 ¡Excelente trabajo, ${authCtrl.currentDriver?.fullName ?? "Alex"}!\n\nHas ganado +Bs. ${payout.toStringAsFixed(2)} por esta entrega. El comprobante POD fue respaldado en Cloudinary y tu saldo ha sido acreditado en Chiringuito.',
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
                        backgroundColor: rideCtrl.isWithinGeofence
                            ? (isDelivering ? AppColors.primary : AppColors.secondary)
                            : const Color(0xFF94A3B8),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Te encuentras a ${distanceMeters >= 1000 ? (distanceMeters / 1000).toStringAsFixed(1) + " km" : distanceMeters.round().toString() + " metros"} de ${isDelivering ? "la dirección de entrega del cliente" : "el comercio de recogida"}.\n\nPor políticas de seguridad y validación de entrega, debes estar a menos de 150 metros del punto para confirmar este paso.',
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sigue la ruta en el mapa hasta acercarte al perímetro.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              rideCtrl.snapDriverToDestination();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚡ Posición simulada en el destino (Modo Pruebas)'),
                  backgroundColor: AppColors.primaryDark,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Simular Llegada (Test)', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continuar Conduciendo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
