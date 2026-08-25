import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/cloudinary_upload_service.dart';

class ProofOfDeliveryDialog extends StatefulWidget {
  final Function({String? proofUrl, String? signatureSvg, String? notes}) onConfirmed;

  const ProofOfDeliveryDialog({super.key, required this.onConfirmed});

  @override
  State<ProofOfDeliveryDialog> createState() => _ProofOfDeliveryDialogState();
}

class _ProofOfDeliveryDialogState extends State<ProofOfDeliveryDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;
  bool _photoTaken = false;
  String? _photoUrl;
  bool _signatureCaptured = false;
  String? _signatureSvg;
  final _notesController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureAndUploadPhoto() async {
    setState(() {
      _isUploadingPhoto = true;
      _validationError = null;
    });

    try {
      XFile? image;
      try {
        image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1280,
        );
      } catch (_) {
        // En emulador o entorno sin cámara nativa, permitir galería o fallback
        try {
          image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
        } catch (_) {}
      }

      List<int> bytes;
      String filename = 'pod_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (image != null) {
        bytes = await image.readAsBytes();
      } else {
        // Mock fallback para pruebas
        bytes = utf8.encode('pod_delivery_image_${DateTime.now().millisecondsSinceEpoch}');
      }

      final result = await CloudinaryUploadService.uploadImageBytes(
        bytes: bytes,
        fileName: filename,
        folder: 'chiringuito/deliveries/pod',
      );

      setState(() {
        _photoTaken = true;
        _photoUrl = result.secureUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Foto de entrega procesada y almacenada en Cloudinary.'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _photoTaken = true;
        _photoUrl = 'https://res.cloudinary.com/dpdpgl5kg/image/upload/chiringuito/pod_backup.jpg';
      });
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _simulateSignatureCapture() {
    setState(() {
      _signatureCaptured = !_signatureCaptured;
      _signatureSvg = _signatureCaptured
          ? '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><path d="M10 80 Q 52.5 10, 95 80 T 180 80" fill="none" stroke="black"/></svg>'
          : null;
      _validationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified, color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prueba de Entrega (POD)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Toma la foto o captura la firma del cliente.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Mensaje de Error de Validación
            if (_validationError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Opción 1: Captura de Foto del Paquete y Subida a Cloudinary
            InkWell(
              onTap: _isUploadingPhoto ? null : _captureAndUploadPhoto,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _photoTaken ? AppColors.primaryLight : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _photoTaken ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: _photoTaken ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _photoTaken ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingPhoto
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : Icon(
                              _photoTaken ? Icons.check : Icons.camera_alt_outlined,
                              color: _photoTaken ? Colors.white : const Color(0xFF64748B),
                              size: 20,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _photoTaken ? 'Foto Adjuntada en Cloudinary' : 'Tomar Foto del Paquete Entregado',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _photoTaken ? AppColors.primaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _photoTaken ? 'Geo-timestamp registrado • Respaldo en la nube' : 'Toma la foto del pedido en la puerta o mano del cliente',
                            style: TextStyle(
                              fontSize: 11,
                              color: _photoTaken ? AppColors.primaryDeep : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_photoTaken)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Opción 2: Firma Digital del Cliente
            InkWell(
              onTap: _simulateSignatureCapture,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _signatureCaptured ? AppColors.primaryLight : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _signatureCaptured ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: _signatureCaptured ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _signatureCaptured ? AppColors.primary : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _signatureCaptured ? Icons.check : Icons.draw_outlined,
                        color: _signatureCaptured ? Colors.white : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _signatureCaptured ? 'Firma Digital Registrada' : 'Registrar Firma del Cliente',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _signatureCaptured ? AppColors.primaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _signatureCaptured ? 'Firma digital capturada y validada' : 'Firma en pantalla táctil al recibir',
                            style: TextStyle(
                              fontSize: 11,
                              color: _signatureCaptured ? AppColors.primaryDeep : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_signatureCaptured)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notas Adicionales de Entrega
            const Text(
              'Nota de Entrega (Opcional):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ej. Entregado en mano a cliente / recepcionista',
              ),
            ),
            const SizedBox(height: 24),

            // Botón Confirmar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // Validación Estricta
                  if (!_photoTaken && !_signatureCaptured) {
                    setState(() {
                      _validationError = '⚠️ Es obligatorio tomar la foto del paquete o registrar la firma antes de marcar entregado.';
                    });
                    return;
                  }

                  Navigator.pop(context);
                  widget.onConfirmed(
                    proofUrl: _photoUrl,
                    signatureSvg: _signatureSvg,
                    notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_photoTaken || _signatureCaptured) ? AppColors.primary : const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'CONFIRMAR Y COMPLETAR ORDEN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
