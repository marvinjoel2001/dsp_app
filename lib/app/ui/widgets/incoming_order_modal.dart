import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/app_audio_service.dart';
import '../../domain/entities/order_entity.dart';

class IncomingOrderModal extends StatefulWidget {
  final OrderEntity order;
  final Future<void> Function() onAccept;
  final VoidCallback onDecline;

  const IncomingOrderModal({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingOrderModal> createState() => _IncomingOrderModalState();
}

class _IncomingOrderModalState extends State<IncomingOrderModal> {
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    // Iniciar sonido de alerta de despacho
    AppAudioService().playIncomingOrderAlert();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        AppAudioService().stopAlertSound();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppAudioService().stopAlertSound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payout = widget.order.driverPayout > 0 ? widget.order.driverPayout : 43.20;
    final progress = _secondsRemaining / 30.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de arrastre superior
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Temporizador y Alerta de Despacho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '¡NUEVA ORDEN ENTRANTE!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progress > 0.3 ? AppColors.primaryLight : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: progress > 0.3 ? AppColors.primaryDark : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_secondsRemaining}s',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: progress > 0.3 ? AppColors.primaryDark : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de Progreso del Temporizador
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFF1F5F9),
              color: progress > 0.3 ? AppColors.primary : AppColors.error,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 18),

          // Ganancia Prominente y Métricas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GANANCIA ESTIMADA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '+\$${payout.toStringAsFixed(2)} USD',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_outlined, size: 16, color: AppColors.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.order.estimatedDistanceKm ?? 1.5} km',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule, size: 16, color: AppColors.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      widget.order.estimatedTime ?? '12 min',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Ruta Recogida -> Entrega
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Recogida
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront, size: 16, color: AppColors.secondaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RECOGIDA (COMERCIO)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                          Text(
                            widget.order.pickupAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFFE2E8F0), height: 1),
                ),
                // Entrega
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_on, size: 16, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ENTREGA (CLIENTE FINAL)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
                          ),
                          Text(
                            widget.order.dropoffAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Botones de Acción: Aceptar vs Rechazar
          Row(
            children: [
              // Botón Rechazar
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _isAccepting ? null : widget.onDecline,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Rechazar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botón ACEPTAR ORDEN
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isAccepting
                        ? null
                        : () async {
                            setState(() => _isAccepting = true);
                            try {
                              await widget.onAccept();
                            } finally {
                              if (mounted) setState(() => _isAccepting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isAccepting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'ACEPTAR ORDEN',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
