import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import '../../../core/services/cloudinary_upload_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/digital_signature_pad.dart';
import 'driver_verification_pending_screen.dart';

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Paso 1: Datos Personales y Domicilio
  final _formKeyStep1 = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _homeAddressController = TextEditingController();
  String _selectedCity = 'Santa Cruz';
  bool _obscurePassword = true;

  // Paso 2: C.I. y Vehículo
  final _formKeyStep2 = GlobalKey<FormState>();
  final _ciNumberController = TextEditingController();
  String _ciExpedition = 'SC';
  String _selectedVehicleType = 'MOTORCYCLE';
  final _vehiclePlateController = TextEditingController();
  String? _idCardUrl;
  String? _licenseUrl;
  String? _soatUrl;

  // Estados de subida individual y errores para documentos
  final Map<String, bool> _uploadingDocs = {
    'id_card': false,
    'license': false,
    'soat': false,
  };
  final Map<String, String?> _docErrors = {
    'id_card': null,
    'license': null,
    'soat': null,
  };

  // Paso 3: Selfie Facial de Seguridad (Solo Cámara)
  final ImagePicker _picker = ImagePicker();
  String? _avatarUrl;
  bool _isCapturingSelfie = false;

  // Paso 4 y 5: Contrato, Deslinde y Firma
  bool _acceptTerms = false;
  String? _contractSignatureSvg;
  final GlobalKey<DigitalSignaturePadState> _sigPadKey = GlobalKey<DigitalSignaturePadState>();

  bool _isSubmitting = false;

  final List<String> _bolivianCities = [
    'Santa Cruz',
    'La Paz',
    'Cochabamba',
    'El Alto',
    'Sucre',
    'Tarija',
    'Oruro',
    'Potosí',
    'Beni',
    'Pando',
  ];

  final List<String> _ciExpeditions = [
    'SC',
    'LP',
    'CB',
    'EA',
    'CH',
    'TJ',
    'OR',
    'PT',
    'BN',
    'PA',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _homeAddressController.dispose();
    _ciNumberController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getDocTitle(String docType) {
    switch (docType) {
      case 'id_card':
        return 'Carnet de Identidad';
      case 'license':
        return 'Licencia de Conducir';
      case 'soat':
        return 'Certificado SOAT';
      default:
        return 'Documento';
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!(_formKeyStep1.currentState?.validate() ?? false)) {
        _showToast(
          '⚠️ Por favor revisa los campos en rojo para continuar.',
          isError: true,
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!(_formKeyStep2.currentState?.validate() ?? false)) {
        _showToast(
          '⚠️ Por favor verifica el Carnet de Identidad y la placa del vehículo.',
          isError: true,
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (_avatarUrl == null || _avatarUrl!.isEmpty) {
        _showToast(
          '📸 Es obligatorio tomar tu fotografía facial con la cámara antes de continuar.',
          isError: true,
        );
        return;
      }
    } else if (_currentStep == 3) {
      if (!_acceptTerms) {
        _showToast(
          '⚠️ Debes marcar la casilla para aceptar el contrato de prestación de servicios.',
          isError: true,
        );
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // Captura obligatoria de Selfie Facial ÚNICAMENTE con Cámara Frontal
  Future<void> _captureSelfieWithCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requiere permiso de cámara para la verificación biométrica facial.'),
            backgroundColor: AppColors.error,
          ),
        );
        openAppSettings();
      }
      return;
    }

    setState(() => _isCapturingSelfie = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (photo == null) {
        if (mounted) setState(() => _isCapturingSelfie = false);
        return;
      }

      final bytes = await photo.readAsBytes();
      final fileName = 'driver_face_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await CloudinaryUploadService.uploadImageBytes(
        bytes: bytes,
        fileName: fileName,
        folder: 'chiringuito/drivers/avatars',
      );

      if (!mounted) return;
      setState(() {
        _avatarUrl = result.secureUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Fotografía facial capturada y validada correctamente.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la fotografía: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingSelfie = false);
    }
  }

  // Captura de Documentos (Cédula / Licencia / SOAT)
  Future<void> _pickDocumentImage(String docType) async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showToast('Se requiere permiso de cámara para fotografiar tus documentos.', isError: true);
        openAppSettings();
      }
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (file == null) return;

      if (!mounted) return;
      setState(() {
        _uploadingDocs[docType] = true;
        _docErrors[docType] = null;
      });

      final bytes = await file.readAsBytes();
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
        _uploadingDocs[docType] = false;
      });

      if (mounted) {
        _showToast('✅ ${_getDocTitle(docType)} subido y validado.');
      }
    } catch (e) {
      setState(() {
        _uploadingDocs[docType] = false;
        _docErrors[docType] = 'Error al subir imagen. Toca para reintentar.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo subir ${_getDocTitle(docType)}: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _pickDocumentImage(docType),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (_contractSignatureSvg == null || _contractSignatureSvg!.isEmpty) {
      _showToast(
        '✍️ Por favor dibuja tu firma digital en el recuadro antes de finalizar.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final authCtrl = context.read<AuthController>();

    final fullCi = '${_ciNumberController.text.trim()} $_ciExpedition';
    final fullAddress = '${_homeAddressController.text.trim()}, $_selectedCity, Bolivia';

    final success = await authCtrl.registerDriver(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      vehicleType: _selectedVehicleType,
      vehiclePlate: _vehiclePlateController.text.trim().toUpperCase(),
      ciNumber: fullCi,
      homeAddress: fullAddress,
      avatarUrl: _avatarUrl,
      idCardUrl: _idCardUrl,
      licenseUrl: _licenseUrl,
      soatUrl: _soatUrl,
      contractSignatureSvg: _contractSignatureSvg,
      contractAcceptedAt: DateTime.now(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showToast('🎉 ¡Registro completado con éxito! Tu solicitud fue enviada a revisión.');
      // Redirige a la pantalla de espera de validación
      context.pushReplacementAnimated(const DriverVerificationPendingScreen());
    } else {
      _showToast(
        authCtrl.errorMessage ?? 'Error al registrar conductor. Por favor verifica tus datos.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: _previousStep,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgIcons.chiringuitoLogo(size: 26),
            const SizedBox(width: 8),
            const Text(
              'CHIRINGUITO DRIVER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeep,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de Progreso de Pasos Animada
            _buildStepProgressBar(),

            // Contenido de los Pasos
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Navegación controlada
                children: [
                  _buildStep1PersonalAndAddress(),
                  _buildStep2VehicleAndCi(),
                  _buildStep3FaceSelfieCameraOnly(),
                  _buildStep4ContractAndDisclaimer(),
                  _buildStep5DigitalSignature(),
                ],
              ),
            ),

            // Barra Inferior de Navegación de Pasos
            _buildBottomNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressBar() {
    final stepIcons = [
      Icons.person_rounded,
      Icons.two_wheeler_rounded,
      Icons.face_retouching_natural_rounded,
      Icons.description_rounded,
      Icons.draw_rounded,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // 5 Milestone Bubbles con Líneas Conectoras Animadas
          Row(
            children: List.generate(_totalSteps, (index) {
              final isPassed = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Círculo / Burbuja de Paso
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isCurrent ? 34 : 28,
                      height: isCurrent ? 34 : 28,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? const Color(0xFF059669) // Verde completado
                            : (isCurrent ? AppColors.primary : const Color(0xFFF8FAFC)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primary
                              : (isPassed ? const Color(0xFF059669) : const Color(0xFFCBD5E1)),
                          width: isCurrent ? 2.2 : 1.4,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: isPassed
                              ? const Icon(Icons.check_rounded, key: ValueKey('done'), color: Colors.white, size: 16)
                              : Icon(
                                  stepIcons[index],
                                  key: ValueKey('icon_$index'),
                                  color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                                  size: isCurrent ? 17 : 14,
                                ),
                        ),
                      ),
                    ),

                    // Línea conectora hacia el siguiente paso
                    if (index < _totalSteps - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index < _currentStep ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Título y Contador con Transición Suave
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PASO ${_currentStep + 1} DE $_totalSteps',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.08, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  _getStepTitle(_currentStep),
                  key: ValueKey<int>(_currentStep),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Datos Personales & Domicilio';
      case 1:
        return 'C.I. y Vehículo';
      case 2:
        return 'Selfie Facial Obligatoria';
      case 3:
        return 'Contrato & Deslinde Legal';
      case 4:
        return 'Firma Digital en Pantalla';
      default:
        return '';
    }
  }

  // PASO 1: Datos Personales y Domicilio
  Widget _buildStep1PersonalAndAddress() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              icon: Icons.person_pin_outlined,
              title: 'Datos Personales y Domicilio',
              description:
                  'Ingresa tus datos reales y tu dirección de residencia en Bolivia. Esto garantiza la trazabilidad de los despachos y la seguridad de los clientes.',
            ),
            const SizedBox(height: 20),

            _buildFieldLabel('Nombre y Apellido Completos *'),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                hintText: 'Ej. Juan Carlos Mendoza Pérez',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre completo' : null,
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Número de Teléfono Celular (WhatsApp) *'),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+591 70012345',
                prefixIcon: Icon(Icons.phone_android_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().length < 8) ? 'Ingresa tu número de celular válido' : null,
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Correo Electrónico *'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'tu.correo@ejemplo.com',
                prefixIcon: Icon(Icons.mail_outline, size: 20),
              ),
              validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo electrónico válido' : null,
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Contraseña de Acceso (Mínimo 6 caracteres) *'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'La contraseña debe tener al menos 6 caracteres' : null,
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Ciudad de Residencia en Bolivia *'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCity,
                  items: _bolivianCities
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCity = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Dirección de Domicilio Particular *'),
            TextFormField(
              controller: _homeAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ej. Av. Banzer 4to Anillo, Calle 3 #140, Barrio Sirari',
                prefixIcon: Icon(Icons.home_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().length < 6) ? 'Ingresa tu dirección de domicilio completa' : null,
            ),
          ],
        ),
      ),
    );
  }

  // PASO 2: C.I. y Vehículo
  Widget _buildStep2VehicleAndCi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              icon: Icons.two_wheeler_outlined,
              title: 'Cédula de Identidad y Vehículo',
              description:
                  'Indica los datos de tu vehículo de trabajo y tu carnet de identidad. Esto nos permite asignarte pedidos acordes a tu capacidad de carga.',
            ),
            const SizedBox(height: 20),

            _buildFieldLabel('Número de Carnet de Identidad (C.I.) *'),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _ciNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Ej. 8945612',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().length < 5) ? 'Ingresa tu C.I.' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _ciExpedition,
                        items: _ciExpeditions
                            .map((e) => DropdownMenuItem(value: e, child: Text('Exp. $e', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _ciExpedition = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildFieldLabel('Tipo de Vehículo para Despacho *'),
            Row(
              children: [
                _buildVehicleOption('MOTORCYCLE', 'Motocicleta', Icons.two_wheeler),
                const SizedBox(width: 10),
                _buildVehicleOption('BICYCLE', 'Bicicleta', Icons.pedal_bike),
                const SizedBox(width: 10),
                _buildVehicleOption('CAR', 'Automóvil', Icons.directions_car),
              ],
            ),
            const SizedBox(height: 20),

            _buildFieldLabel('Número de Placa del Vehículo *'),
            TextFormField(
              controller: _vehiclePlateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ej. 4589-KLT (o N/A para Bici)',
                prefixIcon: Icon(Icons.pin_outlined, size: 20),
              ),
              validator: (v) {
                if (_selectedVehicleType != 'BICYCLE' && (v == null || v.trim().length < 4)) {
                  return 'Ingresa la placa del vehículo';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Documentos de Verificación (Recomendado subirlos ahora):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            _buildDocUploadTile(
              docType: 'id_card',
              title: 'Cédula de Identidad',
              subtitle: 'Foto nítida de anverso y reverso',
              url: _idCardUrl,
              onTap: () => _pickDocumentImage('id_card'),
            ),
            _buildDocUploadTile(
              docType: 'license',
              title: 'Licencia de Conducir',
              subtitle: 'Categoría vigente para tu vehículo',
              url: _licenseUrl,
              onTap: () => _pickDocumentImage('license'),
            ),
            _buildDocUploadTile(
              docType: 'soat',
              title: 'Certificado SOAT',
              subtitle: 'Comprobante de seguro obligatorio',
              url: _soatUrl,
              onTap: () => _pickDocumentImage('soat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleOption(String type, String label, IconData icon) {
    final isSelected = _selectedVehicleType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedVehicleType = type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primaryDark : const Color(0xFF64748B), size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? AppColors.primaryDark : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocUploadTile({
    required String docType,
    required String title,
    required String subtitle,
    required String? url,
    required VoidCallback onTap,
  }) {
    final hasUploaded = url != null && url.isNotEmpty;
    final isUploading = _uploadingDocs[docType] ?? false;
    final error = _docErrors[docType];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: error != null
              ? AppColors.error
              : (hasUploaded ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
          width: hasUploaded || error != null ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasUploaded
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUploading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icono / Preview Thumbnail
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasUploaded ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasUploaded ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: hasUploaded
                        ? Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF059669),
                              size: 24,
                            ),
                          )
                        : Icon(
                            isUploading ? Icons.cloud_upload_rounded : Icons.camera_alt_rounded,
                            color: isUploading ? AppColors.primary : const Color(0xFF64748B),
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: hasUploaded ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        error ?? subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: error != null
                              ? AppColors.error
                              : (hasUploaded ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Botón / Pill de Acción
                if (isUploading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Subiendo...',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  )
                else if (hasUploaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Listo',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.edit_outlined, color: Color(0xFF059669), size: 12),
                      ],
                    ),
                  )
                else if (error != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, color: AppColors.error, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Reintentar',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.error),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_rounded, color: Color(0xFF475569), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Tomar Foto',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PASO 3: Selfie Facial Obligatoria ÚNICAMENTE con Cámara
  Widget _buildStep3FaceSelfieCameraOnly() {
    final hasSelfie = _avatarUrl != null && _avatarUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStepHeader(
            icon: Icons.face_retouching_natural,
            title: 'Verificación Facial en Vivo',
            description:
                'Por políticas de seguridad y autenticidad, debes tomarte una fotografía de tu rostro directamente con la cámara del dispositivo. No se permite subir imágenes de la galería.',
          ),
          const SizedBox(height: 32),

          // Círculo de Vista Previa Facial
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: hasSelfie ? AppColors.primary : const Color(0xFFCBD5E1),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasSelfie ? AppColors.primary.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasSelfie
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          width: 170,
                          height: 170,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80, color: Color(0xFF94A3B8)),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: Icon(Icons.camera_alt, size: 54, color: Color(0xFF94A3B8)),
                          ),
                        ),
                ),
              ),
              if (hasSelfie)
                Positioned(
                  bottom: 6,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            hasSelfie ? '¡Fotografía Facial Registrada!' : 'Rostro Completo y Nítido',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mira directamente a la cámara frontal, sin lentes oscuros ni gorra, con buena iluminación.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Botón Único de Captura con Cámara (Sin Galería)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isCapturingSelfie ? null : _captureSelfieWithCamera,
              icon: _isCapturingSelfie
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(hasSelfie ? Icons.replay : Icons.camera_alt, color: Colors.white, size: 20),
              label: Text(
                _isCapturingSelfie
                    ? 'Procesando captura...'
                    : (hasSelfie ? 'Volver a Tomar Fotografía' : 'Activar Cámara y Tomar Selfie'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelfie ? AppColors.secondary : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PASO 4: Contrato de Prestación de Servicios, Deslinde & Pagos Semanales (Leyes Bolivianas)
  Widget _buildStep4ContractAndDisclaimer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.gavel_outlined,
            title: 'Términos, Deslinde Legal y Pagos',
            description:
                'Marco legal aplicable a repartidores independientes conforme a la legislación boliviana vigente.',
          ),
          const SizedBox(height: 16),

          // Contenedor de Texto Legal Scrolleable
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const SingleChildScrollView(
              child: Text(
                'CONTRATO DE PRESTACIÓN DE SERVICIOS INDEPENDIENTES Y DESLINDE DE RESPONSABILIDAD (ESTADO PLURINACIONAL DE BOLIVIA)\n\n'
                '1. NATURALEZA JURÍDICA: El presente acuerdo se rige bajo las disposiciones del Código Civil Boliviano (Artículos 732, 1279 y concordantes sobre Contratos de Locación de Servicios y Mandato). El REPARTIDOR presta servicios logísticos de forma autónoma, independiente y sin exclusividad ni relación de dependencia laboral con CHIRINGUITO / DSP.\n\n'
                '2. DESLINDE DE RESPONSABILIDADES: El REPARTIDOR declara asumir la total y exclusiva responsabilidad civil, penal y contravencional por cualquier infracción a las leyes de tránsito vigentes en Bolivia, accidentes viales, pérdidas imputables a dolo o negligencia en el traslado de mercadería, paquetes o alimentos perecederos.\n\n'
                '3. POLÍTICA DE LIQUIDACIÓN Y PAGOS SEMANALES: Los ingresos generados por los servicios de despacho completados se computan de forma acumulativa en la billetera virtual del conductor. CHIRINGUITO procesará los pagos correspondientes UNA VEZ A LA SEMANA (los días lunes en horario bancario), mediante transferencia interbancaria ACH o QR Simple a la cuenta proporcionada por el repartidor.\n\n'
                '4. REQUISITOS LEGALES Y SEGURIDAD VIAL: El REPARTIDOR garantiza contar con Licencia de Conducir vigente categoría legal correspondiente, Seguro Obligatorio contra Accidentes de Tránsito (SOAT boliviano) vigente e implementos de seguridad reglamentarios (casco certificado, chaleco reflectivo y mochila térmica desinfectada).\n\n'
                '5. CONSENTIMIENTO Y FIRMA DIGITAL: Al suscribir electrónicamente en la siguiente pantalla, el solicitante reconoce y acepta expresamente el contenido del presente documento vinculante en todo el territorio boliviano.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Checkbox Aceptación Expresa Estilizado en Card
          InkWell(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _acceptTerms ? const Color(0xFFECFDF5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _acceptTerms ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: _acceptTerms ? 2.0 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _acceptTerms
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _acceptTerms ? const Color(0xFF059669) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _acceptTerms ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                        width: 2,
                      ),
                    ),
                    child: _acceptTerms
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'He leído, comprendo y acepto los términos del contrato de servicios, el deslinde de responsabilidad y el esquema de pagos semanales.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PASO 5: Firma Digital Táctil en Pantalla
  Widget _buildStep5DigitalSignature() {
    final driverName = _fullNameController.text.trim().isEmpty ? 'Carlos Mendoza' : _fullNameController.text.trim();
    final driverCi = _ciNumberController.text.trim().isEmpty ? 'C.I. Solicitante' : '${_ciNumberController.text.trim()} $_ciExpedition';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.draw_outlined,
            title: 'Firma Digital en Pantalla',
            description:
                'Como paso final, plasma tu firma digital con tu dedo en el recuadro. Esta firma se vinculará a tu Cédula de Identidad y a tu contrato legal.',
          ),
          const SizedBox(height: 18),

          // Ficha del Solicitante
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null ? const Icon(Icons.person, color: AppColors.primaryDark) : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'C.I.: $driverCi • Residencia: $_selectedCity',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.verified_user, color: AppColors.primary, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Canvas de Firma Táctil
          DigitalSignaturePad(
            key: _sigPadKey,
            onSignatureCaptured: (svg) {
              setState(() => _contractSignatureSvg = svg);
            },
            onClear: () {
              setState(() => _contractSignatureSvg = null);
            },
          ),
          const SizedBox(height: 24),

          // Mensaje de Validación de Firma
          if (_contractSignatureSvg != null && _contractSignatureSvg!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Firma digital registrada y vinculada a tu solicitud de registro.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildBottomNavButtons() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: const Text(
                  'Atrás',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : (isLastStep ? _submitRegistration : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'ENVIAR REGISTRO' : 'Continuar',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Icon(isLastStep ? Icons.check_circle : Icons.arrow_forward_ios, size: 14, color: Colors.white),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
