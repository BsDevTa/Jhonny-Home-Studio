import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_empty_state.dart';
import '../../../shared/widgets/premium_icon_tile.dart';
import '../../../shared/widgets/premium_status_badge.dart';
import '../data/appointment_models.dart';
import '../data/appointments_api.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late final AppointmentsApi _appointmentsApi;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  AppointmentModel? _appointment;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _appointmentsApi = AppointmentsApi(apiClient: context.read<ApiClient>());
    _loadDetail();
  }

  bool _canCancel(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'pending' ||
        normalized == 'waitingpayment' ||
        normalized == 'confirmed';
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointment = await _appointmentsApi.getMyAppointmentById(
        widget.appointmentId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointment = appointment;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Não foi possível carregar os detalhes do agendamento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final appointment = _appointment;
    if (appointment == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar agendamento'),
          content: const Text('Deseja realmente cancelar este agendamento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await _appointmentsApi.cancelMyAppointment(appointment.id);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado com sucesso.')),
      );
      _loadDetail();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    final canCancel = appointment != null && _canCancel(appointment.status);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.surfaceElevated,
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                )
              : _errorMessage != null
              ? _ErrorCard(message: _errorMessage!, onRetry: _loadDetail)
              : appointment == null
              ? const _ErrorCard(message: 'Agendamento não encontrado.')
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PremiumCard(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.surface,
                                AppColors.surfaceElevated,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            child: Row(
                              children: [
                                const PremiumIconTile(
                                  icon: Icons.calendar_month_rounded,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Detalhe do agendamento',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        appointment.serviceName,
                                        style: const TextStyle(
                                          color: AppColors.goldSoft,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PremiumStatusBadge(status: appointment.status),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Serviço',
                            value: appointment.serviceName,
                          ),
                          _DetailRow(
                            label: 'Status',
                            value: appointment.status,
                          ),
                          _DetailRow(
                            label: 'Data e horário',
                            value: appointment.scheduledAt == null
                                ? 'Não informado'
                                : _dateFormat.format(
                                    appointment.scheduledAt!.toLocal(),
                                  ),
                          ),
                          _DetailRow(
                            label: 'Preço',
                            value: _currencyFormat.format(
                              appointment.servicePriceSnapshot,
                            ),
                          ),
                          _DetailRow(
                            label: 'Duração',
                            value:
                                '${appointment.estimatedDurationMinutesSnapshot} min',
                          ),
                          _DetailRow(
                            label: 'Endereço',
                            value: appointment.addressText,
                          ),
                          _DetailRow(
                            label: 'Observações',
                            value: appointment.customerNotes.trim().isEmpty
                                ? 'Sem observações'
                                : appointment.customerNotes,
                          ),
                          const SizedBox(height: 18),
                          if (canCancel)
                            PremiumButton(
                              text: 'Cancelar agendamento',
                              isLoading: _isCancelling,
                              onPressed: _cancelAppointment,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PremiumEmptyState(
          icon: Icons.error_outline,
          title: 'Não foi possível carregar',
          message: message,
          actionLabel: onRetry == null ? null : 'Tentar novamente',
          onAction: onRetry,
        ),
      ),
    );
  }
}
