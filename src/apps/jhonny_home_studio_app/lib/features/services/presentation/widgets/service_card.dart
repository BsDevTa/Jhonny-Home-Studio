import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/service_presentation_formatter.dart';
import '../../data/service_models.dart';
import '../../../../../shared/widgets/premium_card.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onDetailsPressed,
  });

  final ServiceModel service;
  final VoidCallback onDetailsPressed;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onDetailsPressed,
      padding: const EdgeInsets.all(14),
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
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    width: 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.serviceCategoryName.isEmpty
                          ? 'Categoria não informada'
                          : service.serviceCategoryName,
                      style: const TextStyle(
                        color: AppColors.goldSoft,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service.description.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.payments_outlined,
                label: ServicePresentationFormatter.priceFrom(service.price),
              ),
              _InfoPill(
                icon: Icons.schedule_outlined,
                label: ServicePresentationFormatter.estimatedDuration(
                  service.estimatedDurationMinutes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDetailsPressed,
              child: const Text('Ver detalhes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.goldSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
