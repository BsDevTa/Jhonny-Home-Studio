import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../data/marketplace_models.dart';

class ProductCard extends StatelessWidget {
  ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.imageHeight = 132,
  }) : _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final ProductModel product;
  final VoidCallback onTap;
  final double imageHeight;
  final NumberFormat _currency;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: product.hasImage
                  ? Image.network(
                      product.mainImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ProductPlaceholder(),
                    )
                  : const _ProductPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            product.shortDescription.isEmpty
                ? product.productCategoryName
                : product.shortDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                _currency.format(product.currentPrice),
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (product.hasPromotionalPrice)
                Text(
                  _currency.format(product.price),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 11,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(38),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onTap,
              child: const Text('Ver produto'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.goldDark,
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.champagne,
        size: 34,
      ),
    );
  }
}
