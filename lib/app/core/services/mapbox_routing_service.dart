import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../constants/api_constants.dart';

class RouteStep {
  final String instruction;
  final String modifier;
  final String type;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng location;

  RouteStep({
    required this.instruction,
    required this.modifier,
    required this.type,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>? ?? {};
    final coords = maneuver['location'] as List<dynamic>? ?? [0.0, 0.0];
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    return RouteStep(
      instruction: maneuver['instruction'] as String? ?? 'Continúa por la ruta',
      modifier: maneuver['modifier'] as String? ?? 'straight',
      type: maneuver['type'] as String? ?? 'depart',
      distanceMeters: (json['distance'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration'] as num?)?.toDouble() ?? 0.0,
      location: LatLng(lat, lng),
    );
  }
}

class MapboxRouteResult {
  final List<LatLng> polyline;
  final double distanceKm;
  final int durationMinutes;
  final List<RouteStep> steps;

  MapboxRouteResult({
    required this.polyline,
    required this.distanceKm,
    required this.durationMinutes,
    required this.steps,
  });
}

class MapboxRoutingService {
  static final MapboxRoutingService _instance = MapboxRoutingService._internal();
  factory MapboxRoutingService() => _instance;
  MapboxRoutingService._internal();

  /// Consulta la API de Mapbox Directions v5 para calcular la ruta exacta por calles reales
  Future<MapboxRouteResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final token = ApiConstants.mapboxPublicToken;
      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/'
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?geometries=geojson&steps=true&overview=full&language=es&access_token=$token',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0];
          final geometry = firstRoute['geometry'];
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final polyline = coordinates.map((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final distanceMeters = (firstRoute['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSec = (firstRoute['duration'] as num?)?.toDouble() ?? 0.0;

          final legs = firstRoute['legs'] as List<dynamic>? ?? [];
          final List<RouteStep> steps = [];

          if (legs.isNotEmpty) {
            final rawSteps = legs[0]['steps'] as List<dynamic>? ?? [];
            for (final step in rawSteps) {
              steps.add(RouteStep.fromJson(step as Map<String, dynamic>));
            }
          }

          return MapboxRouteResult(
            polyline: polyline,
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: (durationSec / 60.0).ceil(),
            steps: steps,
          );
        }
      }
    } catch (e) {
      // Fallback local en caso de timeout o red offline
    }

    // Fallback geométrico suave si falla la red
    return _generateFallbackRoute(origin, destination);
  }

  MapboxRouteResult _generateFallbackRoute(LatLng origin, LatLng destination) {
    final List<LatLng> fallbackPoints = [];
    const stepsCount = 12;
    for (int i = 0; i <= stepsCount; i++) {
      final t = i / stepsCount;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      fallbackPoints.add(LatLng(lat, lng));
    }

    final distanceKm = const Distance().as(LengthUnit.Kilometer, origin, destination);
    final durationMin = (distanceKm * 3.0).ceil() + 2;

    return MapboxRouteResult(
      polyline: fallbackPoints,
      distanceKm: distanceKm,
      durationMinutes: durationMin,
      steps: [
        RouteStep(
          instruction: 'Sigue la ruta hacia el destino',
          modifier: 'straight',
          type: 'depart',
          distanceMeters: distanceKm * 1000,
          durationSeconds: durationMin * 60.0,
          location: origin,
        ),
      ],
    );
  }
}
