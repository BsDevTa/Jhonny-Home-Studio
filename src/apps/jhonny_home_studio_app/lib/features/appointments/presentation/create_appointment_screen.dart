import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_empty_state.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../addresses/data/address_models.dart';
import '../../addresses/data/addresses_api.dart';
import '../../services/data/service_models.dart';
import '../../services/data/services_api.dart';
import '../data/appointment_models.dart';
import '../data/appointments_api.dart';
import 'widgets/available_slot_card.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key, this.serviceId});

  final String? serviceId;

  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  late final AppointmentsApi _appointmentsApi;
  late final ServicesApi _servicesApi;
  late final AddressesApi _addressesApi;

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<ServiceModel> _services = const [];
  List<AddressModel> _addresses = const [];
  List<AvailableSlotModel> _slots = const [];

  ServiceModel? _selectedService;
  AddressModel? _selectedAddress;
  DateTime? _selectedDate;
  AvailableSlotModel? _selectedSlot;

  bool _isLoading = true;
  bool _isLoadingSlots = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _appointmentsApi = AppointmentsApi(apiClient: apiClient);
    _servicesApi = ServicesApi(apiClient: apiClient);
    _addressesApi = AddressesApi(apiClient: apiClient);
    _loadInitialData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _servicesApi.getActiveServices(),
        _addressesApi.getMyAddresses(),
      ]);

      if (!mounted) {
        return;
      }

      final services = results[0] as List<ServiceModel>;
      final addresses = results[1] as List<AddressModel>;

      ServiceModel? initialService;
      if (widget.serviceId != null && widget.serviceId!.isNotEmpty) {
        for (final service in services) {
          if (service.id == widget.serviceId) {
            initialService = service;
            break;
          }
        }
      }

      addresses.sort((a, b) {
        if (a.isDefault == b.isDefault) {
          return 0;
        }
        return a.isDefault ? -1 : 1;
      });

      setState(() {
        _services = services;
        _addresses = addresses;
        _selectedService = initialService;
        _selectedAddress = addresses.isEmpty ? null : addresses.first;
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
        _errorMessage = 'Não foi possível preparar o agendamento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      _dateController.text = _dateFormat.format(_selectedDate!);
      _selectedSlot = null;
    });

    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    if (_selectedService == null || _selectedDate == null) {
      return;
    }

    setState(() {
      _isLoadingSlots = true;
      _slots = const [];
      _errorMessage = null;
    });

    try {
      final slots = await _appointmentsApi.getAvailableSlots(
        _selectedService!.id,
        _selectedDate!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _slots = slots
            .where((slot) => slot.isAvailable)
            .toList(growable: false);
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
        _errorMessage = 'Não foi possível carregar os horários disponíveis.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedService == null) {
      _showMessage('Selecione um serviço para continuar.');
      return;
    }

    if (_selectedAddress == null) {
      _showMessage('Selecione um endereço para continuar.');
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Selecione a data do agendamento.');
      return;
    }

    if (_selectedSlot?.startAt == null) {
      _showMessage('Selecione um horário disponível.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _appointmentsApi.createAppointment(
        CreateAppointmentRequest(
          serviceId: _selectedService!.id,
          addressId: _selectedAddress!.id,
          scheduledAt: _selectedSlot!.startAt!,
          customerNotes: _notesController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seu horário foi solicitado. Aguarde a confirmação do estúdio.',
          ),
        ),
      );
      context.go('/appointments/my');
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
        _errorMessage = 'Não foi possível concluir o agendamento.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _goToAddresses() async {
    await context.push('/addresses');
    if (!mounted) {
      return;
    }
    _loadInitialData();
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
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadInitialData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PageHeader(
                                title: 'Novo agendamento',
                                subtitle:
                                    'Uma experiência simples, clara e elegante em poucos passos.',
                                onBack: () => context.pop(),
                              ),
                              const SizedBox(height: 12),
                              if (_errorMessage != null) ...[
                                _ErrorBanner(message: _errorMessage!),
                                const SizedBox(height: 12),
                              ],
                              _StepCard(
                                step: '1',
                                title: 'Serviço',
                                subtitle: 'Escolha o atendimento desejado.',
                                child: DropdownButtonFormField<ServiceModel>(
                                  initialValue: _selectedService,
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.expand_more_rounded,
                                    size: 18,
                                  ),
                                  dropdownColor: AppColors.surfaceElevated,
                                  items: _services
                                      .map(
                                        (service) =>
                                            DropdownMenuItem<ServiceModel>(
                                              value: service,
                                              child: Text(service.name),
                                            ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedService = value;
                                      _selectedSlot = null;
                                    });
                                    if (_selectedDate != null) {
                                      _loadSlots();
                                    }
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Serviço',
                                    prefixIcon: Icon(
                                      Icons.spa_outlined,
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              if (_selectedService != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${_currencyFormat.format(_selectedService!.price)} • ${_selectedService!.estimatedDurationMinutes} min',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              _StepCard(
                                step: '2',
                                title: 'Endereço',
                                subtitle: 'Onde você quer ser atendida.',
                                child: _addresses.isEmpty
                                    ? PremiumEmptyState(
                                        icon: Icons.location_off_outlined,
                                        title: 'Nenhum endereço cadastrado',
                                        message:
                                            'Adicione um endereço para continuar com o agendamento.',
                                        actionLabel: 'Cadastrar endereço',
                                        onAction: _goToAddresses,
                                      )
                                    : Column(
                                        children: _addresses
                                            .map(
                                              (address) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: _SelectableAddressCard(
                                                  address: address,
                                                  selected:
                                                      _selectedAddress ==
                                                      address,
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedAddress =
                                                          address;
                                                    });
                                                  },
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              _StepCard(
                                step: '3',
                                title: 'Data',
                                subtitle: 'Defina o dia do atendimento.',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _selectDate,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                          color: AppColors.goldSoft,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _selectedDate == null
                                                ? 'Selecionar data'
                                                : _dateFormat.format(
                                                    _selectedDate!,
                                                  ),
                                            style: TextStyle(
                                              color: _selectedDate == null
                                                  ? AppColors.textSecondary
                                                  : AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _StepCard(
                                step: '4',
                                title: 'Horário',
                                subtitle: 'Escolha um horário disponível.',
                                child: _isLoadingSlots
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: AppColors.gold,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : _selectedDate == null
                                    ? const PremiumEmptyState(
                                        icon: Icons.schedule_outlined,
                                        title: 'Escolha uma data',
                                        message:
                                            'Depois de escolher o dia, os horários disponíveis aparecerão aqui.',
                                      )
                                    : _slots.isEmpty
                                    ? PremiumEmptyState(
                                        icon: Icons.hourglass_empty,
                                        title:
                                            'Não há atendimento disponível nesta data',
                                        message:
                                            'Nenhum horário disponível para esta data. Tente escolher outro dia.',
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _slots
                                            .map(
                                              (slot) => AvailableSlotCard(
                                                slot: slot,
                                                selected: _selectedSlot == slot,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedSlot = slot;
                                                  });
                                                },
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              _StepCard(
                                step: '5',
                                title: 'Observação',
                                subtitle:
                                    'Deixe um recado curto se houver algo importante.',
                                child: TextFormField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  minLines: 2,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Observação',
                                    hintText:
                                        'Ex.: Portão branco, tocar interfone',
                                    prefixIcon: Icon(
                                      Icons.edit_note_outlined,
                                      size: 18,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _StepCard(
                                step: '6',
                                title: 'Confirmação',
                                subtitle: 'Revise os dados antes de finalizar.',
                                child: _ConfirmationSummary(
                                  service: _selectedService,
                                  address: _selectedAddress,
                                  date: _selectedDate,
                                  slot: _selectedSlot,
                                  currencyFormat: _currencyFormat,
                                  dateFormat: _dateFormat,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 48,
                                child: PremiumButton(
                                  text: 'Confirmar agendamento',
                                  isLoading: _isSaving,
                                  onPressed: _submit,
                                ),
                              ),
                            ],
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_rounded, size: 18),
            ),
          ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String step;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    width: 0.6,
                  ),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      color: AppColors.goldSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SelectableAddressCard extends StatelessWidget {
  const _SelectableAddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final AddressModel address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.gold.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.20)
                  : AppColors.border,
              width: 0.6,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
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
                  size: 18,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.fullAddress,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Endereço padrão',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: selected ? AppColors.gold : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationSummary extends StatelessWidget {
  const _ConfirmationSummary({
    required this.service,
    required this.address,
    required this.date,
    required this.slot,
    required this.currencyFormat,
    required this.dateFormat,
  });

  final ServiceModel? service;
  final AddressModel? address;
  final DateTime? date;
  final AvailableSlotModel? slot;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final serviceName = service?.name ?? 'Selecione um serviço';
    final servicePrice = service == null
        ? '—'
        : currencyFormat.format(service!.price);
    final serviceDuration = service == null
        ? '—'
        : '${service!.estimatedDurationMinutes} min';
    final addressText = address?.fullAddress ?? 'Selecione um endereço';
    final dateText = date == null
        ? 'Selecione uma data'
        : dateFormat.format(date!);
    final timeText = slot?.startAt == null
        ? 'Selecione um horário'
        : DateFormat('HH:mm').format(slot!.startAt!.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: 'Serviço', value: serviceName),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Endereço', value: addressText),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Data', value: dateText),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Horário', value: timeText),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryPill(label: 'Preço', value: servicePrice),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryPill(label: 'Duração', value: serviceDuration),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
