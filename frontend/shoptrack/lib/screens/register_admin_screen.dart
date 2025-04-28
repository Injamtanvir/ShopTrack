import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../constants/theme_constants.dart';

class RegisterAdminScreen extends StatefulWidget {
  static const routeName = '/register-admin';

  const RegisterAdminScreen({Key? key}) : super(key: key);

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  String? _base64Image;
  bool _obscurePassword = true;
  bool _registrationSuccess = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      
      // Convert image to base64
      final bytes = await File(image.path).readAsBytes();
      _base64Image = base64Encode(bytes);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Add the missing validation methods
  bool _validatePersonalInfo() {
    return _nameController.text.isNotEmpty &&
        _designationController.text.isNotEmpty &&
        _idNumberController.text.isNotEmpty;
  }

  bool _validateContactInfo() {
    return _addressController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
  }

  bool _validateEmploymentInfo() {
    return _employeeIdController.text.isNotEmpty &&
        _salaryController.text.isNotEmpty &&
        double.tryParse(_salaryController.text) != null;
  }

  bool _validateAccountInfo() {
    return _emailController.text.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text) &&
        _passwordController.text.isNotEmpty &&
        _passwordController.text.length >= 6;
  }

  void _registerAdmin() async {
    if (!_formKey.currentState!.validate()) {
      // Find the first step with validation errors
      if (!_validatePersonalInfo()) {
        setState(() => _currentStep = 0);
      } else if (!_validateContactInfo()) {
        setState(() => _currentStep = 1);
      } else if (!_validateEmploymentInfo()) {
        setState(() => _currentStep = 2);
      } else if (!_validateAccountInfo()) {
        setState(() => _currentStep = 3);
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final result = await authProvider.registerManager(
        name: _nameController.text.trim(),
        designation: _designationController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        imageBase64: _base64Image,
        idNumber: _idNumberController.text.trim(),
        dateOfBirth: _selectedDate,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        salary: double.tryParse(_salaryController.text) ?? 0,
      );

      if (result) {
        setState(() {
          _registrationSuccess = true;
        });
      } else {
        // Handle general errors (the error message is already set in the provider)
        setState(() {}); // Trigger a rebuild to show the error message
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show success dialog
  void _showSuccessDialog() {
    setState(() {
      _registrationSuccess = true;
    });
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Image picker
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null 
                  ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                  : null,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Select Image'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Full Name',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Designation',
          controller: _designationController,
          prefixIcon: Icons.work_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter designation';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Date of Birth picker
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy').format(_selectedDate),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'NID/Birth Certificate Number',
          controller: _idNumberController,
          prefixIcon: Icons.badge_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter ID number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Address',
          controller: _addressController,
          prefixIcon: Icons.home_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Phone Number',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmploymentInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employment Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Employee ID',
          controller: _employeeIdController,
          prefixIcon: Icons.badge_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter employee ID';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Salary',
          controller: _salaryController,
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter salary';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kNewTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          label: 'Email',
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
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
        
        CustomTextField(
          label: 'Password',
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_registrationSuccess) {
      // Show success screen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manager Registration'),
          backgroundColor: kManagerRoleColor,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ),
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
                    'The manager has been registered successfully.',
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

                  // Add another admin button
                  CustomButton(
                    text: 'Register Another Manager',
                    onPressed: () {
                      setState(() {
                        _registrationSuccess = false;
                        _nameController.clear();
                        _designationController.clear();
                        _employeeIdController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                        _idNumberController.clear();
                        _addressController.clear();
                        _phoneController.clear();
                        _salaryController.clear();
                        _selectedImage = null;
                        _base64Image = null;
                        _currentStep = 0;
                      });
                    },
                    buttonStyle: ElevatedButton.styleFrom(
                      backgroundColor: kManagerRoleColor,
                    ),
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
        title: const Text('Register Manager'),
        backgroundColor: kManagerRoleColor,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Error message display
              if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          authProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              
              Expanded(
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 3) {
                      setState(() {
                        _currentStep += 1;
                      });
                    } else {
                      _registerAdmin();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: _currentStep == 3 ? 'Register Manager' : 'Continue',
                              onPressed: details.onStepContinue!,
                              isLoading: _currentStep == 3 ? authProvider.isLoading : false,
                              buttonStyle: ElevatedButton.styleFrom(
                                backgroundColor: kManagerRoleColor,
                              ),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: details.onStepCancel,
                                child: const Text('Back'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Personal Information'),
                      content: _buildPersonalInfoStep(),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: const Text('Contact Information'),
                      content: _buildContactInfoStep(),
                      isActive: _currentStep >= 1,
                    ),
                    Step(
                      title: const Text('Employment Information'),
                      content: _buildEmploymentInfoStep(),
                      isActive: _currentStep >= 2,
                    ),
                    Step(
                      title: const Text('Account Information'),
                      content: _buildAccountInfoStep(),
                      isActive: _currentStep >= 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}