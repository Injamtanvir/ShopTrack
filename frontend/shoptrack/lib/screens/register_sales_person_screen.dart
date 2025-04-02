import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterSalesPersonScreen extends StatefulWidget {
  static const routeName = '/register-sales-person';

  const RegisterSalesPersonScreen({Key? key}) : super(key: key);

  @override
  State<RegisterSalesPersonScreen> createState() => _RegisterSalesPersonScreenState();
}

class _RegisterSalesPersonScreenState extends State<RegisterSalesPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _sellerIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _registrationSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _sellerIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerSalesPerson() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.registerSalesPerson(
      name: _nameController.text.trim(),
      designation: _designationController.text.trim(),
      sellerId: _sellerIdController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success) {
      setState(() {
        _registrationSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_registrationSuccess) {
      // Show success screen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sales Person Registration'),
          backgroundColor: Colors.indigo,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Registration Successful!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The sales person has been registered successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),

                  // Back to admin home button
                  CustomButton(
                    text: 'Back to Dashboard',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Add another sales person button
                  CustomButton(
                    text: 'Register Another Sales Person',
                    onPressed: () {
                      setState(() {
                        _registrationSuccess = false;
                        _nameController.clear();
                        _designationController.clear();
                        _sellerIdController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                    color: Colors.indigoAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show registration form
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Sales Person'),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message if any
                if (authProvider.errorMessage != null)
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

                // Sales Person information
                const Text(
                  'Sales Person Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Designation
                CustomTextField(
                  label: 'Designation',
                  controller: _designationController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter designation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Seller ID
                CustomTextField(
                  label: 'Seller ID Number',
                  controller: _sellerIdController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter seller ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Account information
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
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
                const SizedBox(height: 32),

                // Register button
                CustomButton(
                  text: 'Register Sales Person',
                  onPressed: _registerSalesPerson,
                  isLoading: authProvider.isLoading,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}