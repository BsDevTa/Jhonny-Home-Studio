import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/premium_card.dart';
import '../../../shared/widgets/premium_empty_state.dart';
import '../../../shared/widgets/premium_icon_tile.dart';
import '../data/address_models.dart';
import '../data/addresses_api.dart';
import 'widgets/address_card.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late final AddressesApi _addressesApi;

  List<AddressModel> _addresses = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addressesApi = AddressesApi(apiClient: context.read<ApiClient>());
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addresses = await _addressesApi.getMyAddresses();
      if (!mounted) {
        return;
      }

      addresses.sort((a, b) {
        if (a.isDefault == b.isDefault) {
          return 0;
        }
        return a.isDefault ? -1 : 1;
      });

      setState(() {
        _addresses = addresses;
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
        _errorMessage = 'Não foi possível carregar os endereços.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir endereço'),
          content: const Text('Deseja excluir este endereço?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _addressesApi.deleteAddress(address.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço removido com sucesso.')),
      );
      _loadAddresses();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _setDefault(AddressModel address) async {
    try {
      await _addressesApi.setDefaultAddress(address.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço padrão atualizado.')),
      );
      _loadAddresses();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openNewAddress() async {
    await context.push('/addresses/new');
    if (!mounted) {
      return;
    }
    _loadAddresses();
  }

  Future<void> _openEditAddress(AddressModel address) async {
    await context.push('/addresses/${address.id}/edit');
    if (!mounted) {
      return;
    }
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewAddress,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Novo endereço'),
      ),
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
            onRefresh: _loadAddresses,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 90),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PremiumCard(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.surfaceElevated],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    children: [
                      const PremiumIconTile(icon: Icons.location_on_rounded),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meus endereços',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cadastre os locais onde você deseja receber atendimento.',
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
                    onAction: _loadAddresses,
                  )
                else if (_addresses.isEmpty)
                  PremiumEmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'Nenhum endereço cadastrado',
                    message: 'Cadastre seu primeiro endereço para agendar.',
                    actionLabel: 'Cadastrar endereço',
                    onAction: _openNewAddress,
                  )
                else
                  ..._addresses.map(
                    (address) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: AddressCard(
                        address: address,
                        onEdit: () => _openEditAddress(address),
                        onDelete: () => _deleteAddress(address),
                        onSetDefault: () => _setDefault(address),
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
