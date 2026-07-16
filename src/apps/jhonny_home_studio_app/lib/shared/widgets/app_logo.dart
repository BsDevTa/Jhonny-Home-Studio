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
    this.imageScale = 1,
    this.logoUrl = '',
    this.fallbackName = AppTexts.appName,
  });

  final double? width;
  final double? height;
  final bool showBorder;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxFit fit;
  final double imageScale;
  final String logoUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    if (!showBorder) {
      return _LogoImage(
        width: width,
        height: height,
        fit: fit,
        imageScale: imageScale,
        logoUrl: logoUrl,
        fallbackName: fallbackName,
      );
    }

    const borderWidth = 1.2;

    return SizedBox(
      width: width,
      height: height,
      child: PremiumGradientBorderCard(
        borderRadius: borderRadius,
        padding: padding,
        backgroundColor: AppColors.backgroundSoft,
        borderWidth: borderWidth,
        subtleGlow: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _LogoImage(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                fit: fit,
                imageScale: imageScale,
                logoUrl: logoUrl,
                fallbackName: fallbackName,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({
    required this.width,
    required this.height,
    required this.fit,
    required this.imageScale,
    required this.logoUrl,
    required this.fallbackName,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final double imageScale;
  final String logoUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    Widget applyScale(Widget child) {
      if (imageScale == 1) {
        return child;
      }

      return Transform.scale(scale: imageScale, child: child);
    }

    if (logoUrl.trim().isNotEmpty) {
      return applyScale(
        Image.network(
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
        ),
      );
    }

    // A imagem da logo possui margem interna; escala controlada melhora o encaixe.
    return applyScale(
      _AssetLogo(
        width: width,
        height: height,
        fit: fit,
        fallbackName: fallbackName,
      ),
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
