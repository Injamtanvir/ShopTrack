import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/dashboard_header.dart';
import '../constants/theme_constants.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/custom_bottom_nav.dart';
import 'login_screen.dart';
import 'register_sales_person_screen.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'price_list_screen.dart';
import 'create_invoice_screen.dart';
import 'admin_pending_invoice_screen.dart';
import 'invoice_history_screen.dart';
import 'daily_tracking_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  static const routeName = '/admin-home';
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentNavIndex = 0;
  
  // Mock data for statistics
  final Map<String, double> _statsData = {
    'todaySales': 2800.00,
    'stockValue': 95000.00,
    'pendingOrders': 2,
  };

  @override
  void initState() {
    super.initState();
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
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kNewTextColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kNewTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Today Sales',
            '\$${_statsData['todaySales']?.toStringAsFixed(2) ?? '0.00'}',
            kManagerRoleColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Stock Value',
            '\$${_statsData['stockValue']?.toStringAsFixed(2) ?? '0.00'}',
            kSalesColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: kNewTextColor,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kNewTextColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, DailyTrackingScreen.routeName);
              },
              child: const Text('Analytics',
                  style: TextStyle(color: kManagerRoleColor)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildQuickAction(
          title: 'Add New Product',
          icon: Icons.add_circle_outline,
          color: kProductsColor,
          onTap: () => Navigator.pushNamed(context, AddProductScreen.routeName),
        ),
        const SizedBox(height: 12),
        _buildQuickAction(
          title: 'Create Invoice',
          icon: Icons.receipt_long_outlined,
          color: kInvoiceColor,
          onTap: () => Navigator.pushNamed(context, CreateInvoiceScreen.routeName),
        ),
        const SizedBox(height: 12),
        _buildQuickAction(
          title: 'Add Sales Person',
          icon: Icons.person_add_outlined,
          color: kSellerRoleColor,
          onTap: () => Navigator.pushNamed(context, RegisterSalesPersonScreen.routeName),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kNewTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: kNewTextColor.withOpacity(0.6),
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
          'Manage Your Shop',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: 'Product List',
                description: 'View all products',
                icon: Icons.inventory_2_outlined,
                color: kProductsColor,
                onTap: () => Navigator.pushNamed(context, ProductListScreen.routeName),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                title: 'Price List',
                description: 'View and share price list',
                icon: Icons.list_alt_outlined,
                color: kPriceColor,
                onTap: () => Navigator.pushNamed(context, PriceListScreen.routeName),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: 'Pending Invoices',
                description: 'Manage pending orders',
                icon: Icons.pending_actions_outlined,
                color: kPendingColor,
                onTap: () => Navigator.pushNamed(context, AdminPendingInvoicesScreen.routeName),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                title: 'Invoice History',
                description: 'View all completed invoices',
                icon: Icons.history_outlined,
                color: kHistoryColor,
                onTap: () => Navigator.pushNamed(context, InvoiceHistoryScreen.routeName),
              ),
            ),
          ],
        ),
      ],
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
                  designation: 'MANAGER',
                  shopId: user.shopId,
                  notificationCount: 0,
                ),
                
                const SizedBox(height: 24),
                
                // Stats Summary
                _buildStatsSummary(),
                
                const SizedBox(height: 24),
                
                // Quick Actions
                _buildQuickActions(),
                
                const SizedBox(height: 24),
                
                // Main Feature Grid
                _buildMainFeatureGrid(),
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
}