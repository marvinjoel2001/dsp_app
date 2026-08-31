import 'package:flutter/material.dart';

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
    if (mod == null) return Icons.straight_rounded;
    final m = mod.toLowerCase();
    if (m.contains('sharp_right')) return Icons.turn_sharp_right_rounded;
    if (m.contains('slight_right') || m.contains('right')) return Icons.turn_right_rounded;
    if (m.contains('sharp_left')) return Icons.turn_sharp_left_rounded;
    if (m.contains('slight_left') || m.contains('left')) return Icons.turn_left_rounded;
    if (m.contains('uturn')) return Icons.u_turn_left_rounded;
    if (m.contains('roundabout')) return Icons.roundabout_right_rounded;
    return Icons.straight_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = (distanceMeters != null && distanceMeters! > 0)
        ? (distanceMeters! >= 1000
            ? '${(distanceMeters! / 1000).toStringAsFixed(1)} km'
            : '${distanceMeters!.round()} m')
        : 'Ruta activa';

    // Extraer nombre de calle de la instrucción (si dice "Gira a la derecha en Calle San Martin")
    String streetName = instruction;
    if (instruction.toLowerCase().contains(' en ')) {
      streetName = instruction.split(RegExp(r'\sen\s', caseSensitive: false)).last;
    } else if (instruction.toLowerCase().contains(' hacia ')) {
      streetName = instruction.split(RegExp(r'\shacia\s', caseSensitive: false)).last;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Waze Slate Dark 900
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Icono Gigante de Giro Waze
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF475569), width: 1),
            ),
            child: Icon(
              _getManeuverIcon(modifier),
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),

          // 2. Distancia y Nombre de la Calle en Cian Eléctrico
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  distanceText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  streetName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF38BDF8), // Waze Vibrant Cyan
                    letterSpacing: 0.2,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Indicador de Maniobra Siguiente o Voz
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assistant_navigation,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
