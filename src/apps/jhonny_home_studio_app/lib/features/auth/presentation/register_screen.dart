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
import '../data/auth_models.dart';
import 'auth_provider.dart';
import '../../settings/presentation/app_settings_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final request = RegisterCustomerRequest(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    final success = await authProvider.register(request);

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
    final settings = context.watch<AppSettingsProvider>().settings;
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
                                logoUrl: settings.logoUrl,
                                fallbackName: settings.studioName,
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
                                      AppTexts.registerTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Crie sua conta e comece com uma experiÃªncia exclusiva.',
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
                                            controller: _fullNameController,
                                            labelText: 'Nome completo',
                                            prefixIcon: Icons.person_outline,
                                            validator: (value) {
                                              if ((value ?? '')
                                                  .trim()
                                                  .isEmpty) {
                                                return AppTexts
                                                    .validationRequired;
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 16),
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
                                            controller: _phoneController,
                                            labelText: 'Telefone',
                                            keyboardType: TextInputType.phone,
                                            prefixIcon: Icons.phone_outlined,
                                            validator: (value) {
                                              if ((value ?? '')
                                                  .trim()
                                                  .isEmpty) {
                                                return AppTexts
                                                    .validationRequired;
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
                                          const SizedBox(height: 16),
                                          PremiumTextField(
                                            controller:
                                                _confirmPasswordController,
                                            labelText: 'Confirmar senha',
                                            obscureText: true,
                                            prefixIcon:
                                                Icons.lock_reset_outlined,
                                            validator: (value) {
                                              if ((value ?? '').isEmpty) {
                                                return AppTexts
                                                    .validationRequired;
                                              }
                                              if (value !=
                                                  _passwordController.text) {
                                                return AppTexts
                                                    .validationPasswordMatch;
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 24),
                                          PremiumButton(
                                            text: AppTexts.createAccount,
                                            isLoading: authProvider.isLoading,
                                            onPressed: _submit,
                                          ),
                                          const SizedBox(height: 14),
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
                                                context.go(AppRoutes.login),
                                            child: const Text(
                                              AppTexts.alreadyHaveAccount,
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
        fit: BoxFit.contain,
        logoUrl: logoUrl,
        fallbackName: fallbackName,
      ),
    );
  }
}
