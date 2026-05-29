import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_icon_tile.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/premium_text_field.dart';
import '../data/profile_api.dart';
import '../data/profile_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _birthDateController = TextEditingController();

  late final ProfileApi _profileApi;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  CustomerProfileModel? _profile;
  DateTime? _birthDate;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileApi = ProfileApi(apiClient: context.read<ApiClient>());
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileApi.getMyProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _birthDate = profile.birthDate;
        _fullNameController.text = profile.fullName;
        _phoneController.text = profile.phone;
        _documentController.text = profile.documentNumber;
        _birthDateController.text = profile.birthDate == null
            ? ''
            : _dateFormat.format(profile.birthDate!.toLocal());
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
        _errorMessage = 'Não foi possível carregar seu perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _birthDate = picked;
      _birthDateController.text = _dateFormat.format(picked);
    });
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
      final profile = await _profileApi.updateMyProfile(
        UpdateCustomerProfileRequest(
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          documentNumber: _documentController.text.trim(),
          birthDate: _birthDate,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
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
        _errorMessage = 'Não foi possível atualizar o perfil agora.';
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
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Form(
                          key: _formKey,
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
                                      icon: Icons.person_rounded,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Meu perfil',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _profile?.email ?? '',
                                            style: const TextStyle(
                                              color: AppColors.goldSoft,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_errorMessage != null) ...[
                                _ErrorPanel(message: _errorMessage!),
                                const SizedBox(height: 14),
                              ],
                              PremiumCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PremiumTextField(
                                      controller: _fullNameController,
                                      labelText: 'Nome completo',
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if ((value ?? '').trim().isEmpty) {
                                          return 'Nome é obrigatório';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    PremiumTextField(
                                      controller: _phoneController,
                                      labelText: 'Telefone',
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: Icons.phone_outlined,
                                    ),
                                    const SizedBox(height: 14),
                                    PremiumTextField(
                                      controller: _documentController,
                                      labelText: 'Documento',
                                      keyboardType: TextInputType.text,
                                      prefixIcon: Icons.badge_outlined,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _birthDateController,
                                      readOnly: true,
                                      onTap: _pickBirthDate,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Data de nascimento',
                                        prefixIcon: Icon(Icons.cake_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    PremiumButton(
                                      text: 'Salvar perfil',
                                      isLoading: _isSaving,
                                      onPressed: _submit,
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          context.push('/addresses'),
                                      icon: const Icon(
                                        Icons.location_on_outlined,
                                      ),
                                      label: const Text('Gerenciar endereços'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
