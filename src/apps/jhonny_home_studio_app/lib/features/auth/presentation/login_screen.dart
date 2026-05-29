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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
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
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final logoWidth = isWide ? 240.0 : 180.0;
    final logoHeight = isWide ? 135.0 : 105.0;
    final topSpacing = isWide ? 70.0 : 36.0;
    final logoCardSpacing = isWide ? 70.0 : 42.0;

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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: topSpacing),
                              _BrandHeader(
                                width: logoWidth,
                                height: logoHeight,
                              ),
                              SizedBox(height: logoCardSpacing),
                              PremiumCard(
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
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Entre para continuar sua experiÃªncia premium.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    if (authProvider.errorMessage != null) ...[
                                      ErrorMessage(
                                        message: authProvider.errorMessage!,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          PremiumTextField(
                                            controller: _emailController,
                                            labelText: 'E-mail',
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            prefixIcon: Icons.email_outlined,
                                            validator: (value) {
                                              final text = value?.trim() ?? '';
                                              if (text.isEmpty) {
                                                return AppTexts
                                                    .validationRequired;
                                              }
                                              if (!text.contains('@')) {
                                                return AppTexts.validationEmail;
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          PremiumTextField(
                                            controller: _passwordController,
                                            labelText: 'Senha',
                                            obscureText: true,
                                            prefixIcon: Icons.lock_outline,
                                            validator: (value) {
                                              if ((value ?? '').isEmpty) {
                                                return AppTexts
                                                    .validationRequired;
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 22),
                                          PremiumButton(
                                            text: AppTexts.signIn,
                                            isLoading: authProvider.isLoading,
                                            onPressed: _submit,
                                          ),
                                          const SizedBox(height: 12),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.buttonSecondaryText,
                                              backgroundColor: AppColors
                                                  .buttonSecondaryBackground,
                                              side: const BorderSide(
                                                color: AppColors.border,
                                                width: 0.8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 14,
                                                  ),
                                            ),
                                            onPressed: () =>
                                                context.go(AppRoutes.register),
                                            child: const Text(
                                              AppTexts.createAccount,
                                              style: TextStyle(
                                                color: AppColors
                                                    .buttonSecondaryText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLogo(width: width, height: height, fit: BoxFit.contain),
    );
  }
}
