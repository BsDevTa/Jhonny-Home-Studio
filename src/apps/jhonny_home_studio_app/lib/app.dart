import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/settings/presentation/app_settings_provider.dart';

class JhonnyHomeStudioApp extends StatelessWidget {
  const JhonnyHomeStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final settings = context.watch<AppSettingsProvider>().settings;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: settings.studioName,
      theme: AppTheme.premiumTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      locale: const Locale('pt', 'BR'),
      routerConfig: AppRoutes.createRouter(authProvider),
    );
  }
}
