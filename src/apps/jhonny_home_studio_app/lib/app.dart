import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/settings/presentation/app_settings_provider.dart';

class JhonnyHomeStudioApp extends StatefulWidget {
  const JhonnyHomeStudioApp({super.key});

  @override
  State<JhonnyHomeStudioApp> createState() => _JhonnyHomeStudioAppState();
}

class _JhonnyHomeStudioAppState extends State<JhonnyHomeStudioApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRoutes.createRouter(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      routerConfig: _router,
    );
  }
}
