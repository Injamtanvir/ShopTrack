import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

class CustomBottomNavBar extends StatelessWidget{
  final int currentIndex;
  final Function(int) onTap;
  final String? userPhotoUrl;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.userPhotoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Container(
      height: 65,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
          _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
          _buildNavItem(2, Icons.receipt_long_outlined, Icons.receipt_long, 'Invoice'),
          _buildNavItem(3, Icons.insights_outlined, Icons.insights, 'Reports'),
          _buildNavItem(4, Icons.menu, Icons.menu, 'Menu'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kNewPrimaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kNewPrimaryColor : kNewSecondaryTextColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? kNewPrimaryColor : kNewSecondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 