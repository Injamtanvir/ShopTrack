import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../providers/auth_provider.dart';
import '../services/shop_info_service.dart';
import '../services/user_info_service.dart';
import 'id_card.dart';
import 'shop_info_form.dart';
import 'user_info_form.dart';

class SellerDashboardHeader extends StatefulWidget {
  final String? shopName;
  final String? userName;
  final String? designation;
  final String? shopId;
  final VoidCallback? onLogout;
  
  const SellerDashboardHeader({
    Key? key,
    this.shopName,
    this.userName,
    this.designation,
    this.shopId,
    this.onLogout,
  }) : super(key: key);

  @override
  State<SellerDashboardHeader> createState() => _SellerDashboardHeaderState();
}

class _SellerDashboardHeaderState extends State<SellerDashboardHeader> {
  final ShopInfoService _shopInfoService = ShopInfoService();
  final UserInfoService _userInfoService = UserInfoService();
  Map<String, dynamic> _shopAdditionalInfo = {};
  Map<String, dynamic> _userAdditionalInfo = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdditionalInfo();
  }

  void _loadAdditionalInfo() {
    // Get user details from provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user != null) {
      try {
        // Load shop info
        _shopInfoService.getShopAdditionalInfo(widget.shopId ?? '').then((shopInfo) {
          if (mounted) {
            setState(() {
              _shopAdditionalInfo = shopInfo;
            });
          }
        });
        
        // Load user info
        _userInfoService.getUserInfo(user.id).then((userInfo) {
          if (mounted && userInfo != null) {
            setState(() {
              _userAdditionalInfo = userInfo;
            });
          }
        });
      } catch (e) {
        debugPrint("Error loading additional info: $e");
      }
    }
  }

  void _showShopIdCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;
    
    final shopData = {
      'shopId': widget.shopId,
      'shopName': widget.shopName,
      'shopCategory': _shopAdditionalInfo['shopCategory'] ?? '*******',
      'shopLicense': _shopAdditionalInfo['shopLicense'] ?? '*******',
      'shopVatLicense': _shopAdditionalInfo['shopVatLicense'] ?? '*******',
      'shopAddress': user.address ?? '*******',
      'registrationDate': user.createdAt?.split('T')[0] ?? '*******',
    };
    
    showDialog(
      context: context,
      builder: (context) => IDCard(
        userData: {
          'name': widget.userName,
          'designation': widget.designation,
        },
        shopData: shopData,
        isUserCard: false,
      ),
    );
  }

  void _showUserIdCard() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user!;
    
    final userData = {
      'name': widget.userName,
      'designation': _userAdditionalInfo['designation'] ?? widget.designation ?? '*******',
      'userId': _userAdditionalInfo['userId'] ?? '*******',
      'email': user.email,
    };
    
    final shopData = {
      'shopId': widget.shopId,
      'shopName': widget.shopName,
    };
    
    showDialog(
      context: context,
      builder: (context) => IDCard(
        userData: userData,
        shopData: shopData,
        isUserCard: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the appropriate role color based on designation
    Color roleColor = kSellerRoleColor; // Default to seller color

    return Container(
      decoration: BoxDecoration(
        gradient: kNewPrimaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Shop and user info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Shop icon in circle - now clickable
                      InkWell(
                        onTap: _showShopIdCard,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            FlutterIcons.store_mdi,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Shop name
                      Text(
                        widget.shopName ?? 'Shop',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // User info with avatar and designation
                  Row(
                    children: [
                      // User avatar circle - now clickable
                      InkWell(
                        onTap: _showUserIdCard,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(
                            FlutterIcons.user_faw,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // User name
                      Text(
                        widget.userName ?? 'User',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // User designation
                      if (widget.designation != null) Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          widget.designation!.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action buttons 
            Row(
              children: [
                // Notification icon
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications will be implemented in a future update'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FlutterIcons.bells_ant,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Logout button
                InkWell(
                  onTap: widget.onLogout,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      FlutterIcons.logout_ant,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 