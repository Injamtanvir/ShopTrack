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
  File? _ownerPhoto;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });
      
      final imageFile = await ImageUtils.pickAndCompressImage(source, context: context);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (imageFile != null) {
        // For web platform, skip extra validation and accept all images
        if (kIsWeb || await ImageUtils.isValidImage(imageFile)) {
          setState(() {
            _ownerPhoto = imageFile;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid image. Please select a JPG or PNG file under 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (mounted) {
        // Only show this if the user canceled the selection
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      if (_nidNumberController.text.isEmpty || 
          !RegExp(r'^[0-9]{10}$|^[0-9]{13}$|^[0-9]{17}$').hasMatch(_nidNumberController.text.replaceAll(RegExp(r'[^0-9]'), ''))) {
        _showError('Please enter a valid NID number');
        return false;
      }
      if (_ownerPhoto == null) {
        _showError('Please upload owner photo');
        return false;
      }
      
      // Check if image is currently being processed
      if (_isLoading) {
        _showError('Please wait while the image is being processed');
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
    
    // Create registration data map to pass to OTP screen
    final registrationData = {
      'shopName': _shopNameController.text.trim(),
      'shopAddress': _shopAddressController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'licenseNumber': _licenseNumberController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'mobileNumber': _mobileFormatter.getUnmaskedText(),
      'nidNumber': _nidFormatter.getUnmaskedText(),
      'ownerPhotoPath': _ownerPhoto?.path,
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
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: 'Enter your mobile number',
            prefixIcon: const Icon(Icons.phone, color: Colors.indigo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter mobile number';
            }
            // Bangladesh mobile number validation (starts with 01 and has 11 digits)
            if (!RegExp(r'^01[0-9]{9}$').hasMatch(value)) {
              return 'Please enter valid BD mobile number';
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
            // NID number format validation (10, 13 or 17 digits)
            if (!RegExp(r'^[0-9]{10}$|^[0-9]{13}$|^[0-9]{17}$').hasMatch(value)) {
              return 'Please enter valid NID number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Owner Photo',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isLoading ? null : _showPhotoOptionsDialog,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _ownerPhoto != null ? Colors.indigo.shade300 : Colors.grey.shade300),
            ),
            child: _isLoading 
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade300),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Processing image...',
                          style: TextStyle(
                            color: Colors.indigo.shade300,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : (_ownerPhoto != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _ownerPhoto!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _ownerPhoto = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: InkWell(
                          onTap: _showPhotoOptionsDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.indigo,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.indigo.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          color: Colors.indigo.shade300,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        PlatformUtils.isDesktop
                            ? 'Choose from your files'
                            : 'Take a photo or choose from gallery',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )),
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

  // Show photo options dialog
  void _showPhotoOptionsDialog() {
    if (PlatformUtils.isDesktop) {
      // On desktop, only show gallery option
      _pickImage(ImageSource.gallery);
      return;
    }
    
    // For mobile platforms, show dialog with camera and gallery options
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Photo Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
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