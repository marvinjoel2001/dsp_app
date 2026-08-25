import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProofOfDeliveryDialog extends StatefulWidget {
  final VoidCallback onConfirmed;

  const ProofOfDeliveryDialog({super.key, required this.onConfirmed});

  @override
  State<ProofOfDeliveryDialog> createState() => _ProofOfDeliveryDialogState();
}

class _ProofOfDeliveryDialogState extends State<ProofOfDeliveryDialog> {
  bool _photoTaken = false;
  bool _signatureCaptured = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Confirmar Prueba de Entrega',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toma una fotografía del paquete entregado o registra la firma digital del cliente para finalizar el pago.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Caja de Foto
          InkWell(
            onTap: () {
              setState(() => _photoTaken = !_photoTaken);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _photoTaken ? AppColors.primaryLight : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _photoTaken ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _photoTaken ? Icons.check_circle : Icons.camera_alt_outlined,
                    color: _photoTaken ? AppColors.primaryDark : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _photoTaken ? 'Foto Adjuntada (ENTREGA_9941.jpg)' : 'Tomar Foto del Paquete Entregado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _photoTaken ? AppColors.primaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Caja de Firma
          InkWell(
            onTap: () {
              setState(() => _signatureCaptured = !_signatureCaptured);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _signatureCaptured ? AppColors.primaryLight : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _signatureCaptured ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _signatureCaptured ? Icons.check_circle : Icons.draw_outlined,
                    color: _signatureCaptured ? AppColors.primaryDark : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _signatureCaptured ? 'Firma del Cliente Registrada' : 'Registrar Firma Digital del Cliente',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _signatureCaptured ? AppColors.primaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón Confirmar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onConfirmed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'CONFIRMAR Y COMPLETAR ORDEN',
                style: TextStyle(
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
    );
  }
}
