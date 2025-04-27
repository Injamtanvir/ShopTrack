import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final IconData? icon;
  final Color? selectedColor;
  final Color? backgroundColor;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            )
          : null,
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: backgroundColor ?? AppColors.background,
      selectedColor: color,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(
          color: isSelected ? Colors.transparent : color.withOpacity(0.3),
          width: 1,
        ),
      ),
    );
  }
}

class FilterChipGroup<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedOption;
  final Function(T?) onOptionSelected;
  final String Function(T) labelBuilder;
  final IconData? Function(T)? iconBuilder;
  final bool allowDeselection;
  final EdgeInsets? padding;
  final Color? selectedColor;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.labelBuilder,
    this.iconBuilder,
    this.allowDeselection = true,
    this.padding,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: options.map((option) {
          final isSelected = selectedOption == option;
          
          return FilterChipWidget(
            label: labelBuilder(option),
            isSelected: isSelected,
            icon: iconBuilder != null ? iconBuilder!(option) : null,
            selectedColor: selectedColor,
            onSelected: (selected) {
              if (selected) {
                onOptionSelected(option);
              } else if (allowDeselection) {
                onOptionSelected(null);
              }
            },
          );
        }).toList(),
      ),
    );
  }
} 