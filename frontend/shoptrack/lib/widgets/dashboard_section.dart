import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class DashboardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool hasPadding;
  final bool hasBottomMargin;
  final CrossAxisAlignment childrenAlignment;
  
  const DashboardSection({
    Key? key,
    required this.title,
    required this.children,
    this.trailing,
    this.hasPadding = true,
    this.hasBottomMargin = true,
    this.childrenAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: hasBottomMargin 
          ? const EdgeInsets.only(bottom: AppSpacing.large) 
          : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            padding: hasPadding 
                ? const EdgeInsets.symmetric(horizontal: AppSpacing.medium) 
                : EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: childrenAlignment,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;
  final Color? borderColor;
  final bool hasPadding;

  const DashboardCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.children,
    this.trailing,
    this.borderColor,
    this.hasPadding = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [AppShadows.small],
        border: borderColor != null 
            ? Border.all(color: borderColor!, width: 1.5) 
            : Border.all(color: Colors.grey.withValues(red: null, green: null, blue: null, alpha: 0.1 * 255)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subheading.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (hasPadding && children.isNotEmpty) 
            const SizedBox(height: AppSpacing.medium),
          ...children,
        ],
      ),
    );
  }
} 