import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final bool useGradient;

  const DashboardCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
    this.gradient,
    this.useGradient = false,
    this.iconColor = Colors.white,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: useGradient && gradient != null
            ? BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                boxShadow: [AppShadows.small],
              )
            : BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                boxShadow: [AppShadows.small],
              ),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconHeader(),
            const SizedBox(height: 12),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildIconHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: useGradient ? Colors.white.withOpacity(0.2) : backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: useGradient ? Colors.white : iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildContent() {
    final TextStyle valueStyle = useGradient
        ? AppTextStyles.heading2.copyWith(color: Colors.white)
        : AppTextStyles.heading2;

    final TextStyle titleStyle = useGradient
        ? AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8))
        : AppTextStyles.caption.copyWith(color: AppColors.textSecondary);

    final TextStyle subtitleStyle = useGradient
        ? AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.7), fontSize: 12)
        : AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: valueStyle,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: titleStyle,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }
} 