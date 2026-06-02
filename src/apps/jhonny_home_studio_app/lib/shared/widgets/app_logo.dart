import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_texts.dart';
import 'premium_gradient_border_card.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.showBorder = false,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(10),
    this.fit = BoxFit.contain,
    this.logoUrl = '',
    this.fallbackName = AppTexts.appName,
  });

  final double? width;
  final double? height;
  final bool showBorder;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxFit fit;
  final String logoUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final logo = _LogoImage(
      width: showBorder ? null : width,
      height: showBorder ? null : height,
      fit: fit,
      logoUrl: logoUrl,
      fallbackName: fallbackName,
    );

    if (!showBorder) {
      return logo;
    }

    return SizedBox(
      width: width,
      height: height,
      child: PremiumGradientBorderCard(
        borderRadius: borderRadius,
        padding: padding,
        backgroundColor: AppColors.backgroundSoft,
        borderWidth: 1.2,
        subtleGlow: true,
        child: logo,
      ),
    );
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({
    required this.width,
    required this.height,
    required this.fit,
    required this.logoUrl,
    required this.fallbackName,
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

    // A imagem da logo possui margem interna. Recortar o PNG melhora o encaixe.
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
