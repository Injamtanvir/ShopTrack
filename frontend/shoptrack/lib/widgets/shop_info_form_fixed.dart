import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/theme_constants.dart';
import '../services/shop_info_service.dart';

class ShopInfoForm extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic> initialData;
  final Function onSaved;

  const ShopInfoForm({
    Key? key,
    required this.shopId,
    required this.initialData,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<ShopInfoForm> createState() => _ShopInfoFormState();
}

class _ShopInfoFormState extends State<ShopInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _shopInfoService = ShopInfoService();
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _imageUrl;
  
  late final TextEditingController _shopCategoryController;
  late final TextEditingController _shopLicenseController;
  late final TextEditingController _shopVatLicenseController;
  late final TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _shopCategoryController = TextEditingController(text: widget.initialData['shopCategory'] ?? '');
    _shopLicenseController = TextEditingController(text: widget.initialData['shopLicense'] ?? '');
    _shopVatLicenseController = TextEditingController(text: widget.initialData['shopVatLicense'] ?? '');
    _imageUrlController = TextEditingController(text: widget.initialData['image_url'] ?? '');
    _imageUrl = widget.initialData['image_url'];
  }

  @override
  void dispose() {
    _shopCategoryController.dispose();
    _shopLicenseController.dispose();
    _shopVatLicenseController.dispose();
    _imageUrlController.dispose();
    super.dispose();
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

  Future<void> _saveShopInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final shopInfo = {
          'shopCategory': _shopCategoryController.text,
          'shopLicense': _shopLicenseController.text,
          'shopVatLicense': _shopVatLicenseController.text,
          'image_url': _imageUrlController.text,
        };

        // If a new image was selected, add it to the shopInfo
        // Fix: use Map.cast to ensure the type system accepts this operation
        if (_selectedImage != null) {
          final Map<String, dynamic> typedShopInfo = shopInfo;
          typedShopInfo['imageFile'] = _selectedImage;
        }

        final success = await _shopInfoService.saveShopAdditionalInfo(
          widget.shopId,
          shopInfo,
        );

        if (success && mounted) {
          widget.onSaved(shopInfo);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop information saved successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save shop information')),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.contains('can only be set once')) {
            // Show a more user-friendly message for the "once only" case
            errorMessage = 'Shop information can only be updated by the owner. Please contact the shop owner.';
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
                  'Shop Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please provide additional information about your shop. These details will be shown on your shop ID card.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Shop Logo/Image
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: _getDecorationImage(),
                        ),
                        child: _hasNoImage() 
                          ? const Icon(Icons.store, size: 50, color: Colors.grey) 
                          : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Select Shop Logo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Shop Category Field
                TextFormField(
                  controller: _shopCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Shop Category',
                    hintText: 'e.g. Retail, Electronics, Grocery',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    // Category is optional
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Shop License Field
                TextFormField(
                  controller: _shopLicenseController,
                  decoration: InputDecoration(
                    labelText: 'Shop License Number',
                    hintText: 'Optional',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    // License is optional
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Shop VAT License Field
                TextFormField(
                  controller: _shopVatLicenseController,
                  decoration: InputDecoration(
                    labelText: 'VAT License Number',
                    hintText: 'Optional',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    // VAT License is optional
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Shop Image URL Field (hidden if image is selected)
                if (_selectedImage == null)
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Shop Logo URL',
                      hintText: 'Enter URL to your shop logo (optional)',
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
                      onPressed: _isLoading ? null : _saveShopInfo,
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
  
  DecorationImage? _getDecorationImage() {
    if (_selectedImage != null) {
      if (kIsWeb) {
        return DecorationImage(
          image: NetworkImage(_selectedImage!.path),
          fit: BoxFit.cover,
        );
      } else {
        return DecorationImage(
          image: FileImage(File(_selectedImage!.path)),
          fit: BoxFit.cover,
        );
      }
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_imageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
} 