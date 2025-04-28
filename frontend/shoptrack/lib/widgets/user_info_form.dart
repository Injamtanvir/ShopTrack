import 'package:flutter/material.dart';
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
  
  late final TextEditingController _userIdController;
  late final TextEditingController _designationController;

  @override
  void initState() {
    super.initState();
    // Set default values for owner if not already set
    final defaultUserId = widget.initialData['role'] == 'OWNER' ? '0001' : '';
    final defaultDesignation = widget.initialData['role'] == 'OWNER' ? 'OWNER' : '';
    
    _userIdController = TextEditingController(
      text: widget.initialData['userId'] ?? defaultUserId
    );
    _designationController = TextEditingController(
      text: widget.initialData['designation'] ?? defaultDesignation
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userInfo = {
          'userId': _userIdController.text,
          'designation': _designationController.text,
        };

        final success = await _shopInfoService.saveUserAdditionalInfo(
          widget.userId,
          userInfo,
        );

        if (success && mounted) {
          widget.onSaved(userInfo);
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save user information')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
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
    );
  }
} 