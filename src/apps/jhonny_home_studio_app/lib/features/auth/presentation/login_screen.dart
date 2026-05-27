import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_texts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/error_message.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/premium_button.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.background,
                  Color(0xFF111111),
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 28),
                    const _BrandHeader(),
                    const SizedBox(height: 36),
                    Text(
                      AppTexts.loginTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entre para continuar sua experiência premium.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (authProvider.errorMessage != null) ...[
                      ErrorMessage(message: authProvider.errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          PremiumTextField(
                            controller: _emailController,
                            labelText: 'E-mail',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return AppTexts.validationRequired;
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
                                return AppTexts.validationRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          PremiumButton(
                            text: AppTexts.signIn,
                            isLoading: authProvider.isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.register),
                            child: const Text(
                              AppTexts.createAccount,
                              style: TextStyle(color: AppColors.goldSoft),
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
          if (authProvider.isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.spa_outlined, color: AppColors.gold, size: 60),
        SizedBox(height: 16),
        Text(
          AppTexts.appName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          AppTexts.slogan,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }
}
