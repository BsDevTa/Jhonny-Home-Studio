import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/appointment_models.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.serviceName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusBadge(status: appointment.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              appointment.scheduledAt == null
                  ? 'Data não informada'
                  : _dateFormat.format(appointment.scheduledAt!.toLocal()),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoTag(
                  label: _currencyFormat.format(
                    appointment.servicePriceSnapshot,
                  ),
                ),
                _InfoTag(
                  label: '${appointment.estimatedDurationMinutesSnapshot} min',
                ),
              ],
            ),
            const SizedBox(height: 14),
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'pending' => AppColors.gold,
      'waitingpayment' => AppColors.quartz,
      'confirmed' => AppColors.success,
      'completed' => Colors.teal,
      'canceled' => AppColors.error,
      'rejected' => AppColors.error,
      'noshow' => AppColors.error,
      'inprogress' => AppColors.goldSoft,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
