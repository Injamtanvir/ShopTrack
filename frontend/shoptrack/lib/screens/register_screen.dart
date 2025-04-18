import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'otp_verification_screen.dart';
import '../utils/image_utils.dart';
import '../utils/platform_utils.dart';

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
  final _mobileNumberController = TextEditingController();
  final _nidNumberController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _generatedShopId;
  String? _errorMessage;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  int _currentStep = 0;
  
  // Steps: 
  // 0 - Shop Information
  // 1 - Owner Information
  // 2 - Account Information

  // Mobile number formatter
  final _mobileFormatter = MaskTextInputFormatter(
    mask: '+880 ### ### ####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  
  // NID formatter
  final _nidFormatter = MaskTextInputFormatter(
    mask: '#### #### ####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _ownerNameController.dispose();
    _licenseNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileNumberController.dispose();
    _nidNumberController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      // Validate shop information
      if (_shopNameController.text.trim().isEmpty) {
        _showError('Shop name is required');
        return false;
      }
      if (_shopAddressController.text.trim().isEmpty) {
        _showError('Shop address is required');
        return false;
      }
      if (_licenseNumberController.text.trim().isEmpty) {
        _showError('License number is required');
        return false;
      }
    } else if (_currentStep == 1) {
      // Validate owner information
      if (_ownerNameController.text.trim().isEmpty) {
        _showError('Owner name is required');
        return false;
      }
      if (_mobileNumberController.text.isEmpty || 
          _mobileNumberController.text.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
        _showError('Please enter a valid mobile number');
        return false;
      }
      if (_nidNumberController.text.isEmpty) {
        _showError('Please enter NID number');
        return false;
      }
      // Simplified NID validation - just check if it has at least 5 digits
      if (!RegExp(r'[0-9]{5,}').hasMatch(_nidNumberController.text.replaceAll(RegExp(r'[^0-9]'), ''))) {
        _showError('Please enter at least 5 digits for NID number');
        return false;
      }
    } else if (_currentStep == 2) {
      // Validate account information
      if (_emailController.text.trim().isEmpty) {
        _showError('Email is required');
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
        _showError('Please enter a valid email address');
        return false;
      }
      if (_passwordController.text.isEmpty) {
        _showError('Password is required');
        return false;
      }
      if (_passwordController.text.length < 6) {
        _showError('Password must be at least 6 characters');
        return false;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return false;
      }
      if (!_agreeToTerms) {
        _showError('You must agree to the terms and conditions');
        return false;
      }
    }
    
    return true;
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        _errorMessage = null;
        if (_currentStep < 2) {
          _currentStep++;
        } else {
          _proceedToOTP();
        }
      });
    }
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _proceedToOTP() {
    if (!_validateCurrentStep()) {
      return;
    }
    
    // Get mobile number and ensure it has the country code
    String mobileNumber = _mobileNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    // Make sure it has the country code (880 for Bangladesh)
    if (!mobileNumber.startsWith('880')) {
      // If it starts with 0, replace it with 880
      if (mobileNumber.startsWith('0')) {
        mobileNumber = '88' + mobileNumber;
      } else {
        // Otherwise, add 880 prefix
        mobileNumber = '880' + mobileNumber;
      }
    }

    // Get NID number and ensure it's not empty
    String nidNumber = _nidNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    // If NID is empty, provide a default test value
    if (nidNumber.isEmpty) {
      nidNumber = "12345678901"; // Default test NID number
    }
    
    // Create registration data map to pass to OTP screen
    final registrationData = {
      'shopName': _shopNameController.text.trim(),
      'shopAddress': _shopAddressController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'licenseNumber': _licenseNumberController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'mobileNumber': mobileNumber,
      'nidNumber': nidNumber,
    };
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerificationScreen(
          email: _emailController.text.trim(),
          registrationData: registrationData,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          _buildStepCircle(0, 'Shop'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Owner'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Account'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDone ? Colors.green : (isActive ? Colors.indigo : Colors.grey.shade300),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isDone 
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    (step + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.indigo : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isDone = _currentStep > step;
    return Container(
      width: 24,
      height: 2,
      color: isDone ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildShopInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _shopNameController,
          decoration: InputDecoration(
            labelText: 'Shop Name',
            hintText: 'Enter your shop name',
            prefixIcon: const Icon(Icons.store, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter shop name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _shopAddressController,
          decoration: InputDecoration(
            labelText: 'Shop Address',
            hintText: 'Enter your shop address',
            prefixIcon: const Icon(Icons.location_on, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter shop address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _licenseNumberController,
          decoration: InputDecoration(
            labelText: 'License Number',
            hintText: 'Enter your business license number',
            prefixIcon: const Icon(Icons.badge, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter license number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOwnerInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Owner Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ownerNameController,
          decoration: InputDecoration(
            labelText: 'Owner Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter owner name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileNumberController,
          keyboardType: TextInputType.phone,
          inputFormatters: [_mobileFormatter],
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: '+880 1XX XXX XXXX',
            prefixIcon: const Icon(Icons.phone, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            helperText: 'Enter number in Bangladesh format',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter mobile number';
            }
            // Extract digits only
            String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
            // Bangladesh mobile number validation
            if (digitsOnly.length < 10) {
              return 'Please enter a complete mobile number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nidNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'NID Number',
            hintText: 'Enter your national ID number',
            prefixIcon: const Icon(Icons.credit_card, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter NID number';
            }
            // Simplified NID validation for testing
            if (!RegExp(r'[0-9]{5,}').hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
              return 'Please enter at least 5 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        // Information note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Owner photo upload has been temporarily disabled for web version.',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInformationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
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
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Create a password (min. 6 characters)',
            prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.indigo),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Terms and conditions checkbox
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: (value) {
                setState(() {
                  _agreeToTerms = value ?? false;
                });
              },
              activeColor: Colors.indigo,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _agreeToTerms = !_agreeToTerms;
                  });
                },
                child: RichText(
                  text: TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        // You can add a gesture recognizer here to open terms
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Show registration form
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F9),
      appBar: AppBar(
        title: const Text('Register Shop'),
        backgroundColor: Colors.indigo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  // Step indicator
                  _buildStepIndicator(),
                  
                  // Current step content
                  _currentStep == 0 
                      ? _buildShopInformationStep()
                      : _currentStep == 1 
                          ? _buildOwnerInformationStep() 
                          : _buildAccountInformationStep(),
                  
                  const SizedBox(height: 24),
                  
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (hidden on first step)
                      _currentStep > 0
                          ? ElevatedButton(
                              onPressed: _previousStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Back'),
                            )
                          : const SizedBox(width: 80),
                      
                      // Next/Submit button
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _currentStep < 2
                                ? _nextStep
                                : _proceedToOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_currentStep < 2 ? 'Next' : 'Register'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                              context, LoginScreen.routeName);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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