import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';

class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({super.key});

  @override
  State<EditDriverProfileScreen> createState() => _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehiclePlateController;
  String _selectedVehicleType = 'MOTORCYCLE';

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthController>().currentDriver;
    _fullNameController = TextEditingController(text: driver?.fullName ?? '');
    _phoneController = TextEditingController(text: driver?.phone ?? '');
    _vehiclePlateController = TextEditingController(text: driver?.vehiclePlate ?? '');
    _selectedVehicleType = driver?.vehicleType ?? 'MOTORCYCLE';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Editar Perfil y Vehículo',
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar con insignia
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: const Icon(Icons.person, size: 50, color: AppColors.primaryDark),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Nombre Completo
                _buildFieldLabel('Nombre y Apellidos *'),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Tu nombre completo',
                    prefixIcon: Icon(Icons.person_outline, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'El nombre es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 2. Teléfono
                _buildFieldLabel('Teléfono Celular *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '+591 70000000',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'El teléfono es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Tipo de Vehículo Selector
                _buildFieldLabel('Tipo de Vehículo *'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedVehicleType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                      items: const [
                        DropdownMenuItem(
                          value: 'MOTORCYCLE',
                          child: Row(
                            children: [
                              Icon(Icons.two_wheeler, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Text('Motocicleta Express', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'BICYCLE',
                          child: Row(
                            children: [
                              Icon(Icons.pedal_bike, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Text('Bicicleta / E-Bike', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'CAR',
                          child: Row(
                            children: [
                              Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Text('Automóvil / Furgoneta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedVehicleType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Placa del Vehículo
                _buildFieldLabel('Placa / Matrícula del Vehículo *'),
                TextFormField(
                  controller: _vehiclePlateController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '1234-XYZ',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20, color: Color(0xFF94A3B8)),
                  ),
                  validator: (val) {
                    if (_selectedVehicleType != 'BICYCLE' && (val == null || val.trim().isEmpty)) {
                      return 'La placa es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón Guardar Cambios
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: authCtrl.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              final success = await authCtrl.updateProfile(
                                fullName: _fullNameController.text.trim(),
                                phone: _phoneController.text.trim(),
                                vehicleType: _selectedVehicleType,
                                vehiclePlate: _vehiclePlateController.text.trim().toUpperCase(),
                              );

                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Perfil actualizado correctamente.'),
                                    backgroundColor: AppColors.primaryDark,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authCtrl.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Guardar Cambios de Perfil',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
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
