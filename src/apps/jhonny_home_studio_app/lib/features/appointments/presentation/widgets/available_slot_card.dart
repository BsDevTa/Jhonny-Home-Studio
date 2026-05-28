import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/appointment_models.dart';

class AvailableSlotCard extends StatelessWidget {
  AvailableSlotCard({
    super.key,
    required this.slot,
    required this.selected,
    required this.onTap,
  }) : _timeFormat = DateFormat('HH:mm');

  final AvailableSlotModel slot;
  final bool selected;
  final VoidCallback onTap;
  final DateFormat _timeFormat;

  @override
  Widget build(BuildContext context) {
    final start = slot.startAt;
    final end = slot.endAt;
    final label = start == null || end == null
        ? 'Horário indisponível'
        : '${_timeFormat.format(start.toLocal())} - ${_timeFormat.format(end.toLocal())}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: slot.isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : slot.isAvailable
              ? AppColors.surfaceElevated
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.goldSoft
                : slot.isAvailable
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? Colors.black
                : slot.isAvailable
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
