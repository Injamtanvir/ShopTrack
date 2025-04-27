import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class CustomDataTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> items;
  final List<Widget> Function(T item) cellBuilder;
  final Widget? emptyState;
  final bool isLoading;
  final double? columnSpacing;
  final Function(T)? onRowTap;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.cellBuilder,
    this.emptyState,
    this.isLoading = false,
    this.columnSpacing,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return emptyState ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.medium),
              child: Text('No data available'),
            ),
          );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [AppShadows.small],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 1),
            _buildRows(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.small,
        horizontal: AppSpacing.medium,
      ),
      child: Row(
        children: columns.map((column) {
          return Expanded(
            child: Text(
              column,
              style: AppTextStyles.subheading.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRows() {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return InkWell(
          onTap: onRowTap != null ? () => onRowTap!(item) : null,
          child: Container(
            decoration: BoxDecoration(
              color: index.isEven ? Colors.white : AppColors.background.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.textLight.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.small,
              horizontal: AppSpacing.medium,
            ),
            child: Row(
              children: cellBuilder(item).map((cell) {
                return Expanded(child: cell);
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DataTableCell extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final bool isBold;
  final bool alignRight;
  final int maxLines;

  const DataTableCell({
    super.key,
    required this.text,
    this.style,
    this.isBold = false,
    this.alignRight = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? AppTextStyles.body).copyWith(
        fontWeight: isBold ? FontWeight.bold : null,
      ),
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class StatusCell extends StatelessWidget {
  final String text;
  final Color color;
  final double? width;

  const StatusCell({
    super.key,
    required this.text,
    required this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: width ?? 120),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
} 