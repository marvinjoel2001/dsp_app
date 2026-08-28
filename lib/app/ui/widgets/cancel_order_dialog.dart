import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CancelOrderDialog extends StatefulWidget {
  final String orderId;
  final Function(String reason) onConfirmCancel;

  const CancelOrderDialog({
    super.key,
    required this.orderId,
    required this.onConfirmCancel,
  });

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  String _selectedReason = 'MERCHANT_CLOSED';
  bool _showFinalWarning = false;

  final List<Map<String, String>> _cancelReasons = [
    {
      'id': 'MERCHANT_CLOSED',
      'label': 'Local de comida / Comercio cerrado',
      'desc': 'El restaurante o tienda no está atendiendo.',
    },
    {
      'id': 'VEHICLE_BREAKDOWN',
      'label': 'Avería mecánica o llanta pinchada',
      'desc': 'No puedo continuar con el vehículo actual.',
    },
    {
      'id': 'CLIENT_UNREACHABLE',
      'label': 'Cliente no responde llamadas ni mensajes',
      'desc': 'Más de 10 minutos esperando en el punto de entrega.',
    },
    {
      'id': 'WRONG_ADDRESS',
      'label': 'Dirección errónea o inaccesible',
      'desc': 'La zona no es accesible por ruta vehicular.',
    },
    {
      'id': 'EXCESSIVE_DELAY',
      'label': 'Demora excesiva en preparación del pedido',
      'desc': 'El pedido no estará listo a tiempo.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelar Orden',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Selecciona el motivo de cancelación',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showFinalWarning) ...[
              ..._cancelReasons.map((reason) {
                final isSelected = _selectedReason == reason['id'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedReason = reason['id']!);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.errorLight : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.error : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.error : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reason['label']!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? AppColors.error : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  reason['desc']!,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 36),
                    SizedBox(height: 10),
                    Text(
                      '¿Confirmas la cancelación de la orden?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'La orden será reasignada a otro conductor disponible en la central de despacho. Las cancelaciones reiteradas sin causa justificada pueden afectar tu tasa de aceptación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_showFinalWarning) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver a la Orden', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _showFinalWarning = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continuar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              setState(() => _showFinalWarning = false);
            },
            child: const Text('Atrás', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onConfirmCancel(_selectedReason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirmar Cancelación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ],
    );
  }
}
