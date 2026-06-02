import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/address_models.dart';
import '../../../../shared/widgets/premium_card.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    this.isDeleting = false,
  });

  final AddressModel address;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onSetDefault;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    width: 0.6,
                  ),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Endereço',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.10),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.18),
                      width: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Padrão',
                    style: TextStyle(
                      color: AppColors.goldSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.fullAddress,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
              if (!address.isDefault)
                OutlinedButton.icon(
                  onPressed: onSetDefault,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Definir padrão'),
                ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(isDeleting ? 'Excluindo...' : 'Excluir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
