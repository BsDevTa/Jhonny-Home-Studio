import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_text_field.dart';
import 'auth_provider.dart';
import '../../settings/presentation/app_settings_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _introController;
  late final Animation<double> _introScale;
  late final Animation<double> _introOpacity;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    final introCurve = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _introScale = Tween<double>(begin: 0.88, end: 1).animate(introCurve);
    _introOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      context.go(authProvider.isAdmin ? AppRoutes.adminMobile : AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<AppSettingsProvider>().settings;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  AppColors.surfaceElevated,
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = screenWidth >= 700;
                  final isShort = constraints.maxHeight < 760;
                  final horizontalPadding = isWide ? 24.0 : 18.0;
                  final logoWidth = isWide
                      ? (isShort ? 390.0 : 420.0)
                      : (screenWidth - 36).clamp(260.0, 336.0).toDouble();
                  final logoHeight = isWide
                      ? (isShort ? 238.0 : 260.0)
                      : (screenWidth - 36).clamp(166.0, 208.0).toDouble();
                  final cardWidth = isWide
                      ? 430.0
                      : (screenWidth - horizontalPadding * 2)
                            .clamp(0.0, 420.0)
                            .toDouble();
                  final logoCardSpacing = isWide ? 20.0 : 18.0;
                  final topOffset = isWide ? (isShort ? 48.0 : 72.0) : 16.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: _LoginEntrance(
                          scale: _introScale,
                          opacity: _introOpacity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, topOffset, 0, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BrandHeader(
                                  width: logoWidth,
                                  height: logoHeight,
                                  logoUrl: settings.logoUrl,
                                  fallbackName: settings.studioName,
                                ),
                                SizedBox(height: logoCardSpacing),
                                Center(
                                  child: SizedBox(
                                    width: cardWidth,
                                    child: PremiumCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 24,
                                      ),
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.surface,
                                          AppColors.surfaceElevated,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            AppTexts.loginTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Entre para continuar sua experiência premium.',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          if (authProvider.errorMessage !=
                                              null) ...[
                                            ErrorMessage(
                                              message:
                                                  authProvider.errorMessage!,
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          Form(
                                            key: _formKey,
                                            child: Column(
                                              children: [
                                                PremiumTextField(
                                                  controller: _emailController,
                                                  labelText: 'E-mail',
                                                  keyboardType: TextInputType
                                                      .emailAddress,
                                                  prefixIcon:
                                                      Icons.email_outlined,
                                                  prefixIconSize: 19,
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  validator: (value) {
                                                    final text =
                                                        value?.trim() ?? '';
                                                    if (text.isEmpty) {
                                                      return AppTexts
                                                          .validationRequired;
                                                    }
                                                    if (!text.contains('@')) {
                                                      return AppTexts
                                                          .validationEmail;
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                                PremiumTextField(
                                                  controller:
                                                      _passwordController,
                                                  labelText: 'Senha',
                                                  obscureText: true,
                                                  prefixIcon:
                                                      Icons.lock_outline,
                                                  prefixIconSize: 19,
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  validator: (value) {
                                                    if ((value ?? '').isEmpty) {
                                                      return AppTexts
                                                          .validationRequired;
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                PremiumButton(
                                                  text: AppTexts.signIn,
                                                  isLoading:
                                                      authProvider.isLoading,
                                                  height: 46,
                                                  onPressed: _submit,
                                                ),
                                                const SizedBox(height: 6),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: AppColors
                                                        .buttonSecondaryText,
                                                    backgroundColor: AppColors
                                                        .buttonSecondaryBackground,
                                                    side: const BorderSide(
                                                      color: AppColors.border,
                                                      width: 0.8,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 18,
                                                          vertical: 10,
                                                        ),
                                                  ),
                                                  onPressed: () => context.go(
                                                    AppRoutes.register,
                                                  ),
                                                  child: const Text(
                                                    AppTexts.createAccount,
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .buttonSecondaryText,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (authProvider.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}

class _LoginEntrance extends StatelessWidget {
  const _LoginEntrance({
    required this.scale,
    required this.opacity,
    required this.child,
  });

  final Animation<double> scale;
  final Animation<double> opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.width,
    required this.height,
    required this.logoUrl,
    required this.fallbackName,
  });

  final double width;
  final double height;
  final String logoUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLogo(
        width: width,
        height: height,
        showBorder: true,
        padding: const EdgeInsets.all(4),
        fit: BoxFit.contain,
        imageScale: width >= 360 ? 2.15 : 1.88,
        logoUrl: logoUrl,
        fallbackName: fallbackName,
      ),
    );
  }
}
