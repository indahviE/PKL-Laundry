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

/// Custom Bottom Navigation Bar — NetWash
///
/// Didesain ulang jadi floating pill bar: mengambang dengan jarak dari tepi
/// layar (bukan nempel penuh), sudut membulat besar (radiusXl, senada
/// dengan card lain di app), dan indikator biru lembut yang meluncur
/// (AnimatedPositioned) mengikuti tab aktif — bukan cuma ganti warna icon
/// statis. Icon aktif membesar dikit + label jadi bold, semuanya animasi
/// halus 260ms supaya kerasa "hidup" tanpa berlebihan.
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
    final itemActiveColor = activeColor ?? AppTheme.primaryColor;
    final itemInactiveColor = inactiveColor ?? AppTheme.gray500;
    final barColor = backgroundColor ?? Colors.white;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset - 4 : 12),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl + 4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                // Pil indikator biru lembut yang meluncur di belakang tab aktif
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * currentIndex,
                  top: 8,
                  bottom: 8,
                  width: itemWidth,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: itemActiveColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    items.length,
                    (index) => Expanded(
                      child: _NavItemButton(
                        item: items[index],
                        isActive: index == currentIndex,
                        activeColor: itemActiveColor,
                        inactiveColor: itemInactiveColor,
                        onTap: () => onTap(index),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  final BottomNavItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItemButton({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                scale: isActive ? 1.12 : 1.0,
                child: Icon(
                  isActive ? (item.activeIcon ?? item.icon) : item.icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 260),
                style: TextStyle(
                  fontSize: isActive ? 11.5 : 11,
                  color: color,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
                child: Text(item.label),
              ),
            ],
          ),
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