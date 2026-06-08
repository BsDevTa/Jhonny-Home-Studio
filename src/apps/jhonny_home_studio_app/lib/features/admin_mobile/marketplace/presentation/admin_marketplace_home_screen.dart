import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../presentation/admin_mobile_screens.dart';

class AdminMarketplaceHomeScreen extends StatelessWidget {
  const AdminMarketplaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Marketplace',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Loja Beauty',
            style: TextStyle(
              color: AppColors.champagne,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gerencie categorias e produtos da loja.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _MarketplaceAreaCard(
            icon: Icons.category_outlined,
            title: 'Categorias da Loja',
            subtitle:
                'Cadastre categorias como shampoos, máscaras, óleos e kits pós-loiro.',
            action: 'Gerenciar categorias',
            onTap: () => context.push('/admin-mobile/marketplace/categories'),
          ),
          _MarketplaceAreaCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Produtos da Loja',
            subtitle: 'Cadastre os produtos que aparecerão no app do cliente.',
            action: 'Gerenciar produtos',
            onTap: () => context.push('/admin-mobile/marketplace/products'),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceAreaCard extends StatelessWidget {
  const _MarketplaceAreaCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: Icon(icon, color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: onTap, child: Text(action)),
          ),
        ],
      ),
    );
  }
}
