// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:provider/provider.dart';
// import 'package:path_provider/path_provider.dart' as path_provider;
// import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// import 'package:path_provider_web/path_provider_web.dart';
//
// import 'providers/auth_provider.dart';
// import 'services/connectivity_service.dart';
//
// import 'screens/admin_home_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/register_admin_screen.dart';
// import 'screens/register_sales_person_screen.dart';
// import 'screens/register_screen.dart';
// import 'screens/seller_home_screen.dart';
// import 'screens/add_product_screen.dart';
// import 'screens/product_list_screen.dart';
// import 'screens/price_list_screen.dart';
// import 'screens/seller_product_list_screen.dart';
// import 'screens/create_invoice_screen.dart';
// import 'screens/pending_invoices_screen.dart';
// import 'screens/invoice_history_screen.dart';
//
// void main() async {
//   // Ensure Flutter is initialized
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Register the web implementation of path_provider
//   if (kIsWeb) {
//     PathProviderPlatform.instance = PathProviderWeb();
//   }
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (ctx) => AuthProvider()),
//         Provider(create: (ctx) => ConnectivityService()),
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'ShopTrack',
//         theme: ThemeData(
//           primarySwatch: Colors.indigo,
//           fontFamily: 'Roboto',
//           appBarTheme: const AppBarTheme(
//             centerTitle: true,
//             elevation: 2,
//           ),
//           elevatedButtonTheme: ElevatedButtonThemeData(
//             style: ElevatedButton.styleFrom(
//               foregroundColor: Colors.white,
//               backgroundColor: Colors.indigo,
//               elevation: 2,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               padding: const EdgeInsets.symmetric(vertical: 12),
//             ),
//           ),
//           inputDecorationTheme: InputDecorationTheme(
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 16,
//             ),
//           ),
//           cardTheme: CardTheme(
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//         home: const InitScreen(),
//         routes: {
//           LoginScreen.routeName: (ctx) => const LoginScreen(),
//           RegisterScreen.routeName: (ctx) => const RegisterScreen(),
//           AdminHomeScreen.routeName: (ctx) => const AdminHomeScreen(),
//           SellerHomeScreen.routeName: (ctx) => const SellerHomeScreen(),
//           RegisterSalesPersonScreen.routeName: (ctx) => const RegisterSalesPersonScreen(),
//           RegisterAdminScreen.routeName: (ctx) => const RegisterAdminScreen(),
//           SellerProductListScreen.routeName: (ctx) => const SellerProductListScreen(),
//           AddProductScreen.routeName: (ctx) => const AddProductScreen(),
//           ProductListScreen.routeName: (ctx) => const ProductListScreen(),
//           PriceListScreen.routeName: (ctx) => const PriceListScreen(),
//           CreateInvoiceScreen.routeName: (ctx) => const CreateInvoiceScreen(),
//           PendingInvoicesScreen.routeName: (ctx) => const PendingInvoicesScreen(),
//           InvoiceHistoryScreen.routeName: (ctx) => const InvoiceHistoryScreen(),
//         },
//       ),
//     );
//   }
// }
//
// class InitScreen extends StatefulWidget {
//   const InitScreen({Key? key}) : super(key: key);
//
//   @override
//   State<InitScreen> createState() => _InitScreenState();
// }
//
// class _InitScreenState extends State<InitScreen> {
//   bool _initialized = false;
//   bool _connectivityChecked = false;
//   bool _isConnected = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     // Check connectivity first
//     final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
//     _isConnected = await connectivityService.isConnected();
//
//     if (mounted) {
//       setState(() {
//         _connectivityChecked = true;
//       });
//     }
//
//     if (_isConnected) {
//       // Initialize auth provider
//       await Provider.of<AuthProvider>(context, listen: false).initialize();
//
//       if (mounted) {
//         setState(() {
//           _initialized = true;
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_connectivityChecked) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     if (!_isConnected) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.signal_wifi_off,
//                 size: 64,
//                 color: Colors.grey,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'No Internet Connection',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Please check your connection and try again',
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _connectivityChecked = false;
//                   });
//                   _initializeApp();
//                 },
//                 child: const Text('Try Again'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     if (!_initialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     final authProvider = Provider.of<AuthProvider>(context);
//     if (authProvider.isLoggedIn) {
//       if (authProvider.isAdmin) {
//         return const AdminHomeScreen();
//       } else {
//         return const SellerHomeScreen();
//       }
//     } else {
//       return const LoginScreen();
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';

import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_admin_screen.dart';
import 'screens/register_sales_person_screen.dart';
import 'screens/register_screen.dart';
import 'screens/seller_home_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/price_list_screen.dart';
import 'screens/seller_product_list_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/pending_invoices_screen.dart';
import 'screens/invoice_history_screen.dart';
import 'constants/api_constants.dart'; // Add this import for ApiConstants

<<<<<<< HEAD
void main() {
  // Enable debug printing for API URLs
  print('ShopTrack Starting...');

  // Print all API endpoints for debugging
  ApiConstants.printEndpoints();
=======
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

>>>>>>> master
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShopTrack',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.indigo,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const InitScreen(),
        routes: {
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          RegisterScreen.routeName: (ctx) => const RegisterScreen(),
          AdminHomeScreen.routeName: (ctx) => const AdminHomeScreen(),
          SellerHomeScreen.routeName: (ctx) => const SellerHomeScreen(),
          RegisterSalesPersonScreen.routeName: (ctx) => const RegisterSalesPersonScreen(),
          RegisterAdminScreen.routeName: (ctx) => const RegisterAdminScreen(),
          SellerProductListScreen.routeName: (ctx) => const SellerProductListScreen(),
          AddProductScreen.routeName: (ctx) => const AddProductScreen(),
          ProductListScreen.routeName: (ctx) => const ProductListScreen(),
          PriceListScreen.routeName: (ctx) => const PriceListScreen(),
          CreateInvoiceScreen.routeName: (ctx) => const CreateInvoiceScreen(),
          PendingInvoicesScreen.routeName: (ctx) => const PendingInvoicesScreen(),
          InvoiceHistoryScreen.routeName: (ctx) => const InvoiceHistoryScreen(),
        },
      ),
    );
  }
}

class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthProvider>(context, listen: false).initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isLoggedIn) {
      if (authProvider.isAdmin) {
        return const AdminHomeScreen();
      } else {
        return const SellerHomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}