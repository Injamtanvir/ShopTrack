// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../services/api_service.dart';
// import '../models/user.dart';
// import '../widgets/custom_button.dart';
//
// class ShopUsersScreen extends StatefulWidget {
//   static const routeName = '/shop-users';
//   const ShopUsersScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ShopUsersScreen> createState() => _ShopUsersScreenState();
// }
//
// class _ShopUsersScreenState extends State<ShopUsersScreen> {
//   final ApiService _apiService = ApiService();
//   List<User> _shopUsers = [];
//   bool _isLoading = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadShopUsers();
//   }
//
//   Future<void> _loadShopUsers() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final shopId = authProvider.user!.shopId;
//
//       final users = await _apiService.getShopUsers(shopId);
//
//       setState(() {
//         _shopUsers = users;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _deleteUser(String userId, String role, String email) async {
//     // Confirmation dialog
//     final bool confirm = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete ${role == 'admin' ? 'Admin' : 'Sales Person'}?'),
//           content: Text(
//             'Are you sure you want to delete $email?\n\nThis action cannot be undone.',
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: const Text('Delete'),
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     ) ?? false;
//
//     if (!confirm) return;
//
//     // Process deletion
//     try {
//       setState(() {
//         _isLoading = true;
//       });
//
//       await _apiService.deleteUser(userId);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('${role == 'admin' ? 'Admin' : 'Sales Person'} deleted successfully')),
//       );
//
//       _loadShopUsers(); // Refresh the list
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     final currentUser = authProvider.user;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Shop Users'),
//         backgroundColor: Colors.indigo,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadShopUsers,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage != null
//           ? Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Error: $_errorMessage',
//                 style: const TextStyle(color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               CustomButton(
//                 text: 'Retry',
//                 onPressed: _loadShopUsers,
//               ),
//             ],
//           ),
//         ),
//       )
//           : _shopUsers.isEmpty
//           ? const Center(child: Text('No users found.'))
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Manage Users',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'View and delete users associated with your shop',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _shopUsers.length,
//                 itemBuilder: (context, index) {
//                   final userData = _shopUsers[index];
//                   final bool isCurrentUser = userData.email == currentUser?.email;
//
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: ListTile(
//                       contentPadding: const EdgeInsets.all(16),
//                       leading: CircleAvatar(
//                         backgroundColor: userData.role == 'admin'
//                             ? Colors.purple.shade100
//                             : userData.role == 'owner'
//                             ? Colors.green.shade100
//                             : Colors.blue.shade100,
//                         radius: 28,
//                         child: Icon(
//                           userData.role == 'admin'
//                               ? Icons.admin_panel_settings
//                               : userData.role == 'owner'
//                               ? Icons.person_pin
//                               : Icons.person,
//                           color: userData.role == 'admin'
//                               ? Colors.purple
//                               : userData.role == 'owner'
//                               ? Colors.green
//                               : Colors.blue,
//                           size: 28,
//                         ),
//                       ),
//                       title: Text(
//                         userData.name,
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               const Icon(Icons.email, size: 16, color: Colors.grey),
//                               const SizedBox(width: 8),
//                               Text(userData.email),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Icon(
//                                 userData.role == 'admin'
//                                     ? Icons.admin_panel_settings
//                                     : userData.role == 'owner'
//                                     ? Icons.person_pin
//                                     : Icons.person,
//                                 size: 16,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(width: 8),
//                               Text(
//                                 userData.role == 'admin'
//                                     ? 'Admin'
//                                     : userData.role == 'owner'
//                                     ? 'Owner'
//                                     : 'Sales Person',
//                                 style: TextStyle(
//                                   color: userData.role == 'admin'
//                                       ? Colors.purple.shade700
//                                       : userData.role == 'owner'
//                                       ? Colors.green.shade700
//                                       : Colors.blue.shade700,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           if (userData.role == 'seller' && userData.designation != null)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 4),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.work, size: 16, color: Colors.grey),
//                                   const SizedBox(width: 8),
//                                   Text('Designation: ${userData.designation}'),
//                                 ],
//                               ),
//                             ),
//                           if (userData.role == 'seller' && userData.sellerId != null)
//                             Padding(
//                               padding: const EdgeInsets.only(top: 4),
//                               child: Row(
//                                 children: [
//                                   const Icon(Icons.badge, size: 16, color: Colors.grey),
//                                   const SizedBox(width: 8),
//                                   Text('ID: ${userData.sellerId}'),
//                                 ],
//                               ),
//                             ),
//                         ],
//                       ),
//                       trailing: isCurrentUser || userData.role == 'owner'
//                           ? Chip(
//                         label: Text(
//                           isCurrentUser ? 'You' : 'Owner',
//                         ),
//                         backgroundColor: isCurrentUser
//                             ? Colors.grey
//                             : Colors.green,
//                         labelStyle: const TextStyle(
//                           color: Colors.white,
//                         ),
//                       )
//                           : ElevatedButton.icon(
//                         icon: const Icon(Icons.delete, size: 18),
//                         label: const Text('Delete'),
//                         onPressed: () => _deleteUser(
//                             userData.id!,
//                             userData.role,
//                             userData.email
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                         ),
//                       ),
//                       isThreeLine: true,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton.extended(
//             heroTag: 'registerSalesPerson',
//             icon: const Icon(Icons.person_add),
//             label: const Text('Add Sales Person'),
//             onPressed: () {
//               Navigator.pushNamed(context, '/register-sales-person');
//             },
//             backgroundColor: Colors.blue,
//           ),
//           const SizedBox(height: 16),
//           FloatingActionButton.extended(
//             heroTag: 'registerAdmin',
//             icon: const Icon(Icons.admin_panel_settings),
//             label: const Text('Add Admin'),
//             onPressed: () {
//               Navigator.pushNamed(context, '/register-admin');
//             },
//             backgroundColor: Colors.purple,
//           ),
//         ],
//       ),
//     );
//   }
// }







import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../widgets/custom_button.dart';
import 'register_sales_person_screen.dart';
import 'register_admin_screen.dart';

class ShopUsersScreen extends StatefulWidget {
  static const routeName = '/shop-users';
  const ShopUsersScreen({Key? key}) : super(key: key);

  @override
  State<ShopUsersScreen> createState() => _ShopUsersScreenState();
}

class _ShopUsersScreenState extends State<ShopUsersScreen> {
  final ApiService _apiService = ApiService();
  List<User> _shopUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShopUsers();
  }

  Future<void> _loadShopUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = authProvider.user!.shopId;

      print('Loading shop users for shop ID: $shopId');

      // Get raw data from API
      final response = await _apiService.getShopUsersRaw(shopId);

      // Convert the raw data to User objects
      final List<User> users = [];
      for (var userData in response) {
        try {
          users.add(User.fromJson(userData));
        } catch (e) {
          print('Error converting user data: $e');
          // Continue with next user if one fails
        }
      }

      setState(() {
        _shopUsers = users;
        _isLoading = false;
      });

      // Print loaded users for debugging
      print('Loaded ${_shopUsers.length} shop users');
      for (var user in _shopUsers) {
        print('User: ${user.name}, Role: ${user.role}, Email: ${user.email}');
      }
    } on SocketException {
      setState(() {
        _errorMessage = 'Network error: Unable to connect to the server. Please check your internet connection.';
        _isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Network timeout: The server took too long to respond. Please try again later.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading shop users: $_errorMessage');
    }
  }

  Future<void> _deleteUser(String userId, String role, String email) async {
    // Confirmation dialog
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete ${role == 'admin' ? 'Admin' : 'Sales Person'}?'),
          content: Text(
            'Are you sure you want to delete $email?\n\nThis action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    // Process deletion
    try {
      setState(() {
        _isLoading = true;
      });

      await _apiService.deleteUser(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${role == 'admin' ? 'Admin' : 'Sales Person'} deleted successfully')),
      );

      _loadShopUsers(); // Refresh the list
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Users'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShopUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Retry',
                onPressed: _loadShopUsers,
              ),
            ],
          ),
        ),
      )
          : _shopUsers.isEmpty
          ? const Center(child: Text('No users found.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'View and delete users associated with your shop',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _shopUsers.length,
                itemBuilder: (context, index) {
                  final userData = _shopUsers[index];
                  final bool isCurrentUser = userData.email == currentUser?.email;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: userData.role == 'admin'
                            ? Colors.purple.shade100
                            : userData.role == 'owner'
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                        radius: 28,
                        child: Icon(
                          userData.role == 'admin'
                              ? Icons.admin_panel_settings
                              : userData.role == 'owner'
                              ? Icons.person_pin
                              : Icons.person,
                          color: userData.role == 'admin'
                              ? Colors.purple
                              : userData.role == 'owner'
                              ? Colors.green
                              : Colors.blue,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        userData.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(userData.email),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                userData.role == 'admin'
                                    ? Icons.admin_panel_settings
                                    : userData.role == 'owner'
                                    ? Icons.person_pin
                                    : Icons.person,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userData.role == 'admin'
                                    ? 'Admin'
                                    : userData.role == 'owner'
                                    ? 'Owner'
                                    : 'Sales Person',
                                style: TextStyle(
                                  color: userData.role == 'admin'
                                      ? Colors.purple.shade700
                                      : userData.role == 'owner'
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (userData.role == 'seller' && userData.designation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.work, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('Designation: ${userData.designation}'),
                                ],
                              ),
                            ),
                          if (userData.role == 'seller' && userData.sellerId != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.badge, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('ID: ${userData.sellerId}'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: isCurrentUser || userData.role == 'owner'
                          ? Chip(
                        label: Text(
                          isCurrentUser ? 'You' : 'Owner',
                        ),
                        backgroundColor: isCurrentUser
                            ? Colors.grey
                            : Colors.green,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                        ),
                      )
                          : ElevatedButton.icon(
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        onPressed: () => _deleteUser(
                            userData.id!,
                            userData.role,
                            userData.email
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'registerSalesPerson',
            icon: const Icon(Icons.person_add),
            label: const Text('Add Sales Person'),
            onPressed: () {
              Navigator.pushNamed(context, RegisterSalesPersonScreen.routeName);
            },
            backgroundColor: Colors.blue,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'registerAdmin',
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Add Admin'),
            onPressed: () {
              Navigator.pushNamed(context, RegisterAdminScreen.routeName);
            },
            backgroundColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}