import 'package:flutter/material.dart';
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
                        color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.9 * 255),
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
                color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.2 * 255),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: TextField(
                onChanged: onSearch,
                style: AppTextStyles.body.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.7 * 255),
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.9 * 255),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.store, 
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
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
                    Row(
                      children: [
                        Text(
                          userName ?? 'User',
                          style: TextStyle(
                            color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.9 * 255),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (designation != null) Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, 
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.2 * 255),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            designation!,
                            style: TextStyle(
                              color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.9 * 255),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (shopId != null) Text(
                      'ID: $shopId',
                      style: TextStyle(
                        color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.8 * 255),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                // Action buttons 
                Row(
                  children: [
                    if (notificationCount != null) Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.2 * 255),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                          if (notificationCount! > 0) Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                notificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (onLogout != null) InkWell(
                      onTap: onLogout,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.2 * 255),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout,
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
          
          // Balance
          if (balance != null) Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.1 * 255),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Sales",
                  style: TextStyle(
                    color: Colors.white.withValues(red: null, green: null, blue: null, alpha: 0.9 * 255),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '৳ ${balance!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 