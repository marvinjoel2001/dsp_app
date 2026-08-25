import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../navigation/live_map_navigation_screen.dart';
import '../wallet/earnings_wallet_screen.dart';

class DriverSideDrawer extends StatelessWidget {
  const DriverSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final driver = authCtrl.currentDriver;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Driver Header: Avatar, Name, Rating & Online Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver?.fullName ?? 'Alex Courier',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${driver?.rating ?? 4.9}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Online / Offline Switch
                  GestureDetector(
                    onTap: () {
                      final newState = !(driver?.isOnline ?? false);
                      authCtrl.toggleOnline(newState);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newState ? '🟢 You are now ONLINE and visible on Redis GEO' : '⚪ You are now OFFLINE',
                          ),
                          backgroundColor: newState ? AppColors.primaryDark : AppColors.textPrimary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (driver?.isOnline ?? false)
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (driver?.isOnline ?? false) ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
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

            const SizedBox(height: 28),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 16),

            // Navigation Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Active Rides (Highlighted in Emerald Pill)
                  _buildDrawerItem(
                    icon: Icons.alt_route,
                    title: 'Active Rides',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveMapNavigationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Earnings & Wallet
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Earnings & Wallet',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EarningsWalletScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Vehicle Details Dialog
                  _buildDrawerItem(
                    icon: Icons.two_wheeler_outlined,
                    title: 'Vehicle Details',
                    onTap: () {
                      Navigator.pop(context);
                      _showVehicleDialog(context, driver);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Performance Dialog
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'Performance',
                    onTap: () {
                      Navigator.pop(context);
                      _showPerformanceDialog(context);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Settings Dialog
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsDialog(context);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Help & Support Dialog
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      _showSupportDialog(context);
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer Brand
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: const [
                  Icon(Icons.eco, size: 18, color: AppColors.primaryDark),
                  SizedBox(width: 8),
                  Text(
                    'FOOD DRIVE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDialog(BuildContext context, dynamic driver) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.two_wheeler, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Vehicle Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', driver?.vehicleType ?? 'MOTORCYCLE'),
            _buildDetailRow('Plate', driver?.vehiclePlate ?? '1234-XYZ'),
            _buildDetailRow('Model', 'Honda CB 160cc (2024)'),
            _buildDetailRow('Insurance', 'SOAT Valid until Dec 2026'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPerformanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Performance Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Rating', '4.9 ★ (Top 5% of Couriers)'),
            _buildDetailRow('Acceptance Rate', '99.2%'),
            _buildDetailRow('On-Time Delivery', '98.5%'),
            _buildDetailRow('Completed Deliveries', '142 orders'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Driver App Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Map Engine', 'Mapbox Vector Streets v12'),
            _buildDetailRow('GPS Telemetry Frequency', 'Every 5 seconds'),
            _buildDetailRow('Sound Notifications', 'Enabled'),
            _buildDetailRow('Language', 'Español / English'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Help & Dispatch Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Need urgent assistance with an active delivery?', style: TextStyle(fontSize: 13, height: 1.4)),
            SizedBox(height: 12),
            Text('📞 Dispatch Hotline: +591 700-00000', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('💬 WhatsApp Ops: +591 711-22334', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
