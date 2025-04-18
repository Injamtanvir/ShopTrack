import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import 'premium_dashboard_screen.dart';

class PremiumSubscriptionScreen extends StatefulWidget {
  static const routeName = '/premium-subscription';
  
  const PremiumSubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<PremiumSubscriptionScreen> createState() => _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionController = TextEditingController();
  bool _isLoading = false;
  bool _showRechargeHistory = false;
  List<dynamic>? _rechargeHistory;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRechargeHistory();
    });
  }
  
  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchRechargeHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isPremium) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final history = await authProvider.getRechargeHistory();
        setState(() {
          _rechargeHistory = history;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  Future<void> _subscribeOrRecharge() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final transactionId = _transactionController.text.trim();
    
    try {
      final success = await authProvider.subscribeToPremium(
        transactionId: transactionId,
      );
      
      if (success && mounted) {
        _transactionController.clear();
        await _fetchRechargeHistory();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium subscription activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to premium dashboard
        if (mounted) {
          Navigator.pushReplacementNamed(context, PremiumDashboardScreen.routeName);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to activate premium subscription. Please check the transaction ID.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isPremium = authProvider.isPremium;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isPremium ? 'Recharge Premium' : 'Premium Subscription'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium header with animation
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 80,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isPremium ? 'Recharge Your Premium Account' : 'Upgrade to Premium',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium 
                                ? 'Recharge your premium account to continue enjoying exclusive features:'
                                : 'Upgrade to premium to unlock exclusive features:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem('Unlimited invoice history storage'),
                          _buildFeatureItem('Multiple branch management'),
                          _buildFeatureItem('Advanced sales analytics'),
                          _buildFeatureItem('Product returns management'),
                          _buildFeatureItem('Custom branding on invoices'),
                          _buildFeatureItem('Email notifications for low stock'),
                          _buildFeatureItem('Priority customer support'),
                          const SizedBox(height: 8),
                          const Text(
                            'Premium costs just ৳5/day for each branch!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Transaction ID form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter Your Transaction ID',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter the transaction ID you received after payment. Your premium access will be activated immediately.',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _transactionController,
                              decoration: InputDecoration(
                                labelText: 'Transaction ID',
                                hintText: 'Example: TXN123456',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.confirmation_number),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a transaction ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: CustomButton(
                                text: isPremium ? 'Recharge Now' : 'Activate Premium',
                                onPressed: _subscribeOrRecharge,
                                color: Colors.amber,
                                width: double.infinity,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Recharge history (only for premium accounts)
                  if (isPremium) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recharge History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showRechargeHistory = !_showRechargeHistory;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Text(
                                  _showRechargeHistory ? 'Hide' : 'Show',
                                  style: const TextStyle(color: Colors.indigo),
                                ),
                                Icon(
                                  _showRechargeHistory 
                                      ? Icons.keyboard_arrow_up 
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.indigo,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showRechargeHistory) ...[
                      const SizedBox(height: 16),
                      if (_rechargeHistory == null || _rechargeHistory!.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text('No recharge history found'),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rechargeHistory!.length,
                          itemBuilder: (context, index) {
                            final recharge = _rechargeHistory![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.payment, color: Colors.green),
                                title: Text('৳${recharge['amount']}'),
                                subtitle: Text('Transaction ID: ${recharge['transaction_id']}'),
                                trailing: Text(_formatDate(recharge['recharged_at'])),
                              ),
                            );
                          },
                        ),
                    ],
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Contact information
                  const Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Contact our support team for assistance:'),
                          SizedBox(height: 4),
                          Text('Email: support@shoptrack.com'),
                          Text('Phone: +880 1234-567890'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
} 