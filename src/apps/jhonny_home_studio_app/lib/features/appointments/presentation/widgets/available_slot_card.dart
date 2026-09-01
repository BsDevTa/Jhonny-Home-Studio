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
    final range = start == null || end == null
        ? 'Horário indisponível'
        : '${_timeFormat.format(start.toLocal())} - ${_timeFormat.format(end.toLocal())}';
    final label = slot.name.trim().isEmpty || start == null || end == null
        ? range
        : '${slot.name}\n$range';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: slot.isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : slot.isAvailable
              ? AppColors.surfaceElevated
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.goldSoft
                : slot.isAvailable
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.45),
            width: 0.6,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? AppColors.textPrimary
                : slot.isAvailable
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
