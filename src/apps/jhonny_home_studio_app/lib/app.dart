import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_texts.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';

class JhonnyHomeStudioApp extends StatelessWidget {
  const JhonnyHomeStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppTexts.appName,
      theme: AppTheme.premiumTheme,
      routerConfig: AppRoutes.createRouter(authProvider),
    );
  }
}
