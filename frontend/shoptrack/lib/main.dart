
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
import 'screens/admin_pending_invoice_screen.dart';
import 'screens/daily_tracking_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/shop_users_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
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
      AdminPendingInvoicesScreen.routeName: (ctx) => const AdminPendingInvoicesScreen(),
      DailyTrackingScreen.routeName: (ctx) => const DailyTrackingScreen(),
      OwnerDashboardScreen.routeName: (ctx) => const OwnerDashboardScreen(),
      ShopUsersScreen.routeName: (ctx) => const ShopUsersScreen(),
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

// class _InitScreenState extends State<InitScreen> {
//   bool _initialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await Provider.of<AuthProvider>(context, listen: false).initialize();
//       if (mounted) {
//         setState(() {
//           _initialized = true;
//         });
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_initialized) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     final authProvider = Provider.of<AuthProvider>(context);
//
//     // Debug print to check the user role
//     if (authProvider.isLoggedIn && authProvider.user != null) {
//       print('User Role: ${authProvider.user?.role}');
//       print('User Name: ${authProvider.user?.name}');
//       print('User Email: ${authProvider.user?.email}');
//     }
//
//     if (authProvider.isLoggedIn) {
//       final role = authProvider.user?.role;
//
//       // Improved role check with proper logging
//       if (role == 'owner') {
//         print('Redirecting to Owner Dashboard');
//         return const OwnerDashboardScreen();
//       } else if (role == 'admin') {
//         print('Redirecting to Admin Dashboard');
//         return const AdminHomeScreen();
//       } else {
//         print('Redirecting to Seller Dashboard');
//         return const SellerHomeScreen();
//       }
//     } else {
//       return const LoginScreen();
//     }
//   }
// }


class _InitScreenState extends State<InitScreen> {
  bool _initialized = false;
  bool _initError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Provider.of<AuthProvider>(context, listen: false).initialize();
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _initError = true;
            _errorMessage = e.toString();
            _initialized = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Loading ShopTrack...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_initError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Connection Error",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initialized = false;
                      _initError = false;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      await Provider.of<AuthProvider>(context, listen: false).initialize();
                      if (mounted) {
                        setState(() {
                          _initialized = true;
                        });
                      }
                    });
                  },
                  child: const Text("Retry"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
                  },
                  child: const Text("Go to Login"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);

    // Debug print to check the user role
    if (authProvider.isLoggedIn && authProvider.user != null) {
      print('User Role: ${authProvider.user?.role}');
      print('User Name: ${authProvider.user?.name}');
      print('User Email: ${authProvider.user?.email}');
    }

    if (authProvider.isLoggedIn) {
      final role = authProvider.user?.role;

      // Improved role check with proper logging
      if (role == 'owner') {
        print('Redirecting to Owner Dashboard');
        return const OwnerDashboardScreen();
      } else if (role == 'admin') {
        print('Redirecting to Admin Dashboard');
        return const AdminHomeScreen();
      } else {
        print('Redirecting to Seller Dashboard');
        return const SellerHomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}