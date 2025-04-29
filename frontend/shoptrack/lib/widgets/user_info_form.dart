import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/theme_constants.dart';
import '../services/shop_info_service.dart';

class UserInfoForm extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> initialData;
  final Function onSaved;

  const UserInfoForm({
    Key? key,
    required this.userId,
    required this.initialData,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<UserInfoForm> createState() => _UserInfoFormState();
}

class _UserInfoFormState extends State<UserInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _shopInfoService = ShopInfoService();
  bool _isLoading = false;
  DateTime? _selectedDate;
  XFile? _selectedImage;
  String? _imageUrl;
  
  late final TextEditingController _userIdController;
  late final TextEditingController _designationController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _dobController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _salaryController;

  @override
  void initState() {
    super.initState();
    // Set default values for owner if not already set
    final defaultUserId = widget.initialData['role'] == 'OWNER' ? '0001' : '';
    final defaultDesignation = widget.initialData['role'] == 'OWNER' ? 'OWNER' : '';
    
    // Parse date if available
    if (widget.initialData['date_of_birth'] != null) {
      try {
        _selectedDate = DateTime.parse(widget.initialData['date_of_birth']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    
    _userIdController = TextEditingController(
      text: widget.initialData['userId'] ?? defaultUserId
    );
    _designationController = TextEditingController(
      text: widget.initialData['designation'] ?? defaultDesignation
    );
    _imageUrlController = TextEditingController(
      text: widget.initialData['image_url'] ?? ''
    );
    _imageUrl = widget.initialData['image_url'];
    _idNumberController = TextEditingController(
      text: widget.initialData['id_number'] ?? ''
    );
    _dobController = TextEditingController(
      text: _selectedDate != null 
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
          : ''
    );
    _addressController = TextEditingController(
      text: widget.initialData['address'] ?? ''
    );
    _phoneNumberController = TextEditingController(
      text: widget.initialData['phone_number'] ?? ''
    );
    _salaryController = TextEditingController(
      text: widget.initialData['salary']?.toString() ?? ''
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _designationController.dispose();
    _imageUrlController.dispose();
    _idNumberController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
        // Clear the image URL since we're uploading a new image
        _imageUrlController.text = '';
        _imageUrl = null;
      });
    }
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        double? salary;
        if (_salaryController.text.isNotEmpty) {
          salary = double.tryParse(_salaryController.text);
        }
        
        final userInfo = {
          'userId': _userIdController.text,
          'designation': _designationController.text,
          'image_url': _imageUrlController.text,
          'id_number': _idNumberController.text,
          'date_of_birth': _dobController.text,
          'address': _addressController.text,
          'phone_number': _phoneNumberController.text,
          'salary': salary,
        };

        // If a new image was selected, add it to the userInfo
        if (_selectedImage != null) {
          userInfo['imageFile'] = _selectedImage;
        }

        final success = await _shopInfoService.saveUserAdditionalInfo(
          widget.userId,
          userInfo,
        );

        if (success && mounted) {
          widget.onSaved(userInfo);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User information saved successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save user information')),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.contains('can only be set once')) {
            // Show a more user-friendly message for the "once only" case
            bool isOwner = widget.initialData['role'] == 'OWNER';
            if (isOwner) {
              errorMessage = 'You can only update your information once. Please contact support if you need to make changes.';
            } else {
              errorMessage = 'User information can only be set once per user.';
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $errorMessage')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please provide additional information about your profile. These details will be shown on your ID card.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Image picker
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getImageProvider(),
                        child: _hasNoImage() 
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
                
                // User ID Field
                TextFormField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    hintText: 'Enter your user ID',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a user ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Designation Field
                TextFormField(
                  controller: _designationController,
                  decoration: InputDecoration(
                    labelText: 'Designation',
                    hintText: 'e.g. OWNER, MANAGER, SELLER',
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your designation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // ID Number Field
                TextFormField(
                  controller: _idNumberController,
                  decoration: InputDecoration(
                    labelText: 'ID Number',
                    hintText: 'National ID or passport number',
                    prefixIcon: const Icon(Icons.perm_identity),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date of Birth Field
                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _selectDate(context),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                
                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText: 'Enter your address',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                // Phone Number Field
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                // Salary Field
                TextFormField(
                  controller: _salaryController,
                  decoration: InputDecoration(
                    labelText: 'Salary',
                    hintText: 'Enter your salary',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Image URL Field (hidden if image is selected)
                if (_selectedImage == null)
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Profile Image URL',
                      hintText: 'Enter URL to your profile image',
                      prefixIcon: const Icon(Icons.image),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNewPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
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
  
  bool _hasNoImage() {
    return _selectedImage == null && (_imageUrl == null || _imageUrl!.isEmpty);
  }
  
  ImageProvider? _getImageProvider() {
    if (_selectedImage != null) {
      if (kIsWeb) {
        return NetworkImage(_selectedImage!.path);
      } else {
        return FileImage(File(_selectedImage!.path));
      }
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return NetworkImage(_imageUrl!);
    }
    return null;
  }
} 