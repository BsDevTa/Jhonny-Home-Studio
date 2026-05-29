import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_empty_state.dart';
import '../../../shared/widgets/premium_icon_tile.dart';
import '../data/appointment_models.dart';
import '../data/appointments_api.dart';
import 'widgets/appointment_card.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  late final AppointmentsApi _appointmentsApi;

  List<AppointmentListModel> _appointments = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _appointmentsApi = AppointmentsApi(apiClient: context.read<ApiClient>());
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appointments = await _appointmentsApi.getMyAppointments();
      if (!mounted) {
        return;
      }

      appointments.sort((a, b) {
        final left = a.scheduledAt;
        final right = b.scheduledAt;
        if (left == null && right == null) {
          return 0;
        }
        if (left == null) {
          return 1;
        }
        if (right == null) {
          return -1;
        }
        return right.compareTo(left);
      });

      setState(() {
        _appointments = appointments;
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
        _errorMessage = 'Não foi possível carregar seus agendamentos.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _canCancel(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'pending' ||
        normalized == 'waitingpayment' ||
        normalized == 'confirmed';
  }

  Future<void> _cancelAppointment(AppointmentListModel appointment) async {
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

    try {
      await _appointmentsApi.cancelMyAppointment(appointment.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado com sucesso.')),
      );
      _loadAppointments();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openDetails(AppointmentListModel appointment) {
    context.push('/appointments/my/${appointment.id}');
  }

  @override
  Widget build(BuildContext context) {
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
          child: RefreshIndicator(
            color: AppColors.gold,
            onRefresh: _loadAppointments,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              children: [
                PremiumCard(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.surfaceElevated],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    children: [
                      const PremiumIconTile(icon: Icons.calendar_month_rounded),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meus agendamentos',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Acompanhe seus atendimentos com uma visão mais refinada.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  )
                else if (_errorMessage != null)
                  PremiumEmptyState(
                    icon: Icons.error_outline,
                    title: 'Falha ao carregar',
                    message: _errorMessage!,
                    actionLabel: 'Tentar novamente',
                    onAction: _loadAppointments,
                  )
                else if (_appointments.isEmpty)
                  const PremiumEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Nenhum agendamento encontrado',
                    message: 'Você ainda não possui agendamentos.',
                  )
                else
                  ..._appointments.map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AppointmentCard(
                        appointment: appointment,
                        onDetails: () => _openDetails(appointment),
                        onCancel: _canCancel(appointment.status)
                            ? () => _cancelAppointment(appointment)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
