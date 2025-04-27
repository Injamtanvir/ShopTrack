import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final LinearGradient? gradient;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.onTap,
    this.isLoading = false,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.cardBackground,
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: [AppShadows.small],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.subheading.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(red: null, green: null, blue: null, alpha: 0.1 * 255),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            isLoading
                ? const SizedBox(
                    height: 24,
                    child: Center(
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.textLight,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: AppTextStyles.heading2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ],
        ),
      ),
    );
  }
}

class SmallStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SmallStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: [AppShadows.small],
          border: Border.all(color: Colors.grey.withValues(red: null, green: null, blue: null, alpha: 0.1 * 255)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(red: null, green: null, blue: null, alpha: 0.1 * 255),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              value,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
} 