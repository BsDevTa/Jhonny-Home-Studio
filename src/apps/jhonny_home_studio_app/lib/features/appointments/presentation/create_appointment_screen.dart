import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_text_field.dart';
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
        const SnackBar(content: Text('Agendamento criado com sucesso.')),
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
      appBar: AppBar(title: const Text('Novo agendamento')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              Color(0xFF101010),
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
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadInitialData,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      if (_errorMessage != null)
                        _ErrorBanner(message: _errorMessage!),
                      if (_errorMessage != null) const SizedBox(height: 14),
                      _SectionTitle(title: '1. Escolha o serviço'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ServiceModel>(
                        initialValue: _selectedService,
                        items: _services
                            .map(
                              (service) => DropdownMenuItem<ServiceModel>(
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
                          prefixIcon: Icon(Icons.spa_outlined),
                        ),
                      ),
                      if (_selectedService != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_currencyFormat.format(_selectedService!.price)} • ${_selectedService!.estimatedDurationMinutes} min',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _SectionTitle(title: '2. Escolha o endereço'),
                      const SizedBox(height: 8),
                      if (_addresses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Você ainda não possui endereço cadastrado.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _goToAddresses,
                                child: const Text('Cadastrar endereço'),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<AddressModel>(
                          initialValue: _selectedAddress,
                          items: _addresses
                              .map(
                                (address) => DropdownMenuItem<AddressModel>(
                                  value: address,
                                  child: Text(
                                    '${address.street}, ${address.number} - ${address.city}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            setState(() {
                              _selectedAddress = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      const SizedBox(height: 18),
                      _SectionTitle(title: '3. Escolha data e horário'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: _selectDate,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoadingSlots)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          ),
                        )
                      else if (_selectedDate != null && _slots.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Não há horários disponíveis para a data selecionada.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
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
                      const SizedBox(height: 18),
                      _SectionTitle(title: '4. Observações (opcional)'),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        controller: _notesController,
                        labelText: 'Ex.: Portão branco, tocar interfone',
                        prefixIcon: Icons.edit_note_outlined,
                      ),
                      const SizedBox(height: 22),
                      PremiumButton(
                        text: 'Confirmar agendamento',
                        isLoading: _isSaving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
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
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
