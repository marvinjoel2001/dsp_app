import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WithdrawFundsDialog extends StatefulWidget {
  final double currentBalance;
  final Future<bool> Function(
    double amount,
    String method,
    String accountHolder,
    String accountNumberOrPhone,
  ) onWithdrawConfirmed;

  const WithdrawFundsDialog({
    super.key,
    required this.currentBalance,
    required this.onWithdrawConfirmed,
  });

  @override
  State<WithdrawFundsDialog> createState() => _WithdrawFundsDialogState();
}

class _WithdrawFundsDialogState extends State<WithdrawFundsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _accountHolderController = TextEditingController();

  String _selectedMethod = 'BANK_TRANSFER';
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _accountHolderController.dispose();
    super.dispose();
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
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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

              // Título y Saldo Disponible
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retiro de Fondos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Transfiere tus ganancias acumuladas',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('DISPONIBLE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryDeep)),
                        Text(
                          'Bs. ${widget.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. Monto a Retirar con Validación
              const Text(
                'Monto a Retirar (Bs.) *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Ej. 50.00',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Text('Bs.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ),
                  suffixIcon: TextButton(
                    onPressed: () {
                      _amountController.text = widget.currentBalance.toStringAsFixed(2);
                    },
                    child: const Text('TODO', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el monto a retirar';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto numérico válido';
                  }
                  if (amount < 10.0) {
                    return 'El monto mínimo de retiro es Bs. 10.00';
                  }
                  if (amount > widget.currentBalance) {
                    return 'El monto supera tu saldo disponible (Bs. ${widget.currentBalance.toStringAsFixed(2)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // 2. Método de Destino
              const Text(
                'Método de Pago / Destino *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMethodChip('BANK_TRANSFER', 'Cuenta Bancaria', Icons.account_balance),
                  const SizedBox(width: 8),
                  _buildMethodChip('QR_PAYMENT', 'QR / Simple', Icons.qr_code_2),
                ],
              ),
              const SizedBox(height: 18),

              // 3. Titular de la Cuenta
              const Text(
                'Nombre del Titular *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountHolderController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'Nombre completo del titular',
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: Color(0xFF94A3B8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el nombre del titular';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Número de Cuenta / Teléfono QR
              Text(
                _selectedMethod == 'BANK_TRANSFER' ? 'Número de Cuenta Bancaria / IBAN *' : 'Número de Teléfono / CI para QR *',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.text,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: _selectedMethod == 'BANK_TRANSFER' ? 'Ej. 1000004928192 (Banco Unión / BCP)' : 'Ej. +591 70000000',
                  prefixIcon: const Icon(Icons.credit_card, size: 20, color: Color(0xFF94A3B8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo es obligatorio para procesar la transferencia';
                  }
                  if (value.trim().length < 6) {
                    return 'Ingresa un número de cuenta válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botón Procesar Retiro
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() {
                              _isProcessing = true;
                              _errorMessage = null;
                            });

                            final amount = double.parse(_amountController.text.trim());
                            final method = _selectedMethod;
                            final accountHolder = _accountHolderController.text.trim();
                            final accountNumberOrPhone = _accountController.text.trim();

                            try {
                              final success = await widget.onWithdrawConfirmed(
                                amount,
                                method,
                                accountHolder,
                                accountNumberOrPhone,
                              );

                              if (!mounted) return;

                              if (success) {
                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  _isProcessing = false;
                                  _errorMessage = 'No se pudo procesar el retiro. Verifica que el monto no exceda tu saldo.';
                                });
                              }
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _isProcessing = false;
                                _errorMessage = e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'SOLICITAR TRANSFERENCIA',
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
      ),
    );
  }

  Widget _buildMethodChip(String methodKey, String label, IconData icon) {
    final isSelected = _selectedMethod == methodKey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = methodKey),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primaryDark : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.primaryDark : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
