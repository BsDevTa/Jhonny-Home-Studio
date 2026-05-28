import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'navigation_path_helper.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentPath,
    required this.onHome,
    required this.onServices,
    required this.onAppointments,
    required this.onProfile,
  });

  final String currentPath;
  final VoidCallback onHome;
  final VoidCallback onServices;
  final VoidCallback onAppointments;
  final VoidCallback onProfile;

  int get currentIndex {
    return getBottomNavIndex(currentPath);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.55)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border, width: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.home_rounded,
                      label: 'Início',
                      selected: currentIndex == 0,
                      onTap: onHome,
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.spa_rounded,
                      label: 'Serviços',
                      selected: currentIndex == 1,
                      onTap: onServices,
                    ),
                  ),
                  const SizedBox(width: 76),
                  const SizedBox(width: 58),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.event_note_rounded,
                      label: 'Agenda',
                      selected: currentIndex == 2,
                      onTap: onAppointments,
                    ),
                  ),
                  Expanded(
                    child: _BottomNavItem(
                      icon: Icons.person_rounded,
                      label: 'Perfil',
                      selected: currentIndex == 3,
                      onTap: onProfile,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -18,
              child: _CenterActionButton(
                selected: currentIndex == 2,
                onTap: onAppointments,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.gold : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.20),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          color: AppColors.gold,
          size: 24,
        ),
      ),
    );
  }
}
