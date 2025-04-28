import 'package:flutter/material.dart';
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
  
  late final TextEditingController _shopCategoryController;
  late final TextEditingController _shopLicenseController;
  late final TextEditingController _shopVatLicenseController;

  @override
  void initState() {
    super.initState();
    _shopCategoryController = TextEditingController(text: widget.initialData['shopCategory'] ?? '');
    _shopLicenseController = TextEditingController(text: widget.initialData['shopLicense'] ?? '');
    _shopVatLicenseController = TextEditingController(text: widget.initialData['shopVatLicense'] ?? '');
  }

  @override
  void dispose() {
    _shopCategoryController.dispose();
    _shopLicenseController.dispose();
    _shopVatLicenseController.dispose();
    super.dispose();
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
        };

        final success = await _shopInfoService.saveShopAdditionalInfo(
          widget.shopId,
          shopInfo,
        );

        if (success && mounted) {
          widget.onSaved(shopInfo);
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save shop information')),
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
    );
  }
} 