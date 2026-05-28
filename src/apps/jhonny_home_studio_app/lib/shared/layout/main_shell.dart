import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'app_bottom_nav.dart';
import 'app_drawer.dart';
import 'app_side_menu.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 0),
              child: child,
            ),
          ),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: AppDrawer(currentPath: currentPath),
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jhonny Home Studio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'Experiência premium',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                iconSize: 20,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.go(AppRoutes.createAppointment),
                iconSize: 20,
                icon: const Icon(Icons.calendar_month_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    AppSideMenu(currentPath: currentPath),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: isWide
              ? null
              : AppBottomNav(
                  currentPath: currentPath,
                  onHome: () => context.go(AppRoutes.home),
                  onServices: () => context.go(AppRoutes.services),
                  onAppointments: () => context.go(AppRoutes.myAppointments),
                  onProfile: () => context.go(AppRoutes.profile),
                ),
        );
      },
    );
  }
}
