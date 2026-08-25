import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ConnectivityStatusBanner extends StatelessWidget {
  final bool isOnline;
  final bool isGpsActive;

  const ConnectivityStatusBanner({
    super.key,
    this.isOnline = true,
    this.isGpsActive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && isGpsActive) return const SizedBox.shrink();

    final isOffline = !isOnline;
    final bgColor = isOffline ? const Color(0xFF334155) : AppColors.warning;
    final icon = isOffline ? Icons.wifi_off_rounded : Icons.location_off_rounded;
    final text = isOffline
        ? 'Estás desconectado. Conéctate para recibir nuevos pedidos.'
        : 'Señal GPS baja o buscando ubicación del conductor...';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
