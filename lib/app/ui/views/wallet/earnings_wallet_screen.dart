import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/wallet_model.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/withdraw_funds_dialog.dart';

class EarningsWalletScreen extends StatefulWidget {
  final bool showAppBarLeading;
  const EarningsWalletScreen({super.key, this.showAppBarLeading = true});

  @override
  State<EarningsWalletScreen> createState() => _EarningsWalletScreenState();
}

class _EarningsWalletScreenState extends State<EarningsWalletScreen> {
  double _balance = 0.0;
  List<WalletTransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'ALL'; // 'ALL', 'INCOME', 'WITHDRAWAL'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  Future<void> _loadWalletData({bool showIndicator = true}) async {
    if (showIndicator) {
      setState(() => _isLoading = true);
    }

    try {
      final authCtrl = context.read<AuthController>();
      final walletInfo = await authCtrl.getWallet();

      if (mounted) {
        setState(() {
          _balance = walletInfo.balance;
          _transactions = walletInfo.transactions;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final driver = context.read<AuthController>().currentDriver;
        setState(() {
          _balance = driver?.walletBalance ?? 0.0;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _openWithdrawDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawFundsDialog(
        currentBalance: _balance,
        onWithdrawConfirmed: (amount, method, accountHolder, accountNumberOrPhone) async {
          final authCtrl = context.read<AuthController>();
          final success = await authCtrl.requestWithdrawal(
            amount: amount,
            method: method,
            accountHolder: accountHolder,
            accountNumberOrPhone: accountNumberOrPhone,
          );

          if (success) {
            await _loadWalletData(showIndicator: false);

            if (mounted) {
              _showWithdrawalCelebration(amount, method, '$accountHolder - $accountNumberOrPhone');
            }
          }
          return success;
        },
      ),
    );
  }

  void _showWithdrawalCelebration(double amount, String method, String accountInfo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF059669),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '¡Solicitud Procesada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Se ha registrado tu solicitud de transferencia por Bs. ${amount.toStringAsFixed(2)} vía ${method == 'BANK_TRANSFER' ? 'Cuenta Bancaria' : 'QR Simple'}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Destino: $accountInfo',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<WalletTransactionModel> get _filteredTransactions {
    if (_selectedFilter == 'INCOME') {
      return _transactions.where((tx) => tx.amount > 0).toList();
    } else if (_selectedFilter == 'WITHDRAWAL') {
      return _transactions.where((tx) => tx.amount < 0 || tx.type == 'WITHDRAWAL').toList();
    }
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _isRefreshing
                ? null
                : () {
                    setState(() => _isRefreshing = true);
                    _loadWalletData(showIndicator: false);
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadWalletData(showIndicator: false),
          color: AppColors.primary,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta de Saldo con Gradiente Moderno y Animación
                      _buildBalanceCard(),

                      const SizedBox(height: 28),

                      // Barra de Filtros de Transacciones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Historial de Movimientos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_filteredTransactions.length} reg.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Chips de Filtro
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('ALL', 'Todos los movimientos'),
                            const SizedBox(width: 8),
                            _buildFilterChip('INCOME', 'Ganancias (+)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('WITHDRAWAL', 'Retiros (-)'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Listado de Transacciones
                      if (_filteredTransactions.isEmpty)
                        _buildEmptyTransactions()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = _filteredTransactions[index];
                            return _buildTransactionCard(tx);
                          },
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final canWithdraw = _balance >= 10.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wallet_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SALDO DISPONIBLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BOB (Bs.)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Contador Animado del Saldo
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: _balance),
            builder: (_, val, __) {
              return Text(
                'Bs. ${val.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.2,
                ),
              );
            },
          ),
          const SizedBox(height: 22),

          // Botón de Retiro Rápido
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canWithdraw ? _openWithdrawDialog : null,
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    canWithdraw ? 'Retirar Fondos' : 'Mínimo Bs. 10.00',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF064E3B),
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.4),
                    disabledForegroundColor: const Color(0xFF064E3B).withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 22),
                  onPressed: canWithdraw ? _openWithdrawDialog : null,
                  tooltip: 'Retiro vía QR Simple',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sin movimientos registrados',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Las órdenes completadas y los retiros solicitados se reflejarán automáticamente en esta lista.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionModel tx) {
    final isCredit = tx.amount > 0;
    final formattedAmount = '${isCredit ? '+' : ''}Bs. ${tx.amount.abs().toStringAsFixed(2)}';
    final dateStr = DateFormat('dd MMM, hh:mm a').format(tx.createdAt);

    IconData icon;
    Color iconBg;
    Color iconColor;

    if (tx.type == 'WITHDRAWAL' || !isCredit) {
      icon = Icons.arrow_upward_rounded;
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFEF4444);
    } else {
      icon = Icons.arrow_downward_rounded;
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF059669);
    }

    String displayTitle = 'Entrega Completada';
    if (tx.type == 'WITHDRAWAL') {
      displayTitle = 'Retiro Solicitado';
    } else if (tx.type == 'BONUS') {
      displayTitle = 'Bono de Desempeño';
    } else if (tx.type == 'ADJUSTMENT') {
      displayTitle = 'Ajuste Administrativo';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tx.description ?? (isCredit ? 'Abono por despacho' : 'Transferencia bancaria'),
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
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: isCredit ? const Color(0xFF059669) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
