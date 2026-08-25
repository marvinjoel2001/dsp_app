import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/order_entity.dart';

class OrderFeedCard extends StatefulWidget {
  final OrderEntity order;
  final Future<void> Function() onPickOrder;

  const OrderFeedCard({
    super.key,
    required this.order,
    required this.onPickOrder,
  });

  @override
  State<OrderFeedCard> createState() => _OrderFeedCardState();
}

class _OrderFeedCardState extends State<OrderFeedCard> {
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final payout = widget.order.driverPayout > 0 ? widget.order.driverPayout : 43.20;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Superior: ID de Orden y Ganancia Destacada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${widget.order.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Text(
                '+\$${payout.toStringAsFixed(2)} USD',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ruta: Comercio -> Cliente
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna de Iconos
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.storefront, size: 12, color: AppColors.secondaryDark),
                  ),
                  Container(
                    width: 2,
                    height: 22,
                    color: const Color(0xFFCBD5E1),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.location_on, size: 12, color: AppColors.primaryDark),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Textos de Direcciones
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.pickupAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.order.dropoffAddress,
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
          const SizedBox(height: 14),

          // Métricas de Tiempo y Distancia
          Row(
            children: [
              const Icon(Icons.navigation_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                '${widget.order.estimatedDistanceKm ?? 1.5} km',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.schedule, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                widget.order.estimatedTime ?? '12 min',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón Aceptar Orden
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isPicking
                  ? null
                  : () async {
                      setState(() => _isPicking = true);
                      try {
                        await widget.onPickOrder();
                      } finally {
                        if (mounted) setState(() => _isPicking = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isPicking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'VER Y ACEPTAR ORDEN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
