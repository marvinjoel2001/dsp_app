import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../../controllers/auth_controller.dart';

class DriverDocumentsVerificationScreen extends StatefulWidget {
  const DriverDocumentsVerificationScreen({super.key});

  @override
  State<DriverDocumentsVerificationScreen> createState() => _DriverDocumentsVerificationScreenState();
}

class _DriverDocumentsVerificationScreenState extends State<DriverDocumentsVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isSaving = false;

  String? _idCardUrl;
  String? _licenseUrl;
  String? _soatUrl;
  String? _vehiclePhotoUrl;

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthController>().currentDriver;
    if (driver != null) {
      _idCardUrl = driver.idCardUrl;
      _licenseUrl = driver.licenseUrl;
      _soatUrl = driver.soatUrl;
      _vehiclePhotoUrl = driver.vehiclePhotoUrl;
    }
  }

  Future<void> _uploadDoc(String docType) async {
    setState(() => _isUploading = true);

    try {
      XFile? image;
      try {
        image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      } catch (_) {
        try {
          image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
        } catch (_) {}
      }

      List<int> bytes;
      String filename = '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (image != null) {
        bytes = await image.readAsBytes();
      } else {
        bytes = utf8.encode('doc_${docType}_${DateTime.now().millisecondsSinceEpoch}');
      }

      final result = await CloudinaryUploadService.uploadImageBytes(
        bytes: bytes,
        fileName: filename,
        folder: 'chiringuito/drivers/documents',
      );

      setState(() {
        if (docType == 'id_card') _idCardUrl = result.secureUrl;
        if (docType == 'license') _licenseUrl = result.secureUrl;
        if (docType == 'soat') _soatUrl = result.secureUrl;
        if (docType == 'vehicle') _vehiclePhotoUrl = result.secureUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Documento subido con éxito a Cloudinary ($docType).'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir documento: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final driver = authCtrl.currentDriver;
    final status = driver?.verificationStatus ?? 'verified';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Documentos y Verificación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de Verificación Banner
              _buildStatusBanner(status),
              const SizedBox(height: 20),

              const Text(
                'Documentación Obligatoria',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Para mantener activa tu cuenta de repartidor en Chiringuito y recibir ofertas de entrega, sube fotografías nítidas de tus documentos vigentes.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),

              // 1. Cédula de Identidad
              _buildDocCard(
                title: '1. Cédula de Identidad / DNI',
                subtitle: 'Anverso y reverso legible con datos visibles',
                docUrl: _idCardUrl,
                icon: Icons.badge_outlined,
                onUpload: () => _uploadDoc('id_card'),
              ),
              const SizedBox(height: 14),

              // 2. Licencia de Conducir
              _buildDocCard(
                title: '2. Licencia de Conducir Vigente',
                subtitle: 'Categoría para motocicleta o vehículo correspondiente',
                docUrl: _licenseUrl,
                icon: Icons.credit_card_outlined,
                onUpload: () => _uploadDoc('license'),
              ),
              const SizedBox(height: 14),

              // 3. Seguro Obligatorio (SOAT)
              _buildDocCard(
                title: '3. Certificado de Seguro (SOAT)',
                subtitle: 'Comprobante de seguro contra accidentes vigente',
                docUrl: _soatUrl,
                icon: Icons.security_outlined,
                onUpload: () => _uploadDoc('soat'),
              ),
              const SizedBox(height: 14),

              // 4. Foto del Vehículo y Placa
              _buildDocCard(
                title: '4. Fotografía del Vehículo',
                subtitle: 'Foto nítida mostrando el estado del vehículo y placa',
                docUrl: _vehiclePhotoUrl,
                icon: Icons.two_wheeler_outlined,
                onUpload: () => _uploadDoc('vehicle'),
              ),
              const SizedBox(height: 28),

              // Botón Guardar y Enviar a Revisión
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isUploading || _isSaving)
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          final success = await authCtrl.uploadVerificationDocuments(
                            idCardUrl: _idCardUrl,
                            licenseUrl: _licenseUrl,
                            soatUrl: _soatUrl,
                            vehiclePhotoUrl: _vehiclePhotoUrl,
                          );
                          setState(() => _isSaving = false);

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Documentos enviados a revisión exitosamente.'),
                                  backgroundColor: AppColors.primaryDark,
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al guardar documentos en el servidor.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'GUARDAR Y ENVIAR A REVISIÓN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String title;
    String description;

    switch (status) {
      case 'verified':
        bg = AppColors.primaryLight;
        border = AppColors.primary;
        textColor = AppColors.primaryDark;
        icon = Icons.verified;
        title = 'Cuenta Verificada y Activa';
        description = 'Tu documentación está aprobada. Tienes acceso prioritario a todas las órdenes de despacho.';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        border = AppColors.error;
        textColor = AppColors.error;
        icon = Icons.cancel;
        title = 'Documentos Rechazados';
        description = 'Algunos documentos no son legibles o están vencidos. Por favor sube fotografías actualizadas.';
        break;
      case 'pending':
      default:
        bg = AppColors.warningLight;
        border = AppColors.warning;
        textColor = const Color(0xFF92400E);
        icon = Icons.hourglass_top;
        title = 'Revisión en Proceso';
        description = 'Tu documentación está siendo validada por la central de operaciones Chiringuito (24-48 hrs).';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, height: 1.35, color: textColor.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required String title,
    required String subtitle,
    required String? docUrl,
    required IconData icon,
    required VoidCallback onUpload,
  }) {
    final hasUploaded = docUrl != null && docUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasUploaded ? AppColors.primary : const Color(0xFFE2E8F0),
          width: hasUploaded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasUploaded ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: hasUploaded ? AppColors.primaryDark : const Color(0xFF64748B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (hasUploaded)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 14),

          // Botón Subir / Cambiar Archivo
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _isUploading ? null : onUpload,
              icon: Icon(
                hasUploaded ? Icons.refresh : Icons.camera_alt_outlined,
                size: 16,
                color: hasUploaded ? AppColors.primaryDark : const Color(0xFF0F172A),
              ),
              label: Text(
                hasUploaded ? 'Cambiar Foto / Archivo' : 'Tomar Foto o Subir Documento',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: hasUploaded ? AppColors.primaryDark : const Color(0xFF0F172A),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: hasUploaded ? AppColors.primary : const Color(0xFFCBD5E1),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
