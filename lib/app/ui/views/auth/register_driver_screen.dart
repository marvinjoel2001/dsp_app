import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_svg_icons.dart';
import '../../../core/theme/page_transitions.dart';
import '../../controllers/auth_controller.dart';
import '../permissions/permission_request_screen.dart';

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  String _selectedVehicleType = 'MOTORCYCLE';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado Chiringuito Driver SVG
                Row(
                  children: [
                    AppSvgIcons.chiringuitoLogo(size: 32),
                    const SizedBox(width: 10),
                    const Text(
                      'CHIRINGUITO DRIVER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDeep,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Registro de Repartidor',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Únete a la flota de Chiringuito y empieza a recibir órdenes de despacho en tu zona.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // 1. Nombre Completo
                _buildFieldLabel('Nombre y Apellidos *'),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'Ej. Alex Mendoza Quispe',
                    prefixIcon: Icon(Icons.person_outline, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre completo';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Ingresa al menos un nombre y un apellido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 2. Correo Electrónico
                _buildFieldLabel('Correo Electrónico *'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'alex.repartidor@correo.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo electrónico es obligatorio';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Ingresa un correo electrónico válido (ej. alex@chiringuito.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Teléfono Celular
                _buildFieldLabel('Número de Teléfono Celular *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: '+591 70000000',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El número de teléfono es obligatorio';
                    }
                    if (value.trim().length < 7) {
                      return 'Ingresa un número telefónico válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // 4. Selector Interactivo de Vehículo con Iconos SVG
                _buildFieldLabel('Tipo de Vehículo de Despacho *'),
                const SizedBox(height: 6),
                _buildVehicleOption(
                  type: 'MOTORCYCLE',
                  label: 'Motocicleta Express',
                  description: 'Ideal para entregas rápidas de comida y encomiendas ligeras',
                  svgWidget: AppSvgIcons.motorcycleCourier(size: 28),
                ),
                const SizedBox(height: 10),
                _buildVehicleOption(
                  type: 'BICYCLE',
                  label: 'Bicicleta / E-Bike',
                  description: 'Ecológico, ágil en zonas céntricas y de alta densidad',
                  svgWidget: AppSvgIcons.bicycleCourier(size: 28),
                ),
                const SizedBox(height: 10),
                _buildVehicleOption(
                  type: 'CAR',
                  label: 'Automóvil / Furgoneta',
                  description: 'Para múltiples pedidos simultáneos o paquetería de mayor volumen',
                  svgWidget: AppSvgIcons.carCourier(size: 28),
                ),
                const SizedBox(height: 16),

                // 5. Placa del Vehículo
                _buildFieldLabel(
                  _selectedVehicleType == 'BICYCLE'
                      ? 'Identificador / Código de Bicicleta (Opcional)'
                      : 'Número de Placa / Matrícula *',
                ),
                TextFormField(
                  controller: _vehiclePlateController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: _selectedVehicleType == 'BICYCLE' ? 'BIKE-01' : '1234-XYZ',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (value) {
                    if (_selectedVehicleType != 'BICYCLE') {
                      if (value == null || value.trim().isEmpty) {
                        return 'La placa del vehículo es requerida para motocicletas o autos';
                      }
                      if (value.trim().length < 4) {
                        return 'Ingresa una placa válida (ej. 1234-XYZ)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 6. Contraseña
                _buildFieldLabel('Contraseña de Acceso *'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es requerida';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 7. Confirmar Contraseña
                _buildFieldLabel('Confirmar Contraseña *'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Repite tu contraseña',
                    prefixIcon: const Icon(Icons.lock_reset, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Términos y Condiciones
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Acepto los Términos de Servicio, Políticas de Seguridad Vial y Privacidad de Datos de Chiringuito Driver.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Botón Crear Cuenta
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authCtrl.isLoading
                        ? null
                        : () async {
                            if (!_acceptTerms) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debes aceptar los Términos y Condiciones para registrarte.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            if (_formKey.currentState?.validate() ?? false) {
                              final success = await authCtrl.registerDriver(
                                fullName: _fullNameController.text.trim(),
                                email: _emailController.text.trim(),
                                phone: _phoneController.text.trim(),
                                password: _passwordController.text,
                                vehicleType: _selectedVehicleType,
                                vehiclePlate: _selectedVehicleType == 'BICYCLE' && _vehiclePlateController.text.trim().isEmpty
                                    ? 'BIKE-N/A'
                                    : _vehiclePlateController.text.trim().toUpperCase(),
                              );

                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 ¡Bienvenido a Chiringuito Driver, ${_fullNameController.text.split(" ")[0]}! Tu cuenta ha sido creada.'),
                                    backgroundColor: AppColors.primaryDark,
                                  ),
                                );
                                context.pushReplacementAnimated(const PermissionRequestScreen());
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authCtrl.errorMessage ?? 'Error al registrar conductor.'),
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
                    child: authCtrl.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Crear Cuenta y Empezar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Enlace a Inicio de Sesión
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Ya tienes una cuenta de conductor?',
                        style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Inicia Sesión',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleOption({
    required String type,
    required String label,
    required String description,
    required Widget svgWidget,
  }) {
    final isSelected = _selectedVehicleType == type;

    return InkWell(
      onTap: () => setState(() => _selectedVehicleType = type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Center(child: svgWidget),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.primaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}
