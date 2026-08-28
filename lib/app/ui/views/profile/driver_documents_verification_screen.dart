import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  String? _uploadingDocType;
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

  void _showImageSourcePicker(String docType, String docTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Subir $docTitle',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona cómo deseas adjuntar la fotografía',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // Opción 1: Cámara
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primaryDark, size: 22),
                ),
                title: const Text(
                  'Tomar Fotografía con la Cámara',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                subtitle: const Text('Abre la cámara del dispositivo', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(docType, ImageSource.camera);
                },
              ),
              const Divider(color: Color(0xFFF1F5F9)),

              // Opción 2: Galería
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.secondaryDark, size: 22),
                ),
                title: const Text(
                  'Elegir de la Galería de Fotos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                subtitle: const Text('Selecciona una imagen guardada', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(docType, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(String docType, ImageSource source) async {
    // 1. Validar Permisos
    if (source == ImageSource.camera) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog('Se requiere acceso a la cámara para tomar la fotografía del documento.');
        }
        return;
      }
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedFile == null) return;

      if (!mounted) return;
      setState(() => _uploadingDocType = docType);

      final bytes = await pickedFile.readAsBytes();
      final fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await CloudinaryUploadService.uploadImageBytes(
        bytes: bytes,
        fileName: fileName,
        folder: 'chiringuito/drivers/documents',
      );

      if (!mounted) return;
      setState(() {
        if (docType == 'id_card') _idCardUrl = result.secureUrl;
        if (docType == 'license') _licenseUrl = result.secureUrl;
        if (docType == 'soat') _soatUrl = result.secureUrl;
        if (docType == 'vehicle') _vehiclePhotoUrl = result.secureUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fotografía subida con éxito a Cloudinary.'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingDocType = null);
    }
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permiso Requerido'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Abrir Ajustes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('No se pudo cargar la vista previa', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
                'Toma fotos nítidas o adjunta archivos legibles de tus documentos vigentes para validar tu cuenta.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 20),

              // 1. Cédula de Identidad
              _buildDocCard(
                docType: 'id_card',
                title: '1. Cédula de Identidad / DNI',
                subtitle: 'Anverso y reverso legible con datos visibles',
                docUrl: _idCardUrl,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),

              // 2. Licencia de Conducir
              _buildDocCard(
                docType: 'license',
                title: '2. Licencia de Conducir Vigente',
                subtitle: 'Categoría para motocicleta o vehículo correspondiente',
                docUrl: _licenseUrl,
                icon: Icons.credit_card_outlined,
              ),
              const SizedBox(height: 14),

              // 3. Seguro Obligatorio (SOAT)
              _buildDocCard(
                docType: 'soat',
                title: '3. Certificado de Seguro (SOAT)',
                subtitle: 'Comprobante de seguro contra accidentes vigente',
                docUrl: _soatUrl,
                icon: Icons.security_outlined,
              ),
              const SizedBox(height: 14),

              // 4. Foto del Vehículo y Placa
              _buildDocCard(
                docType: 'vehicle',
                title: '4. Fotografía del Vehículo',
                subtitle: 'Foto nítida mostrando el estado del vehículo y placa',
                docUrl: _vehiclePhotoUrl,
                icon: Icons.two_wheeler_outlined,
              ),
              const SizedBox(height: 28),

              // Botón Guardar y Enviar a Revisión
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_uploadingDocType != null || _isSaving)
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          final success = await authCtrl.uploadVerificationDocuments(
                            idCardUrl: _idCardUrl,
                            licenseUrl: _licenseUrl,
                            soatUrl: _soatUrl,
                            vehiclePhotoUrl: _vehiclePhotoUrl,
                          );
                          if (!mounted) return;
                          setState(() => _isSaving = false);

                          if (context.mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Documentos guardados y enviados a revisión exitosamente.'),
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
    required String docType,
    required String title,
    required String subtitle,
    required String? docUrl,
    required IconData icon,
  }) {
    final hasUploaded = docUrl != null && docUrl.isNotEmpty;
    final isCurrentlyUploading = _uploadingDocType == docType;

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

          // Miniatura de Vista Previa Real si ya se subió la imagen
          if (hasUploaded) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showImagePreview(title, docUrl),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      docUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(Icons.image, size: 36, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Ver Foto', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Botón Subir / Cambiar Archivo
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: isCurrentlyUploading ? null : () => _showImageSourcePicker(docType, title),
              icon: isCurrentlyUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Icon(
                      hasUploaded ? Icons.refresh : Icons.camera_alt_outlined,
                      size: 16,
                      color: hasUploaded ? AppColors.primaryDark : const Color(0xFF0F172A),
                    ),
              label: Text(
                isCurrentlyUploading
                    ? 'Subiendo a Cloudinary...'
                    : (hasUploaded ? 'Cambiar Fotografía' : 'Tomar Foto o Subir Documento'),
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
