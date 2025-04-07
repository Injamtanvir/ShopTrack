// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../widgets/custom_button.dart';
// import '../widgets/custom_text_field.dart';
// import 'login_screen.dart';
// import 'package:flutter/services.dart';
//
//
// class RegisterScreen extends StatefulWidget {
//   static const routeName = '/register';
//
//   const RegisterScreen({Key? key}) : super(key: key);
//
//   @override
//   State<RegisterScreen> createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _shopNameController = TextEditingController();
//   final _shopAddressController = TextEditingController();
//   final _ownerNameController = TextEditingController();
//   final _licenseNumberController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;
//   String? _generatedShopId;
//
//   @override
//   void dispose() {
//     _shopNameController.dispose();
//     _shopAddressController.dispose();
//     _ownerNameController.dispose();
//     _licenseNumberController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//
//     final shopId = await authProvider.registerShop(
//       name: _shopNameController.text.trim(),
//       address: _shopAddressController.text.trim(),
//       ownerName: _ownerNameController.text.trim(),
//       licenseNumber: _licenseNumberController.text.trim(),
//       email: _emailController.text.trim(),
//       password: _passwordController.text,
//       confirmPassword: _confirmPasswordController.text,
//     );
//
//     if (shopId != null) {
//       setState(() {
//         _generatedShopId = shopId;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);
//     if (_generatedShopId != null) {
//       return Scaffold(
//         body: SafeArea(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.check_circle_outline,
//                     color: Colors.green,
//                     size: 80,
//                   ),
//                   const SizedBox(height: 24),
//                   const Text(
//                     'Registration Successful!',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   const Text(
//                     'Your shop has been registered successfully.',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 32),
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.indigo.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.indigo.shade200),
//                     ),
//                     child: Column(
//                       children: [
//                         const Text(
//                           'Your Shop ID',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Color(0xFF1A237E),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               _generatedShopId!,
//                               style: const TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 2,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             IconButton(
//                               icon: const Icon(Icons.copy),
//                               onPressed: () {
//                                 Clipboard.setData(
//                                   ClipboardData(text: _generatedShopId!),
//                                 );
//                               },
//                               tooltip: 'Copy to Clipboard',
//                               padding: EdgeInsets.zero,
//                               iconSize: 28,
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           'Please save this Shop ID. You will need it to login.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.red,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),
//                   CustomButton(
//                     text: 'Proceed to Login',
//                     onPressed: () {
//                       Navigator.pushReplacementNamed(
//                           context, LoginScreen.routeName);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//
//
//
// // Show registration form
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Register Shop'),
//         backgroundColor: Colors.indigo,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Error message if any
//                 if (authProvider.errorMessage != null)
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade100,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.red.shade300),
//                     ),
//                     child: Text(
//                       authProvider.errorMessage!,
//                       style: TextStyle(color: Colors.red.shade800),
//                     ),
//                   ),
//                 // Shop information
//                 const Text(
//                   'Shop Information',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Shop Name
//                 CustomTextField(
//                   label: 'Shop Name',
//                   controller: _shopNameController,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter shop name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 // Shop Address
//                 CustomTextField(
//                   label: 'Shop Address',
//                   controller: _shopAddressController,
//                   maxLines: 2,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter shop address';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 // Owner Name
//                 CustomTextField(
//                   label: 'Owner Name',
//                   controller: _ownerNameController,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter owner name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 // License Number
//                 CustomTextField(
//                   label: 'License Number',
//                   controller: _licenseNumberController,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter license number';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 32),
//                 // User information
//                 const Text(
//                   'Account Information',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Email
//                 CustomTextField(
//                   label: 'Email',
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter email';
//                     }
//                     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(
//                         value)) {
//                       return 'Please enter a valid email';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 // Password
//                 CustomTextField(
//                   label: 'Password',
//                   controller: _passwordController,
//                   obscureText: _obscurePassword,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter password';
//                     }
//                     if (value.length < 6) {
//                       return 'Password must be at least 6 characters';
//                     }
//                     return null;
//                   },
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword ? Icons.visibility_off : Icons
//                           .visibility,
//                       color: Colors.grey,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       });
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 // Confirm Password
//                 CustomTextField(
//                   label: 'Confirm Password',
//                   controller: _confirmPasswordController,
//                   obscureText: _obscureConfirmPassword,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please confirm password';
//                     }
//                     if (value != _passwordController.text) {
//                       return 'Passwords do not match';
//                     }
//                     return null;
//                   },
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureConfirmPassword ? Icons.visibility_off : Icons
//                           .visibility,
//                       color: Colors.grey,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscureConfirmPassword = !_obscureConfirmPassword;
//                       });
//                     },
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 // Register button
//                 CustomButton(
//                   text: 'Register Shop',
//                   onPressed: _register,
//                   isLoading: authProvider.isLoading,
//                 ),
//                 const SizedBox(height: 16),
//                 // Login link
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Already have an account?'),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pushReplacementNamed(
//                             context, LoginScreen.routeName);
//                       },
//                       child: const Text('Login'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }







import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _generatedShopId;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _ownerNameController.dispose();
    _licenseNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final shopId = await authProvider.registerShop(
        name: _shopNameController.text.trim(),
        address: _shopAddressController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        licenseNumber: _licenseNumberController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (shopId != null && mounted) {
        setState(() {
          _generatedShopId = shopId;
          _isLoading = false;
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: Unable to connect to the server. Please check your internet connection.';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Network timeout: The server took too long to respond. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_generatedShopId != null) {
      return Scaffold(
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
                    'Your shop has been registered successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Shop ID',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _generatedShopId!,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: _generatedShopId!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Shop ID copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy to Clipboard',
                              padding: EdgeInsets.zero,
                              iconSize: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please save this Shop ID. You will need it to login.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'Proceed to Login',
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, LoginScreen.routeName);
                    },
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
        title: const Text('Register Shop'),
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

                // Show auth provider error if any
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

                // Shop information
                const Text(
                  'Shop Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Shop Name
                CustomTextField(
                  label: 'Shop Name',
                  controller: _shopNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shop name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Shop Address
                CustomTextField(
                  label: 'Shop Address',
                  controller: _shopAddressController,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shop address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Owner Name
                CustomTextField(
                  label: 'Owner Name',
                  controller: _ownerNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter owner name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // License Number
                CustomTextField(
                  label: 'License Number',
                  controller: _licenseNumberController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter license number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // User information
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(
                        value)) {
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
                      _obscurePassword ? Icons.visibility_off : Icons
                          .visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons
                          .visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                // Register button
                CustomButton(
                  text: 'Register Shop',
                  onPressed: _register,
                  isLoading: _isLoading || authProvider.isLoading,
                ),
                const SizedBox(height: 16),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                            context, LoginScreen.routeName);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}