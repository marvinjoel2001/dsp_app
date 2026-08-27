import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/withdraw_funds_dialog.dart';

class EarningsWalletScreen extends StatefulWidget {
  final bool showAppBarLeading;
  const EarningsWalletScreen({super.key, this.showAppBarLeading = true});

  @override
  State<EarningsWalletScreen> createState() => _EarningsWalletScreenState();
}

class _EarningsWalletScreenState extends State<EarningsWalletScreen> {
  double _balance = 142.50;
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Pago Orden #434567',
      'subtitle': '062 Kuhn Plains → 922 Wilfredo Tunnel',
      'amount': '+\$43.20',
      'time': 'Hoy, 12:45 PM',
      'isCredit': true,
    },
    {
      'title': 'Pago Orden #434566',
      'subtitle': '42 King Mission → 67 Hyatt Extension',
      'amount': '+\$57.60',
      'time': 'Hoy, 10:15 AM',
      'isCredit': true,
    },
    {
      'title': 'Retiro a Cuenta Bancaria',
      'subtitle': 'Transferencia a Banco •••• 9941',
      'amount': '-\$120.00',
      'time': 'Ayer, 06:30 PM',
      'isCredit': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    final driver = context.read<AuthController>().currentDriver;
    if (driver != null && driver.walletBalance > 0) {
      _balance = driver.walletBalance;
    }
  }

  void _openWithdrawDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawFundsDialog(
        currentBalance: _balance,
        onWithdrawConfirmed: (amount, method, accountInfo) {
          final driver = context.read<AuthController>().currentDriver;
          if (driver != null) {
            try {
              ApiClient().dio.post(
                '/v1/settlements/withdrawals/request',
                data: {
                  'driverId': driver.id,
                  'amount': amount,
                  'method': method,
                  'accountHolder': driver.fullName,
                  'accountNumberOrPhone': accountInfo,
                },
              );
            } catch (_) {}
          }

          setState(() {
            _balance -= amount;
            _transactions.insert(0, {
              'title': method == 'BANK_TRANSFER' ? 'Retiro a Cuenta Bancaria' : 'Retiro vía QR Simple',
              'subtitle': accountInfo,
              'amount': '-Bs. ${amount.toStringAsFixed(2)}',
              'time': 'Hace un momento',
              'isCredit': false,
            });
          });

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                  SizedBox(width: 10),
                  Text('¡Retiro Procesado!'),
                ],
              ),
              content: Text(
                'Se ha enviado la solicitud de transferencia por Bs. ${amount.toStringAsFixed(2)} hacia:\n\n📌 $accountInfo\n\nEl abono se verá reflejado en tu cuenta en un plazo máximo de 15 a 30 minutos.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Ganancias y Billetera',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: widget.showAppBarLeading
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de Saldo Disponible con Gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDeep, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SALDO DISPONIBLE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bs. ${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _balance >= 10.0 ? _openWithdrawDialog : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDeep,
                              disabledBackgroundColor: Colors.white.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Retirar Fondos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transacciones Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_transactions.length} registros',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ..._transactions.map((tx) => _buildTransactionItem(
                    title: tx['title'] as String,
                    subtitle: tx['subtitle'] as String,
                    amount: tx['amount'] as String,
                    time: tx['time'] as String,
                    isCredit: tx['isCredit'] as bool,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required String amount,
    required String time,
    required bool isCredit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCredit ? AppColors.primaryLight : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
              color: isCredit ? AppColors.primaryDark : AppColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isCredit ? AppColors.primaryDark : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
