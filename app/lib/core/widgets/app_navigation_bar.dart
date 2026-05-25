import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_colors.dart';

enum AppNavTab { home, stats }

class AppCameraFloatingButton extends StatelessWidget {
  const AppCameraFloatingButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary1,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Iconsax.camera5, color: Colors.white, size: 28),
      ),
    );
  }
}

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.selectedTab,
    required this.onHomeTap,
    required this.onStatsTap,
  });

  final AppNavTab selectedTab;
  final VoidCallback onHomeTap;
  final VoidCallback onStatsTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Iconsax.home_2,
              label: '홈',
              selected: selectedTab == AppNavTab.home,
              onTap: onHomeTap,
            ),
            const SizedBox(width: 64),
            _NavItem(
              icon: Iconsax.chart,
              label: '통계',
              selected: selectedTab == AppNavTab.stats,
              onTap: onStatsTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : const Color(0xFFBBBBBB);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
