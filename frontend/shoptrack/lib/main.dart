import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/user_provider.dart';
import 'services/connectivity_service.dart';
import 'models/batch.dart';

import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_manager_screen.dart';
import 'screens/register_sales_person_screen.dart';
import 'screens/register_screen.dart';
import 'screens/seller_home_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/shop_users_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/price_list_screen.dart';
import 'screens/seller_product_list_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/pending_invoices_screen.dart';
import 'screens/invoice_history_screen.dart';
import 'screens/admin_pending_invoice_screen.dart';
import 'screens/daily_tracking_screen.dart';
import 'screens/batch_history_screen.dart';




void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create the connectivity service as a singleton
  final connectivityService = ConnectivityService();

  runApp(MyApp(connectivityService: connectivityService));
}

class MyApp extends StatelessWidget {
  final ConnectivityService connectivityService;
  
  const MyApp({Key? key, required this.connectivityService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ConnectivityProvider(connectivityService)),
        ChangeNotifierProvider(create: (ctx) => UserProvider()),
      ],
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
          RegisterManagerScreen.routeName: (ctx) => const RegisterManagerScreen(),
          SellerProductListScreen.routeName: (ctx) => const SellerProductListScreen(),
          AddProductScreen.routeName: (ctx) => const AddProductScreen(),
          ProductListScreen.routeName: (ctx) => const ProductListScreen(),
          PriceListScreen.routeName: (ctx) => const PriceListScreen(),
          CreateInvoiceScreen.routeName: (ctx) => const CreateInvoiceScreen(),
          PendingInvoicesScreen.routeName: (ctx) => const PendingInvoicesScreen(),
          InvoiceHistoryScreen.routeName: (ctx) => const InvoiceHistoryScreen(),
          AdminPendingInvoicesScreen.routeName: (ctx) => const AdminPendingInvoicesScreen(),
          // Then add this to your routes map in the MaterialApp widget
          DailyTrackingScreen.routeName: (ctx) => const DailyTrackingScreen(),
          OwnerHomeScreen.routeName: (ctx) => const OwnerHomeScreen(),
          ShopUsersScreen.routeName: (ctx) => const ShopUsersScreen(),
          BatchHistoryScreen.routeName: (ctx) => const BatchHistoryScreen(productId: '', productName: '', batches: <Batch>[]),
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      await authProvider.initialize();
      
      // If user is logged in, sync with UserProvider
      if (authProvider.isLoggedIn && authProvider.user != null) {
        userProvider.setUser(authProvider.user!);
      }
      
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
      if (authProvider.isOwner) {
        return const OwnerHomeScreen();
      } else if (authProvider.isManager) {
        return const AdminHomeScreen();
      } else {
        return const SellerHomeScreen();
      }
    } else {
      return const LoginScreen();
    }
  }
}