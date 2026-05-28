import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/appointment_models.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/widgets/premium_status_badge.dart';

class AppointmentCard extends StatelessWidget {
  AppointmentCard({
    super.key,
    required this.appointment,
    required this.onDetails,
    this.onCancel,
  }) : _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$'),
       _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  final AppointmentListModel appointment;
  final VoidCallback onDetails;
  final VoidCallback? onCancel;

  final NumberFormat _currencyFormat;
  final DateFormat _dateFormat;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.serviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              PremiumStatusBadge(status: appointment.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            appointment.scheduledAt == null
                ? 'Data não informada'
                : _dateFormat.format(appointment.scheduledAt!.toLocal()),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoTag(
                label: _currencyFormat.format(appointment.servicePriceSnapshot),
              ),
              _InfoTag(
                label: '${appointment.estimatedDurationMinutesSnapshot} min',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: onDetails,
                child: const Text('Ver detalhes'),
              ),
              if (onCancel != null)
                OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
