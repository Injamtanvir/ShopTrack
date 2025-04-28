import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import '../constants/app_styles.dart';
import '../constants/theme_constants.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool hasSearchBar;
  final Function(String)? onSearch;
  final String searchHint;
  
  // Old properties for compatibility
  final String? shopName;
  final double? balance;
  final String? userName;
  final String? designation;
  final String? shopId;
  final int? notificationCount;
  final VoidCallback? onLogout;
  
  const DashboardHeader({
    Key? key,
    this.title = '',
    this.subtitle = '',
    this.trailing,
    this.hasSearchBar = false,
    this.onSearch,
    this.searchHint = 'Search...',
    
    // Old properties
    this.shopName,
    this.balance,
    this.userName,
    this.designation,
    this.shopId,
    this.notificationCount,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if using the old version of the header
    if (shopName != null || userName != null) {
      return _buildLegacyHeader(context);
    }
    
    // New version
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.large),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [AppShadows.medium],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (hasSearchBar) ...[
            const SizedBox(height: AppSpacing.medium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: TextField(
                onChanged: onSearch,
                style: AppTextStyles.body.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLegacyHeader(BuildContext context) {
    // Determine the appropriate role color based on designation
    Color roleColor = kOwnerRoleColor;
    if (designation?.toLowerCase() == 'manager') {
      roleColor = kManagerRoleColor;
    } else if (designation?.toLowerCase() == 'seller') {
      roleColor = kSellerRoleColor;
    } else if (designation?.toLowerCase() == 'admin') {
      roleColor = kNewPrimaryColor;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: kNewPrimaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section
          Padding(
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
                          // Shop icon in circle
                          Container(
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
                          const SizedBox(width: 8),
                          // Shop name
                          Text(
                            shopName ?? 'Shop',
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
                          // User avatar circle
                          Container(
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
                          const SizedBox(width: 8),
                          // User name
                          Text(
                            userName ?? 'User',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // User designation
                          if (designation != null) Container(
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
                              designation!.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Removing the shop ID display
                      /* if (shopId != null) Text(
                        'ID: $shopId',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ), */
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
                    
                    // Connect button (replaced logout)
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connect to other shops will be implemented in a future update'),
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
                          FlutterIcons.link_fea,
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
          
          // Bottom section with balance/sales info
          _buildBottomSection(),
        ],
      ),
    );
  }

  // Bottom section with balance/sales info
  Widget _buildBottomSection() {
    // Always return an empty SizedBox to ensure no space is taken up
    return const SizedBox.shrink();
  }
} 