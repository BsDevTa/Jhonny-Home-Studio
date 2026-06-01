import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.logoUrl = '',
    this.fallbackName = AppTexts.appName,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final String logoUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    if (logoUrl.trim().isNotEmpty) {
      return Image.network(
        logoUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _AssetLogo(
            width: width,
            height: height,
            fit: fit,
            fallbackName: fallbackName,
          );
        },
      );
    }

    return _AssetLogo(
      width: width,
      height: height,
      fit: fit,
      fallbackName: fallbackName,
    );
  }
}

class _AssetLogo extends StatelessWidget {
  const _AssetLogo({
    required this.width,
    required this.height,
    required this.fit,
    required this.fallbackName,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          fallbackName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        );
      },
    );
  }
}
