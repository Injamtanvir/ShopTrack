// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import 'login_screen.dart';
// import 'add_product_screen.dart';
// import 'product_list_screen.dart';
// import 'price_list_screen.dart';
//
// class SellerHomeScreen extends StatelessWidget {
//   static const routeName = '/seller-home';
//
//   const SellerHomeScreen({Key? key}) : super(key: key);
//
//   Future<void> _logout(BuildContext context) async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     await authProvider.logout();
//     if (context.mounted) {
//       Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final user = authProvider.user;
//
//     if (user == null) {
//       Future.microtask(() {
//         if (context.mounted) {
//           Navigator.pushReplacementNamed(context, LoginScreen.routeName);
//         }
//       });
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         // title: const Text('Sales Dashboard'),
//         title: Text('${user.shopName} Dashboard'),
//         backgroundColor: Colors.indigo,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () => _logout(context),
//             tooltip: 'Logout',
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Welcome header
//               Card(
//                 elevation: 4,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Welcome, ${user.name}',
//                         style: const TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Shop: ${user.shopName}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Shop ID: ${user.shopId}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Email: ${user.email}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Designation: ${user.designation}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Seller ID: ${user.sellerId}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       const Text(
//                         'Role: Sales Person',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),
//
//               // Seller actions - Placeholder for future features
//               const Text(
//                 'Sales Operations',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Placeholder card for future features
//               Card(
//                 elevation: 2,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'Features Coming Soon',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'This section is prepared for future sales operations that will be added to the application.',
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildFeaturePlaceholder(
//                             Icons.shopping_cart,
//                             'New Sale',
//                             Colors.green,
//                           ),
//                           _buildFeaturePlaceholder(
//                             Icons.history,
//                             'Sale History',
//                             Colors.blue,
//                           ),
//                           _buildFeaturePlaceholder(
//                             Icons.people,
//                             'Customers',
//                             Colors.orange,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildFeaturePlaceholder(
//                             Icons.inventory_2,
//                             'Products',
//                             Colors.purple,
//                           ),
//                           _buildFeaturePlaceholder(
//                             Icons.receipt_long,
//                             'Invoices',
//                             Colors.brown,
//                           ),
//                           _buildFeaturePlaceholder(
//                             Icons.support_agent,
//                             'Support',
//                             Colors.teal,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 32),
//
//               // Daily summary section - placeholder
//               const Text(
//                 'Today\'s Summary',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Summary cards
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildSummaryCard(
//                       'Sales',
//                       '0',
//                       Icons.trending_up,
//                       Colors.green,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildSummaryCard(
//                       'Revenue',
//                       '\$0.00',
//                       Icons.attach_money,
//                       Colors.blue,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeaturePlaceholder(IconData icon, String label, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withAlpha(50), // 50 is approximately 0.2 * 255
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             color: color,
//             size: 24,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           label,
//           style: const TextStyle(
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     // color: color.withOpacity(0.2),
//                     color: color.withAlpha((255 * 0.2).toInt()),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     icon,
//                     color: color,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//




import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
// import 'add_product_screen.dart';
import 'product_list_screen.dart';
import 'price_list_screen.dart';

class SellerHomeScreen extends StatelessWidget {
  static const routeName = '/seller-home';

  const SellerHomeScreen({Key? key}) : super(key: key);

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

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.shopName} Dashboard'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user.name}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shop: ${user.shopName}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Shop ID: ${user.shopId}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${user.email}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Designation: ${user.designation}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seller ID: ${user.sellerId}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Role: Sales Person',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Product Management
              const Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Product-related cards
              Row(
                children: [
                  // Product List Card
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, ProductListScreen.routeName);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.inventory,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Product List',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'View all products',
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Price List Card
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, PriceListScreen.routeName);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(50),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: Colors.orange,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Price List',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'View and share price list',
                                style: TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Seller actions - Placeholder for future features
              const Text(
                'Sales Operations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Placeholder card for future features
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
                      const Text(
                        'Features Coming Soon',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This section is prepared for future sales operations that will be added to the application.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeaturePlaceholder(
                            Icons.shopping_cart,
                            'New Sale',
                            Colors.green,
                          ),
                          _buildFeaturePlaceholder(
                            Icons.history,
                            'Sale History',
                            Colors.blue,
                          ),
                          _buildFeaturePlaceholder(
                            Icons.people,
                            'Customers',
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeaturePlaceholder(
                            Icons.receipt_long,
                            'Invoices',
                            Colors.brown,
                          ),
                          _buildFeaturePlaceholder(
                            Icons.support_agent,
                            'Support',
                            Colors.teal,
                          ),
                          _buildFeaturePlaceholder(
                            Icons.analytics,
                            'Analytics',
                            Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Daily summary section - placeholder
              const Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Sales',
                      '0',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Revenue',
                      '\$0.00',
                      Icons.attach_money,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePlaceholder(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(50), // 50 is approximately 0.2 * 255
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha((255 * 0.2).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}