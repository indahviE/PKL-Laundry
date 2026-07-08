import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Bottom Navigation Item
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}

/// Custom Bottom Navigation Bar
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const CustomBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _buildNavItem(
                context,
                items[index],
                index,
                index == currentIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    BottomNavItem item,
    int index,
    bool isActive,
  ) {
    final itemActiveColor = activeColor ?? AppTheme.primaryColor;
    final itemInactiveColor = inactiveColor ?? AppTheme.gray500;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              isActive ? (item.activeIcon ?? item.icon) : item.icon,
              color: isActive ? itemActiveColor : itemInactiveColor,
              size: 24,
            ),

            const SizedBox(height: AppTheme.xs),

            // Label
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isActive ? itemActiveColor : itemInactiveColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Predefined bottom navigation items untuk NetWash
class NetWashBottomNavItems {
  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    BottomNavItem(
      label: 'Orders',
      icon: Icons.receipt_outlined,
      activeIcon: Icons.receipt,
    ),
    BottomNavItem(
      label: 'Customers',
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
    ),
    BottomNavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];
}