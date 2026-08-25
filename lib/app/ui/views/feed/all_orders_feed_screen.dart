import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/orders_feed_controller.dart';
import '../../controllers/active_ride_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/order_feed_card.dart';
import '../drawer/driver_side_drawer.dart';
import '../navigation/live_map_navigation_screen.dart';
import '../wallet/earnings_wallet_screen.dart';

class AllOrdersFeedScreen extends StatefulWidget {
  const AllOrdersFeedScreen({super.key});

  @override
  State<AllOrdersFeedScreen> createState() => _AllOrdersFeedScreenState();
}

class _AllOrdersFeedScreenState extends State<AllOrdersFeedScreen> {
  int _selectedBottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final feedCtrl = context.watch<OrdersFeedController>();
    final activeRideCtrl = context.watch<ActiveRideController>();
    final authCtrl = context.watch<AuthController>();
    final driver = authCtrl.currentDriver;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const DriverSideDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco, color: AppColors.primary, size: 18),
            SizedBox(width: 6),
            Text(
              'Food Drive',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Active ride shortcut badge if on active delivery
          if (activeRideCtrl.activeOrder != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveMapNavigationScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.navigation, size: 12, color: AppColors.primaryDark),
                    SizedBox(width: 4),
                    Text(
                      'Live Trip',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 You have 2 new dispatch offers nearby!'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: _buildSelectedTabContent(feedCtrl, activeRideCtrl, authCtrl),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.list_alt, label: 'Orders', index: 0),
                _buildNavItem(icon: Icons.history, label: 'History', index: 1),
                _buildNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', index: 2),
                _buildNavItem(icon: Icons.person_outline, label: 'Profile', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(
    OrdersFeedController feedCtrl,
    ActiveRideController activeRideCtrl,
    AuthController authCtrl,
  ) {
    switch (_selectedBottomNavIndex) {
      case 0:
        return _buildOrdersFeedTab(feedCtrl, activeRideCtrl, authCtrl);
      case 1:
        return _buildHistoryTab();
      case 2:
        return const EarningsWalletScreen();
      case 3:
        return _buildProfileTab(authCtrl);
      default:
        return _buildOrdersFeedTab(feedCtrl, activeRideCtrl, authCtrl);
    }
  }

  Widget _buildOrdersFeedTab(
    OrdersFeedController feedCtrl,
    ActiveRideController activeRideCtrl,
    AuthController authCtrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title: All Orders
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Orders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (authCtrl.currentDriver?.isOnline ?? false) ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: (authCtrl.currentDriver?.isOnline ?? false) ? AppColors.primary : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (authCtrl.currentDriver?.isOnline ?? false) ? 'Ready for Orders' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: (authCtrl.currentDriver?.isOnline ?? false) ? AppColors.primaryDark : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Selector: Pickup Request / Delivery Request
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => feedCtrl.setTab(FeedTab.pickupRequest),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (feedCtrl.selectedTab == FeedTab.pickupRequest)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      'Pickup Request',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: feedCtrl.selectedTab == FeedTab.pickupRequest
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: feedCtrl.selectedTab == FeedTab.pickupRequest
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => feedCtrl.setTab(FeedTab.deliveryRequest),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (feedCtrl.selectedTab == FeedTab.deliveryRequest)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      'Delivery Request',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: feedCtrl.selectedTab == FeedTab.deliveryRequest
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: feedCtrl.selectedTab == FeedTab.deliveryRequest
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Orders Scroll List with Pull to Refresh
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => feedCtrl.fetchOrders(authCtrl.currentDriver?.id ?? 'c8716b1e-6240-4b2a-8c01-7faef83151cf'),
            child: feedCtrl.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: feedCtrl.orders.length,
                    itemBuilder: (context, index) {
                      final order = feedCtrl.orders[index];
                      return OrderFeedCard(
                        order: order,
                        onPickOrder: () async {
                          final driverId = authCtrl.currentDriver?.id ?? 'c8716b1e-6240-4b2a-8c01-7faef83151cf';
                          final accepted = await feedCtrl.acceptOrder(order.id, driverId);
                          if (accepted && mounted) {
                            activeRideCtrl.setActiveOrder(order);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LiveMapNavigationScreen(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final historyItems = [
      {'id': '#434565', 'pickup': '42 King Mission', 'dropoff': '67 Hyatt Ext', 'price': '\$72.00', 'time': 'Today, 10:15 AM'},
      {'id': '#434564', 'pickup': 'Av. San Martín 450', 'dropoff': 'Calle 5 Equipetrol', 'price': '\$35.00', 'time': 'Yesterday, 08:30 PM'},
      {'id': '#434563', 'pickup': 'Mall Las Brisas', 'dropoff': 'Condominio Sevilla', 'price': '\$48.50', 'time': 'Yesterday, 06:10 PM'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle, color: AppColors.primaryDark, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ${item['id']}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${item['pickup']} → ${item['dropoff']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(item['time']!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(
                        item['price']!,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AuthController authCtrl) {
    final driver = authCtrl.currentDriver;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: const Icon(Icons.person, size: 48, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Text(
            driver?.fullName ?? 'Alex Courier',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                '${driver?.rating ?? 4.9} • Verified Express Driver',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Metrics Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileMetric('142', 'Total Rides'),
                _buildProfileMetric('99.2%', 'Acceptance'),
                _buildProfileMetric('15 min', 'Avg Speed'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Vehicle Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.two_wheeler, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver?.vehicleType ?? 'MOTORCYCLE', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('Plate: ${driver?.vehiclePlate ?? "1234-XYZ"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMetric(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDeep)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedBottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedBottomNavIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
