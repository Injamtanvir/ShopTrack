import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/theme_constants.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/connectivity_banner.dart';
import '../services/stats_service.dart';
import 'login_screen.dart';
import 'register_manager_screen.dart';
import 'register_sales_person_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'price_list_screen.dart';
import 'create_invoice_screen.dart';
import 'admin_pending_invoice_screen.dart';
import 'invoice_history_screen.dart';
import 'daily_tracking_screen.dart';
import 'shop_users_screen.dart';
import 'dart:async';

class OwnerHomeScreen extends StatefulWidget {
  static const routeName = '/owner-home';
  const OwnerHomeScreen({Key? key}) : super(key: key);

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentNavIndex = 0;
  final StatsService _statsService = StatsService();
  bool _isLoading = false;
  Timer? _refreshTimer;
  
  // Statistics data
  final Map<String, double> _statsData = {
    'todaySales': 0.0,
    'pendingAmount': 0.0,
    'pendingInvoices': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Set up timer to refresh stats every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user?.shopId;
      
      if (shopId != null) {
        final todayStats = await _statsService.getTodaySalesStats(shopId);
        
        if (mounted) {
          setState(() {
            _statsData['todaySales'] = (todayStats['total_revenue'] ?? 0).toDouble();
            _statsData['pendingAmount'] = (todayStats['pending_amount'] ?? 0).toDouble();
            _statsData['pendingInvoices'] = (todayStats['pending_invoices'] ?? 0).toDouble();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Fallback to dummy data if API call fails
      if (mounted) {
        setState(() {
          _statsData['todaySales'] = 5420.00;
          _statsData['pendingAmount'] = 12050.00;
          _statsData['pendingInvoices'] = 3;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  void _handleNavigationTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home screen
        break;
      case 1:
        Navigator.pushNamed(context, ProductListScreen.routeName);
        break;
      case 2:
        Navigator.pushNamed(context, CreateInvoiceScreen.routeName);
        break;
      case 3:
        _showComingSoonSnackBar('Reports and Analytics');
        break;
      case 4:
        _showMenuOptions();
        break;
    }
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available in future updates'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.people, color: kOwnerRoleColor),
                title: const Text('Manage Users'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, ShopUsersScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: kNewSecondaryColor),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _showComingSoonSnackBar('Settings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.price_change, color: kNewAccentColor),
                title: const Text('Price List'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, PriceListScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: kNewErrorColor),
                title: const Text('Logout', style: TextStyle(color: kNewErrorColor)),
                onTap: () {
                  Navigator.pop(context);
                  _logout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      Future.microtask(() {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kNewBackgroundColor,
      body: ConnectivityBanner(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard Header
                DashboardHeader(
                  shopName: user.shopName ?? 'Your Shop',
                  balance: _statsData['todaySales'] ?? 0.0,
                  userName: user.name,
                  designation: 'OWNER',
                  shopId: user.shopId,
                  notificationCount: 0,
                ),
                
                const SizedBox(height: 24),
                
                // Stats Summary
                _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildStatsSummary(),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(),
                
                const SizedBox(height: 24),
                
                // Main Feature Grid
                _buildMainFeatureGrid(),
                
                const SizedBox(height: 24),
                
                // User Management Section
                _buildUserManagementSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _handleNavigationTap,
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Row(
      children: [
        _buildStatCard(
          title: "Today's Sales",
          value: _statsData['todaySales'] ?? 0.0,
          icon: Icons.trending_up,
          color: kNewSuccessColor,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          title: "Pending Amount",
          value: _statsData['pendingAmount'] ?? 0.0,
          icon: Icons.money_off,
          color: kNewPrimaryColor,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          title: "Pending Invoices",
          value: _statsData['pendingInvoices'] ?? 0.0,
          icon: Icons.pending_actions,
          color: kNewWarningColor,
          isCount: true,
          onTap: () => Navigator.pushNamed(context, AdminPendingInvoicesScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    bool isCount = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 22),
                  Text(
                    isCount ? value.toInt().toString() : '৳ ${value.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: kNewSecondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.receipt_long,
                title: 'Create Invoice',
                onTap: () => Navigator.pushNamed(context, CreateInvoiceScreen.routeName),
                color: kNewPrimaryColor,
              ),
              _buildActionButton(
                icon: Icons.add_circle_outline,
                title: 'Add Product',
                onTap: () => Navigator.pushNamed(context, AddProductScreen.routeName),
                color: kNewSecondaryColor,
              ),
              _buildActionButton(
                icon: Icons.pending_actions,
                title: 'Pending Invoices',
                onTap: () => Navigator.pushNamed(context, AdminPendingInvoicesScreen.routeName),
                color: kNewWarningColor,
              ),
              _buildActionButton(
                icon: Icons.history,
                title: 'Invoice History',
                onTap: () => Navigator.pushNamed(context, InvoiceHistoryScreen.routeName),
                color: kNewAccentColor,
              ),
              _buildActionButton(
                icon: Icons.people,
                title: 'Manage Users',
                onTap: () => Navigator.pushNamed(context, ShopUsersScreen.routeName),
                color: kOwnerRoleColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 110,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: kCardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kNewTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Operations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureCard(
              title: 'Products',
              description: 'Manage your inventory',
              icon: Icons.inventory_2,
              onTap: () => Navigator.pushNamed(context, ProductListScreen.routeName),
              color: kNewPrimaryColor,
            ),
            _buildFeatureCard(
              title: 'Price List',
              description: 'Manage pricing',
              icon: Icons.price_change,
              onTap: () => Navigator.pushNamed(context, PriceListScreen.routeName),
              color: kNewSecondaryColor,
            ),
            _buildFeatureCard(
              title: 'Daily Reports',
              description: 'Track daily performance',
              icon: Icons.analytics,
              onTap: () => Navigator.pushNamed(context, DailyTrackingScreen.routeName),
              color: kNewAccentColor,
            ),
            _buildFeatureCard(
              title: 'Users',
              description: 'Manage shop users',
              icon: Icons.people,
              onTap: () => Navigator.pushNamed(context, ShopUsersScreen.routeName),
              color: kOwnerRoleColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kNewTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: kNewSecondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'User Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kNewTextColor,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, ShopUsersScreen.routeName),
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: kOwnerRoleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildUserActionCard(
                title: 'Add Manager',
                description: 'Register a manager for your shop',
                icon: Icons.admin_panel_settings,
                onTap: () => Navigator.pushNamed(context, RegisterManagerScreen.routeName),
                color: kManagerRoleColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserActionCard(
                title: 'Add Seller',
                description: 'Register a salesperson',
                icon: Icons.person_add,
                onTap: () => Navigator.pushNamed(context, RegisterSalesPersonScreen.routeName),
                color: kSellerRoleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserActionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kNewTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: kNewSecondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 