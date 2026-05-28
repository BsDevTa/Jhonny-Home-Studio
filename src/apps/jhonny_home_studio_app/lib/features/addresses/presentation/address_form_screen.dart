import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_text_field.dart';
import '../data/address_models.dart';
import '../data/addresses_api.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  bool get isEditing => addressId != null && addressId!.isNotEmpty;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _complementController = TextEditingController();
  final _referenceController = TextEditingController();

  late final AddressesApi _addressesApi;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _addressesApi = AddressesApi(apiClient: context.read<ApiClient>());
    if (widget.isEditing) {
      _loadAddress();
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _complementController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final address = await _addressesApi.getMyAddressById(widget.addressId!);
      if (!mounted) {
        return;
      }

      setState(() {
        _streetController.text = address.street;
        _numberController.text = address.number;
        _neighborhoodController.text = address.neighborhood;
        _cityController.text = address.city;
        _stateController.text = address.state;
        _zipCodeController.text = address.zipCode;
        _complementController.text = address.complement;
        _referenceController.text = address.referencePoint;
        _isDefault = address.isDefault;
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
        _errorMessage = 'Não foi possível carregar o endereço.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (widget.isEditing) {
        await _addressesApi.updateAddress(
          widget.addressId!,
          UpdateAddressRequest(
            street: _streetController.text.trim(),
            number: _numberController.text.trim(),
            neighborhood: _neighborhoodController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            zipCode: _zipCodeController.text.trim(),
            complement: _complementController.text.trim(),
            referencePoint: _referenceController.text.trim(),
            isDefault: _isDefault,
          ),
        );
      } else {
        await _addressesApi.createAddress(
          CreateAddressRequest(
            street: _streetController.text.trim(),
            number: _numberController.text.trim(),
            neighborhood: _neighborhoodController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            zipCode: _zipCodeController.text.trim(),
            complement: _complementController.text.trim(),
            referencePoint: _referenceController.text.trim(),
          ),
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Endereço atualizado com sucesso.'
                : 'Endereço cadastrado com sucesso.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
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
        _errorMessage = 'Não foi possível salvar o endereço.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        PremiumTextField(
                          controller: _streetController,
                          labelText: 'Rua',
                          prefixIcon: Icons.map_outlined,
                          validator: _requiredField,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _numberController,
                          labelText: 'Número',
                          prefixIcon: Icons.pin_outlined,
                          validator: _requiredField,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _neighborhoodController,
                          labelText: 'Bairro',
                          prefixIcon: Icons.location_city_outlined,
                          validator: _requiredField,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _cityController,
                          labelText: 'Cidade',
                          prefixIcon: Icons.location_on_outlined,
                          validator: _requiredField,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _stateController,
                          labelText: 'Estado',
                          prefixIcon: Icons.flag_outlined,
                          validator: _requiredField,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _zipCodeController,
                          labelText: 'CEP',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.markunread_mailbox_outlined,
                          validator: _requiredField,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _complementController,
                          labelText: 'Complemento (opcional)',
                          prefixIcon: Icons.add_business_outlined,
                        ),
                        const SizedBox(height: 14),
                        PremiumTextField(
                          controller: _referenceController,
                          labelText: 'Ponto de referência (opcional)',
                          prefixIcon: Icons.place_outlined,
                        ),
                        if (widget.isEditing) ...[
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.gold,
                            title: const Text('Endereço padrão'),
                            value: _isDefault,
                            onChanged: (value) {
                              setState(() {
                                _isDefault = value;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        PremiumButton(
                          text: widget.isEditing
                              ? 'Salvar alterações'
                              : 'Cadastrar endereço',
                          isLoading: _isSaving,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  String? _requiredField(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }
}
