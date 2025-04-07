// Back to previous kindly get it from Github website





import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'admin_home_screen.dart';
import 'register_screen.dart';
import 'seller_home_screen.dart';
import 'owner_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _shopIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        shopId: _shopIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        // Navigate based on user role
        final role = authProvider.user?.role;
        print('Login successful. User role: $role');

        if (role == 'owner') {
          print('Redirecting to Owner Dashboard');
          Navigator.pushReplacementNamed(context, OwnerDashboardScreen.routeName);
        } else if (role == 'admin') {
          print('Redirecting to Admin Dashboard');
          Navigator.pushReplacementNamed(context, AdminHomeScreen.routeName);
        } else {
          print('Redirecting to Seller Dashboard');
          Navigator.pushReplacementNamed(context, SellerHomeScreen.routeName);
        }
      } else if (authProvider.errorMessage != null) {
        setState(() {
          _errorMessage = authProvider.errorMessage;
        });
      }
    } on SocketException {
      setState(() {
        _errorMessage = 'Network error: Unable to connect to the server. Please check your internet connection.';
      });
    } on TimeoutException {
      setState(() {
        _errorMessage = 'Network timeout: The server took too long to respond. Please try again later.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      print('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Title
                  const Text(
                    'ShopTrack',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to your shop account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Error message if any
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  // Auth provider error message if any
                  if (authProvider.errorMessage != null && _errorMessage == null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  // Shop ID field
                  CustomTextField(
                    label: 'Shop ID',
                    controller: _shopIdController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter shop ID';
                      }
                      if (value.length != 8) {
                        return 'Shop ID must be 8 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  CustomButton(
                    text: 'Login',
                    onPressed: _login,
                    isLoading: _isLoading || authProvider.isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have a shop account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, RegisterScreen.routeName);
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}