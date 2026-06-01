import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_text_field.dart';
import '../data/address_models.dart';
import '../data/addresses_api.dart';
import '../data/cep_api.dart';

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
  final _zipCodeFocusNode = FocusNode();

  late final AddressesApi _addressesApi;
  late final CepApi _cepApi;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearchingCep = false;
  String? _errorMessage;
  String? _cepMessage;
  bool _cepLookupSucceeded = false;
  bool _isDefault = false;
  Timer? _cepDebounce;
  String? _lastQueriedCep;
  int _cepRequestId = 0;

  @override
  void initState() {
    super.initState();
    _addressesApi = AddressesApi(apiClient: context.read<ApiClient>());
    _cepApi = CepApi();
    _zipCodeFocusNode.addListener(_handleZipCodeFocusChange);
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
    _zipCodeFocusNode
      ..removeListener(_handleZipCodeFocusChange)
      ..dispose();
    _cepDebounce?.cancel();
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
        _zipCodeController.text = _formatCep(address.zipCode);
        _complementController.text = address.complement;
        _referenceController.text = address.referencePoint;
        _isDefault = address.isDefault;
        _lastQueriedCep = _onlyDigits(address.zipCode);
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

  void _handleZipCodeFocusChange() {
    if (!_zipCodeFocusNode.hasFocus) {
      _lookupCep(_zipCodeController.text, showInvalidMessage: true);
    }
  }

  void _handleZipCodeChanged(String value) {
    _cepDebounce?.cancel();
    final cep = _onlyDigits(value);

    if (cep.length != 8) {
      _cepRequestId++;
      if (mounted) {
        setState(() {
          _isSearchingCep = false;
          _cepMessage = null;
          _cepLookupSucceeded = false;
        });
      }
      return;
    }

    _cepDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _lookupCep(cep),
    );
  }

  Future<void> _lookupCep(
    String value, {
    bool showInvalidMessage = false,
  }) async {
    final cep = _onlyDigits(value);
    if (cep.length != 8) {
      if (showInvalidMessage && cep.isNotEmpty && mounted) {
        setState(() {
          _cepMessage = 'Informe um CEP válido com 8 números.';
          _cepLookupSucceeded = false;
        });
      }
      return;
    }

    if (_lastQueriedCep == cep) {
      return;
    }

    _cepDebounce?.cancel();
    _lastQueriedCep = cep;
    final requestId = ++_cepRequestId;

    setState(() {
      _isSearchingCep = true;
      _cepMessage = 'Buscando CEP...';
      _cepLookupSucceeded = false;
    });

    try {
      final address = await _cepApi.getAddressByCep(cep);
      if (!mounted ||
          requestId != _cepRequestId ||
          _onlyDigits(_zipCodeController.text) != cep) {
        return;
      }

      setState(() {
        _streetController.text = address.logradouro;
        _neighborhoodController.text = address.bairro;
        _cityController.text = address.localidade;
        _stateController.text = address.uf;
        if (_complementController.text.trim().isEmpty &&
            address.complemento.trim().isNotEmpty) {
          _complementController.text = address.complemento;
        }
        _cepMessage = 'Endereço encontrado.';
        _cepLookupSucceeded = true;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _cepRequestId) {
        return;
      }
      setState(() {
        _cepMessage = error.message == 'CEP não encontrado.'
            ? 'CEP não encontrado. Preencha manualmente.'
            : error.message;
        _cepLookupSucceeded = false;
      });
    } catch (_) {
      if (!mounted || requestId != _cepRequestId) {
        return;
      }
      setState(() {
        _cepMessage = 'Não foi possível consultar o CEP agora.';
        _cepLookupSucceeded = false;
      });
    } finally {
      if (mounted && requestId == _cepRequestId) {
        setState(() {
          _isSearchingCep = false;
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
                          controller: _zipCodeController,
                          labelText: 'CEP',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.markunread_mailbox_outlined,
                          suffixIcon: _isSearchingCep
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: AppColors.gold,
                                      strokeWidth: 1.8,
                                    ),
                                  ),
                                )
                              : null,
                          focusNode: _zipCodeFocusNode,
                          inputFormatters: const [CepInputFormatter()],
                          onChanged: _handleZipCodeChanged,
                          validator: _zipCodeValidator,
                        ),
                        if (_cepMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _cepMessage!,
                            style: TextStyle(
                              color: _cepLookupSucceeded
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
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

  String? _zipCodeValidator(String? value) {
    if (_onlyDigits(value ?? '').length != 8) {
      return 'Informe um CEP válido com 8 números';
    }
    return null;
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _formatCep(String value) {
    final digits = _onlyDigits(value);
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    if (limitedDigits.length <= 5) {
      return limitedDigits;
    }
    return '${limitedDigits.substring(0, 5)}-${limitedDigits.substring(5)}';
  }
}

class CepInputFormatter extends TextInputFormatter {
  const CepInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = limitedDigits.length <= 5
        ? limitedDigits
        : '${limitedDigits.substring(0, 5)}-${limitedDigits.substring(5)}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
