import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:provider/provider.dart';
import '../constants/theme_constants.dart';
import '../providers/auth_provider.dart';
import '../services/shop_info_service.dart';
import '../services/user_info_service.dart';
import 'id_card.dart';

class DashboardHeader extends StatefulWidget {
  final String? shopName;
  final String? userName;
  final String? designation;
  final String? shopId;
  final double? balance;
  final int? notificationCount;
  final VoidCallback? onLogout;
  
  const DashboardHeader({
    Key? key,
    this.shopName,
    this.userName,
    this.designation,
    this.shopId,
    this.balance,
    this.notificationCount,
    this.onLogout,
  }) : super(key: key);

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
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

  Future<void> _loadAdditionalInfo() async {
    if (widget.shopId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        final shopInfo = await _shopInfoService.getShopAdditionalInfo(widget.shopId!);
        final userInfo = await _userInfoService.getUserInfo(user.id);
        
        setState(() {
          _shopAdditionalInfo = shopInfo;
          _userAdditionalInfo = userInfo ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading additional info: $e');
      setState(() {
        _isLoading = false;
      });
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

  Color _getRoleColor() {
    if (widget.designation == null) return kOwnerRoleColor;
    
    switch (widget.designation!.toUpperCase()) {
      case 'OWNER':
        return kOwnerRoleColor;
      case 'MANAGER':
        return kManagerRoleColor;
      case 'SELLER':
        return kSellerRoleColor;
      default:
        return kOwnerRoleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _getRoleColor();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kNewPrimaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Shop Info (Left side)
              InkWell(
                onTap: _showShopIdCard,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FlutterIcons.store_mdi,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.shopName ?? 'Shop',
                          style: const TextStyle(
                            color: Colors.white,
                        fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                    Text(
                          'Shop ID: ${widget.shopId ?? ''}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Balance (Right side)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Today's Sales",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "৳ ${widget.balance?.toStringAsFixed(0) ?? '0'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                  ),
                ),
                ],
            ),
        ],
      ),
          
          const SizedBox(height: 20),
          
          // Bottom row with user info and actions
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
              // User info
              InkWell(
                onTap: _showUserIdCard,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Icon(
                        FlutterIcons.user_faw,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Text(
                            widget.designation?.toUpperCase() ?? 'OWNER',
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
                  // Notification
                  Stack(
                    children: [
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
                            size: 20,
                          ),
                        ),
                      ),
                      if (widget.notificationCount != null && widget.notificationCount! > 0)
                        Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                              widget.notificationCount! > 9 ? '9+' : widget.notificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 12),
                  
                  // Connect link instead of Logout
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connectivity features will be implemented in a future update'),
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
                        FlutterIcons.link_ant,
                          color: Colors.white,
                        size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
          ),
        ],
      ),
    );
  }
} 