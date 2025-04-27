import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import 'dashboard_card.dart';

class DashboardStatsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<DashboardCard> cards;
  final EdgeInsets padding;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const DashboardStatsSection({
    Key? key,
    required this.title,
    this.subtitle,
    required this.cards,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.4,
    this.spacing = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          _buildCardsGrid(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildCardsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getResponsiveCrossAxisCount(context, constraints),
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  int _getResponsiveCrossAxisCount(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    if (width < 500) {
      return 1; // For very small screens (mobile)
    } else if (width < 800) {
      return 2; // For medium screens (tablets)
    } else {
      return crossAxisCount; // For larger screens
    }
  }
} 