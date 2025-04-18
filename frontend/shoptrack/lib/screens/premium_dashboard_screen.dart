import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'branch_management_screen.dart';
import 'premium_analytics_screen.dart';
import 'returned_products_screen.dart';
import 'shop_settings_screen.dart';
import 'premium_subscription_screen.dart';

class PremiumDashboardScreen extends StatefulWidget {
  static const routeName = '/premium-dashboard';
  
  const PremiumDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _premiumStatus;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _premiumStatus = await authProvider.getPremiumStatus();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
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

    // If not premium, show upgrade message
    if (!authProvider.isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Premium Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                'Premium Features',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Upgrade to Premium to access advanced features like Branch Management, Analytics, and more!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Upgrade Now',
                onPressed: () {
                  Navigator.pushNamed(context, PremiumSubscriptionScreen.routeName);
                },
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium status card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 30),
                                const SizedBox(width: 8),
                                Text(
                                  'Premium Status',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _premiumStatus != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatusItem(
                                        'Current Balance',
                                        '৳ ${_premiumStatus!['balance'].toStringAsFixed(2)}',
                                        _premiumStatus!['balance'] < 30 ? Colors.red : Colors.green.shade700,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildStatusItem(
                                        'Premium Until',
                                        _formatDate(_premiumStatus!['premium_until']),
                                        Colors.blue.shade800,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildStatusItem(
                                        'Branches',
                                        _premiumStatus!['branch_count'].toString(),
                                        Colors.purple,
                                      ),
                                      const SizedBox(height: 16),
                                      if (_premiumStatus!['balance'] < 30)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.red.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.red.shade700),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Low balance! Please recharge to avoid service interruption.',
                                                  style: TextStyle(color: Colors.red.shade700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      CustomButton(
                                        text: 'Recharge Balance',
                                        onPressed: () {
                                          Navigator.pushNamed(context, PremiumSubscriptionScreen.routeName);
                                        },
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ],
                                  )
                                : const Text('Error loading premium status'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Premium Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Premium feature grid
                    GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildFeatureCard(
                          'Branch Management',
                          Icons.business,
                          Colors.purple,
                          () => Navigator.pushNamed(context, BranchManagementScreen.routeName),
                        ),
                        _buildFeatureCard(
                          'Advanced Analytics',
                          Icons.bar_chart,
                          Colors.blue,
                          () => Navigator.pushNamed(context, PremiumAnalyticsScreen.routeName),
                        ),
                        _buildFeatureCard(
                          'Returned Products',
                          Icons.assignment_return,
                          Colors.orange,
                          () => Navigator.pushNamed(context, ReturnedProductsScreen.routeName),
                        ),
                        _buildFeatureCard(
                          'Shop Settings',
                          Icons.settings,
                          Colors.teal,
                          () => Navigator.pushNamed(context, ShopSettingsScreen.routeName),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Premium Benefits',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Benefits list
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildBenefitItem(
                              'Unlimited Invoice History',
                              'Access complete history of all sales and transactions',
                              Icons.history,
                            ),
                            const Divider(),
                            _buildBenefitItem(
                              'Multiple Branches',
                              'Manage multiple store locations with ease',
                              Icons.store,
                            ),
                            const Divider(),
                            _buildBenefitItem(
                              'Sales Analytics',
                              'Advanced analytics to track sales performance',
                              Icons.insights,
                            ),
                            const Divider(),
                            _buildBenefitItem(
                              'Product Returns',
                              'Efficiently track and manage returned products',
                              Icons.assignment_return,
                            ),
                            const Divider(),
                            _buildBenefitItem(
                              'Custom Branding',
                              'Add your shop logo to invoices and receipts',
                              Icons.branding_watermark,
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

  Widget _buildStatusItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (date.year == now.year) {
        return '${date.day} ${_getMonth(date.month)}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
} 