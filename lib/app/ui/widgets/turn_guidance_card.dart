import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TurnGuidanceCard extends StatelessWidget {
  final String instruction;
  final String? modifier;
  final double? distanceMeters;
  final int? durationMinutes;
  final double? speedKmh;

  const TurnGuidanceCard({
    super.key,
    required this.instruction,
    this.modifier,
    this.distanceMeters,
    this.durationMinutes,
    this.speedKmh,
  });

  IconData _getManeuverIcon(String? mod) {
    if (mod == null) return Icons.navigation;
    final m = mod.toLowerCase();
    if (m.contains('right')) return Icons.turn_right;
    if (m.contains('left')) return Icons.turn_left;
    if (m.contains('uturn')) return Icons.u_turn_left;
    if (m.contains('straight')) return Icons.straight;
    return Icons.navigation;
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = (distanceMeters != null && distanceMeters! > 0)
        ? (distanceMeters! >= 1000
            ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km'
            : '${distanceMeters!.round()} m')
        : 'Ruta activa';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Slate 900 de ultra contraste para modo navegación
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icono de Maniobra
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getManeuverIcon(modifier),
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),

              // Texto del Giro e Indicación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distanceText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF34D399), // Verde esmeralda brillante
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      instruction,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (durationMinutes != null || speedKmh != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        '${speedKmh?.toStringAsFixed(0) ?? "35"} km/h',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE2E8F0)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        'ETA ${durationMinutes ?? 12} min',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFDE047)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
