import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../data/admin_mobile_api.dart';
import '../../presentation/admin_mobile_screens.dart';

AdminMobileApi _api(BuildContext context) =>
    AdminMobileApi(apiClient: context.read<ApiClient>());

String _text(Map<String, dynamic> item, String key) =>
    item[key]?.toString() ?? '';

bool _flag(Map<String, dynamic> item, String key, [bool fallback = false]) =>
    item[key] is bool ? item[key] as bool : fallback;

class AdminProductCategoryFormScreen extends StatefulWidget {
  const AdminProductCategoryFormScreen({super.key, this.id});

  final String? id;

  @override
  State<AdminProductCategoryFormScreen> createState() =>
      _AdminProductCategoryFormScreenState();
}

class _AdminProductCategoryFormScreenState
    extends State<AdminProductCategoryFormScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final displayOrder = TextEditingController(text: '0');
  bool active = true;
  bool loading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final category = await _api(context).getMarketplaceCategory(widget.id!);
      if (!mounted) return;
      setState(() {
        name.text = _text(category, 'name');
        description.text = _text(category, 'description');
        displayOrder.text = _text(category, 'displayOrder').isEmpty
            ? '0'
            : _text(category, 'displayOrder');
        active = _flag(category, 'isActive', true);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da categoria.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await _api(context).saveMarketplaceCategory(widget.id, {
        'name': name.text.trim(),
        'description': description.text.trim().isEmpty
            ? null
            : description.text.trim(),
        'displayOrder': int.tryParse(displayOrder.text.trim()) ?? 0,
        'isActive': active,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Categoria da loja salva.')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    displayOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: widget.id == null
          ? 'Nova categoria da loja'
          : 'Editar categoria da loja',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayOrder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ordem de exibição',
                  ),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                  title: const Text('Ativo'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'Salvando...' : 'Salvar categoria'),
                ),
              ],
            ),
    );
  }
}
