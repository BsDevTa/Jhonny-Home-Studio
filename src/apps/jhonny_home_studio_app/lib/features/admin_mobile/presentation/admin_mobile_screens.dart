import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/admin_mobile_api.dart';

AdminMobileApi _api(BuildContext context) =>
    AdminMobileApi(apiClient: context.read<ApiClient>());

String _text(Map<String, dynamic> item, String key) =>
    item[key]?.toString() ?? '';
bool _flag(Map<String, dynamic> item, String key, [bool fallback = false]) =>
    item[key] is bool ? item[key] as bool : fallback;
String _date(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null
      ? '-'
      : DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
}

class AdminMobileHomeScreen extends StatefulWidget {
  const AdminMobileHomeScreen({super.key});

  @override
  State<AdminMobileHomeScreen> createState() => _AdminMobileHomeScreenState();
}

class _AdminMobileHomeScreenState extends State<AdminMobileHomeScreen> {
  bool loading = true;
  String error = '';
  Map<String, int> counts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final api = _api(context);
      final values = await Future.wait([
        api.getCategories(),
        api.getServices(),
        api.getAppointments(),
        api.getCustomers(),
        api.getStories(),
      ]);
      if (!mounted) return;
      setState(() {
        counts = {
          'Categorias': values[0].length,
          'Serviços': values[1].length,
          'Agenda': values[2]
              .where((x) => _text(x, 'status') == 'Pending')
              .length,
          'Clientes': values[3].length,
          'Stories': values[4].where((x) => _flag(x, 'isActive')).length,
        };
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Admin Mobile',
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Gestão rápida do estúdio',
              style: TextStyle(
                color: AppColors.champagne,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Acesse os módulos administrativos pelo celular.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            if (loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            if (error.isNotEmpty) _ErrorCard(message: error),
            ..._modules.map(
              (module) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AdminModuleCard(
                  module: module,
                  count: counts[module.title],
                  onTap: () => context.push(module.path),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Module {
  const _Module(this.title, this.subtitle, this.path, this.icon);
  final String title;
  final String subtitle;
  final String path;
  final IconData icon;
}

const _modules = [
  _Module(
    'Categorias',
    'Organize os tipos de serviço',
    '/admin-mobile/categories',
    Icons.category_outlined,
  ),
  _Module(
    'Serviços',
    'Edite catálogo, preço e duração',
    '/admin-mobile/services',
    Icons.spa_outlined,
  ),
  _Module(
    'Agenda',
    'Acompanhe e altere status',
    '/admin-mobile/appointments',
    Icons.event_note_outlined,
  ),
  _Module(
    'Clientes',
    'Consulte perfis e fidelidade',
    '/admin-mobile/customers',
    Icons.people_outline,
  ),
  _Module(
    'Stories',
    'Publique fotos e vídeos',
    '/admin-mobile/stories',
    Icons.auto_awesome_outlined,
  ),
  _Module(
    'Configurações',
    'Atualize dados do estúdio',
    '/admin-mobile/settings',
    Icons.settings_outlined,
  ),
  _Module(
    'Disponibilidade',
    'Horários e datas bloqueadas',
    '/admin-mobile/availability',
    Icons.schedule_outlined,
  ),
  _Module(
    'Marketplace',
    'Gerencie categorias e produtos da loja.',
    '/admin-mobile/marketplace',
    Icons.shopping_bag_outlined,
  ),
];

class _AdminModuleCard extends StatelessWidget {
  const _AdminModuleCard({
    required this.module,
    required this.onTap,
    this.count,
  });
  final _Module module;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(module.icon, color: AppColors.gold, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  module.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (count != null)
            Text(
              '$count',
              style: const TextStyle(
                color: AppColors.champagne,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

enum AdminListType { categories, services, appointments, customers, stories }

class AdminListScreen extends StatefulWidget {
  const AdminListScreen({super.key, required this.type});
  final AdminListType type;

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen> {
  bool loading = true;
  String error = '';
  String query = '';
  String status = '';
  DateTime? appointmentDate;
  List<Map<String, dynamic>> items = [];

  String get title => switch (widget.type) {
    AdminListType.categories => 'Categorias',
    AdminListType.services => 'Serviços',
    AdminListType.appointments => 'Agenda',
    AdminListType.customers => 'Clientes',
    AdminListType.stories => 'Stories',
  };

  bool get canCreate =>
      widget.type == AdminListType.categories ||
      widget.type == AdminListType.services ||
      widget.type == AdminListType.stories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final api = _api(context);
      items = await switch (widget.type) {
        AdminListType.categories => api.getCategories(),
        AdminListType.services => api.getServices(),
        AdminListType.appointments => api.getAppointments(),
        AdminListType.customers => api.getCustomers(),
        AdminListType.stories => api.getStories(),
      };
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filtered => items
      .where((item) {
        final haystack = item.values.join(' ').toLowerCase();
        final matchesText = haystack.contains(query.trim().toLowerCase());
        final matchesStatus = status.isEmpty || _text(item, 'status') == status;
        final scheduledAt = DateTime.tryParse(
          _text(item, 'scheduledAt'),
        )?.toLocal();
        final matchesDate =
            appointmentDate == null ||
            (scheduledAt != null &&
                scheduledAt.year == appointmentDate!.year &&
                scheduledAt.month == appointmentDate!.month &&
                scheduledAt.day == appointmentDate!.day);
        return matchesText && matchesStatus && matchesDate;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: title,
      floatingActionButton: canCreate
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.background,
              onPressed: () async {
                await context.push('${GoRouterState.of(context).uri.path}/new');
                _load();
              },
              child: const Icon(Icons.add),
            )
          : null,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: widget.type == AdminListType.customers
                    ? 'Buscar nome, e-mail ou telefone'
                    : 'Buscar',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
            if (widget.type == AdminListType.appointments) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ..._statuses.map(
                    (x) => DropdownMenuItem(value: x, child: Text(x)),
                  ),
                ],
                onChanged: (value) => setState(() => status = value ?? ''),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                    initialDate: appointmentDate ?? DateTime.now(),
                  );
                  if (selected != null && mounted) {
                    setState(() => appointmentDate = selected);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  appointmentDate == null
                      ? 'Filtrar por data'
                      : DateFormat('dd/MM/yyyy').format(appointmentDate!),
                ),
              ),
              if (appointmentDate != null)
                TextButton(
                  onPressed: () => setState(() => appointmentDate = null),
                  child: const Text('Limpar data'),
                ),
            ],
            const SizedBox(height: 14),
            if (loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            if (error.isNotEmpty) _ErrorCard(message: error),
            if (!loading && filtered.isEmpty) const _EmptyCard(),
            ...filtered.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItemCard(type: widget.type, item: item, reload: _load),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.type,
    required this.item,
    required this.reload,
  });
  final AdminListType type;
  final Map<String, dynamic> item;
  final Future<void> Function() reload;

  String get id =>
      _text(item, type == AdminListType.customers ? 'customerId' : 'id');
  String get title => switch (type) {
    AdminListType.categories => _text(item, 'name'),
    AdminListType.services => _text(item, 'name'),
    AdminListType.appointments =>
      '${_text(item, 'customerName')} · ${_text(item, 'serviceName')}',
    AdminListType.customers => _text(item, 'fullName'),
    AdminListType.stories => _text(item, 'title'),
  };
  String get subtitle => switch (type) {
    AdminListType.categories => _text(item, 'description'),
    AdminListType.services =>
      '${_text(item, 'serviceCategoryName')} · R\$ ${_text(item, 'price')}',
    AdminListType.appointments =>
      '${_date(item['scheduledAt'])} · ${_statusLabel(_text(item, 'status'))}',
    AdminListType.customers =>
      '${_text(item, 'email')} · ${_text(item, 'phone')}',
    AdminListType.stories =>
      '${_text(item, 'subtitle')} · ordem ${_text(item, 'displayOrder')}',
  };

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      onTap: () async {
        final path = switch (type) {
          AdminListType.categories => '/admin-mobile/categories/$id/edit',
          AdminListType.services => '/admin-mobile/services/$id/edit',
          AdminListType.appointments => '/admin-mobile/appointments/$id',
          AdminListType.customers => '/admin-mobile/customers/$id',
          AdminListType.stories => '/admin-mobile/stories/$id/edit',
        };
        await context.push(path);
        reload();
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (type != AdminListType.appointments)
            _ActiveDot(active: _flag(item, 'isActive')),
          if (type != AdminListType.appointments)
            PopupMenuButton<String>(
              iconColor: AppColors.textSecondary,
              onSelected: (action) async {
                final api = _api(context);
                final isActive = _flag(item, 'isActive');
                if (action == 'toggle') {
                  switch (type) {
                    case AdminListType.categories:
                      await api.toggleCategory(id, !isActive);
                      break;
                    case AdminListType.services:
                      await api.toggleService(id, !isActive);
                      break;
                    case AdminListType.customers:
                      await api.toggleCustomer(id, !isActive);
                      break;
                    case AdminListType.stories:
                      await api.toggleStory(id);
                      break;
                    case AdminListType.appointments:
                      break;
                  }
                } else if (action == 'delete') {
                  switch (type) {
                    case AdminListType.categories:
                      await api.deleteCategory(id);
                      break;
                    case AdminListType.services:
                      await api.deleteService(id);
                      break;
                    case AdminListType.stories:
                      await api.deleteStory(id);
                      break;
                    case AdminListType.customers:
                    case AdminListType.appointments:
                      break;
                  }
                }
                await reload();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(_flag(item, 'isActive') ? 'Desativar' : 'Ativar'),
                ),
                if (type != AdminListType.customers)
                  const PopupMenuItem(value: 'delete', child: Text('Excluir')),
              ],
            ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class AdminCategoryFormScreen extends StatefulWidget {
  const AdminCategoryFormScreen({super.key, this.id});
  final String? id;
  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  bool active = true, saving = false;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) _load();
  }

  Future<void> _load() async {
    final x = await _api(context).getCategory(widget.id!);
    if (!mounted) return;
    setState(() {
      name.text = _text(x, 'name');
      description.text = _text(x, 'description');
      active = _flag(x, 'isActive', true);
    });
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: widget.id == null ? 'Nova categoria' : 'Editar categoria',
    saving: saving,
    onSave: () async {
      setState(() => saving = true);
      await _api(context).saveCategory(widget.id, {
        'name': name.text,
        'description': description.text,
        if (widget.id != null) 'isActive': active,
      });
      if (mounted) this.context.pop();
    },
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
      if (widget.id != null)
        SwitchListTile(
          value: active,
          onChanged: (v) => setState(() => active = v),
          title: const Text('Ativa'),
        ),
    ],
  );
}

class AdminServiceFormScreen extends StatefulWidget {
  const AdminServiceFormScreen({super.key, this.id});
  final String? id;
  @override
  State<AdminServiceFormScreen> createState() => _AdminServiceFormScreenState();
}

class _AdminServiceFormScreenState extends State<AdminServiceFormScreen> {
  final name = TextEditingController(),
      description = TextEditingController(),
      price = TextEditingController(),
      duration = TextEditingController(),
      imageUrl = TextEditingController();
  List<Map<String, dynamic>> categories = [];
  String categoryId = '';
  bool active = true, saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api(context);
    categories = await api.getCategories();
    if (widget.id != null) {
      final x = await api.getService(widget.id!);
      name.text = _text(x, 'name');
      description.text = _text(x, 'description');
      price.text = _text(x, 'price');
      duration.text = _text(x, 'estimatedDurationMinutes');
      imageUrl.text = _text(x, 'imageUrl');
      categoryId = _text(x, 'serviceCategoryId');
      active = _flag(x, 'isActive', true);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    duration.dispose();
    imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: widget.id == null ? 'Novo serviço' : 'Editar serviço',
    saving: saving,
    onSave: () async {
      setState(() => saving = true);
      await _api(context).saveService(widget.id, {
        'serviceCategoryId': categoryId,
        'name': name.text,
        'description': description.text,
        'price': double.tryParse(price.text.replaceAll(',', '.')) ?? 0,
        'estimatedDurationMinutes': int.tryParse(duration.text) ?? 0,
        'imageUrl': imageUrl.text,
        if (widget.id != null) 'isActive': active,
      });
      if (mounted) this.context.pop();
    },
    children: [
      DropdownButtonFormField<String>(
        initialValue: categoryId.isEmpty ? null : categoryId,
        decoration: const InputDecoration(labelText: 'Categoria'),
        items: categories
            .where((x) => _flag(x, 'isActive', true))
            .map(
              (x) => DropdownMenuItem(
                value: _text(x, 'id'),
                child: Text(_text(x, 'name')),
              ),
            )
            .toList(),
        onChanged: (v) => categoryId = v ?? '',
      ),
      const SizedBox(height: 12),
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
        controller: price,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Preço'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: duration,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Duração em minutos'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: imageUrl,
        decoration: const InputDecoration(labelText: 'URL da imagem'),
      ),
      if (widget.id != null)
        SwitchListTile(
          value: active,
          onChanged: (v) => setState(() => active = v),
          title: const Text('Ativo'),
        ),
    ],
  );
}

class AdminAppointmentDetailScreen extends StatefulWidget {
  const AdminAppointmentDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<AdminAppointmentDetailScreen> createState() =>
      _AdminAppointmentDetailScreenState();
}

class _AdminAppointmentDetailScreenState
    extends State<AdminAppointmentDetailScreen> {
  Map<String, dynamic> item = {};
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    item = await _api(context).getAppointment(widget.id);
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    title: 'Detalhe do agendamento',
    child: loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminMobileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Info('Cliente', _text(item, 'customerName')),
                    _Info('Serviço', _text(item, 'serviceName')),
                    _Info('Endereço', _text(item, 'addressText')),
                    _Info('Data', _date(item['scheduledAt'])),
                    _Info('Status', _statusLabel(_text(item, 'status'))),
                    _Info(
                      'Preço',
                      'R\$ ${_text(item, 'servicePriceSnapshot')}',
                    ),
                    _Info(
                      'Duração',
                      '${_text(item, 'estimatedDurationMinutesSnapshot')} min',
                    ),
                    _Info('Observação', _text(item, 'customerNotes')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ..._statusActions(_text(item, 'status')).map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton(
                    onPressed: () async {
                      await _api(context).updateAppointmentStatus(
                        widget.id,
                        action.$1,
                        action.$3,
                      );
                      await _load();
                    },
                    child: Text(action.$2),
                  ),
                ),
              ),
            ],
          ),
  );
}

class AdminCustomerDetailScreen extends StatefulWidget {
  const AdminCustomerDetailScreen({super.key, required this.id});
  final String id;
  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  Map<String, dynamic> profile = {}, loyalty = {};
  List<Map<String, dynamic>> addresses = [], appointments = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api(context);
    final values = await Future.wait([
      api.getCustomer(widget.id),
      api.getCustomerAddresses(widget.id),
      api.getAppointments(customerId: widget.id),
      api.getCustomerLoyalty(widget.id),
    ]);
    profile = values[0] as Map<String, dynamic>;
    addresses = values[1] as List<Map<String, dynamic>>;
    appointments = values[2] as List<Map<String, dynamic>>;
    loyalty = values[3] as Map<String, dynamic>;
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    title: 'Cliente',
    child: loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminMobileCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Info('Nome', _text(profile, 'fullName')),
                    _Info('E-mail', _text(profile, 'email')),
                    _Info('Telefone', _text(profile, 'phone')),
                    _Info('Cadastro', _date(profile['createdAt'])),
                    _Info(
                      'Pontos',
                      '${_text(loyalty, 'points')} · ${_text(loyalty, 'level')}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _Section('Endereços'),
              ...addresses.map(
                (x) => AdminMobileCard(
                  child: Text(
                    '${_text(x, 'street')}, ${_text(x, 'number')} · ${_text(x, 'city')}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _Section('Histórico'),
              ...appointments.map(
                (x) => AdminMobileCard(
                  child: Text(
                    '${_text(x, 'serviceName')} · ${_date(x['scheduledAt'])} · ${_statusLabel(_text(x, 'status'))}',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
  );
}

class AdminStoryFormScreen extends StatefulWidget {
  const AdminStoryFormScreen({super.key, this.id});
  final String? id;
  @override
  State<AdminStoryFormScreen> createState() => _AdminStoryFormScreenState();
}

class _AdminStoryFormScreenState extends State<AdminStoryFormScreen> {
  final title = TextEditingController(),
      subtitle = TextEditingController(),
      mediaUrl = TextEditingController(),
      order = TextEditingController(text: '0');
  List<Map<String, dynamic>> services = [];
  String serviceId = '';
  bool active = true, saving = false, uploading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api(context);
    services = await api.getServices();
    if (widget.id != null) {
      final x = await api.getStory(widget.id!);
      title.text = _text(x, 'title');
      subtitle.text = _text(x, 'subtitle');
      mediaUrl.text = _text(x, 'mediaUrl').isEmpty
          ? _text(x, 'imageUrl')
          : _text(x, 'mediaUrl');
      order.text = _text(x, 'displayOrder');
      serviceId = _text(x, 'serviceId');
      active = _flag(x, 'isActive', true);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pick(ImageSource source, {required bool video}) async {
    final picker = ImagePicker();
    final api = _api(context);
    final file = video
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);
    if (file == null) return;
    setState(() => uploading = true);
    final result = await api.uploadStoryMedia(file.path);
    if (mounted) {
      setState(() {
        mediaUrl.text = _text(result, 'mediaUrl');
        uploading = false;
      });
    }
  }

  @override
  void dispose() {
    title.dispose();
    subtitle.dispose();
    mediaUrl.dispose();
    order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: widget.id == null ? 'Novo story' : 'Editar story',
    saving: saving,
    onSave: () async {
      setState(() => saving = true);
      await _api(context).saveStory(widget.id, {
        'title': title.text,
        'subtitle': subtitle.text,
        'imageUrl': mediaUrl.text,
        'serviceId': serviceId.isEmpty ? null : serviceId,
        'displayOrder': int.tryParse(order.text) ?? 0,
        'isActive': active,
      });
      if (mounted) this.context.pop();
    },
    children: [
      TextField(
        controller: title,
        decoration: const InputDecoration(labelText: 'Título'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: subtitle,
        decoration: const InputDecoration(labelText: 'Subtítulo'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: mediaUrl,
        decoration: const InputDecoration(labelText: 'URL da mídia'),
      ),
      const SizedBox(height: 10),
      if (uploading) const LinearProgressIndicator(color: AppColors.gold),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.camera, video: false),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Foto'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery, video: false),
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeria'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.camera, video: true),
            icon: const Icon(Icons.videocam),
            label: const Text('Gravar vídeo'),
          ),
          OutlinedButton.icon(
            onPressed: () => _pick(ImageSource.gallery, video: true),
            icon: const Icon(Icons.video_library),
            label: const Text('Vídeo'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: serviceId,
        decoration: const InputDecoration(labelText: 'Serviço vinculado'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Nenhum')),
          ...services
              .where((x) => _flag(x, 'isActive', true))
              .map(
                (x) => DropdownMenuItem(
                  value: _text(x, 'id'),
                  child: Text(_text(x, 'name')),
                ),
              ),
        ],
        onChanged: (v) => serviceId = v ?? '',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: order,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Ordem'),
      ),
      SwitchListTile(
        value: active,
        onChanged: (v) => setState(() => active = v),
        title: const Text('Ativo'),
      ),
    ],
  );
}

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final fields = <String, TextEditingController>{
    for (final key in [
      'studioName',
      'subtitle',
      'slogan',
      'logoUrl',
      'whatsAppNumber',
      'instagramUrl',
      'welcomeTitle',
      'welcomeMessage',
      'supportMessage',
    ])
      key: TextEditingController(),
  };
  bool active = true, saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final x = await _api(context).getSettings();
    for (final e in fields.entries) {
      e.value.text = _text(x, e.key);
    }
    active = _flag(x, 'isActive', true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final x in fields.values) {
      x.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: 'Configurações',
    saving: saving,
    onSave: () async {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => saving = true);
      await _api(context).saveSettings({
        for (final e in fields.entries) e.key: e.value.text,
        'isActive': active,
      });
      if (mounted) {
        setState(() => saving = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Configurações salvas.')),
        );
      }
    },
    children: [
      for (final entry in fields.entries) ...[
        TextField(
          controller: entry.value,
          decoration: InputDecoration(labelText: _settingsLabels[entry.key]),
        ),
        const SizedBox(height: 12),
      ],
      SwitchListTile(
        value: active,
        onChanged: (v) => setState(() => active = v),
        title: const Text('Estúdio ativo'),
      ),
    ],
  );
}

const _settingsLabels = {
  'studioName': 'Nome do estúdio',
  'subtitle': 'Subtítulo',
  'slogan': 'Slogan',
  'logoUrl': 'URL da logo',
  'whatsAppNumber': 'WhatsApp',
  'instagramUrl': 'Instagram',
  'welcomeTitle': 'Título de boas-vindas',
  'welcomeMessage': 'Mensagem de boas-vindas',
  'supportMessage': 'Mensagem de suporte',
};

class AdminAvailabilityScreen extends StatefulWidget {
  const AdminAvailabilityScreen({super.key});
  @override
  State<AdminAvailabilityScreen> createState() =>
      _AdminAvailabilityScreenState();
}

class _AdminAvailabilityScreenState extends State<AdminAvailabilityScreen> {
  List<Map<String, dynamic>> hours = [], blocked = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api(context);
    hours = await api.getBusinessHours();
    blocked = await api.getBlockedDates();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _saveHours() async {
    final messenger = ScaffoldMessenger.of(context);
    await _api(context).saveBusinessHours(
      hours
          .map(
            (x) => {
              'dayOfWeek': x['dayOfWeek'],
              'isOpen': x['isOpen'],
              'startTime': x['startTime'],
              'endTime': x['endTime'],
              'slotIntervalMinutes': x['slotIntervalMinutes'],
            },
          )
          .toList(),
    );
    if (mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Horários salvos.')));
    }
  }

  @override
  Widget build(BuildContext context) => AdminScaffold(
    title: 'Disponibilidade',
    floatingActionButton: FloatingActionButton(
      backgroundColor: AppColors.gold,
      foregroundColor: AppColors.background,
      onPressed: () async {
        await context.push('/admin-mobile/availability/blocked-dates/new');
        _load();
      },
      child: const Icon(Icons.add),
    ),
    child: loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Section('Horários semanais'),
              ...hours.map(
                (x) => AdminMobileCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_text(x, 'dayName')),
                        value: _flag(x, 'isOpen'),
                        onChanged: (v) => setState(() => x['isOpen'] = v),
                      ),
                      if (_flag(x, 'isOpen'))
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _text(x, 'startTime'),
                                decoration: const InputDecoration(
                                  labelText: 'Início',
                                ),
                                onChanged: (v) => x['startTime'] = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: _text(x, 'endTime'),
                                decoration: const InputDecoration(
                                  labelText: 'Fim',
                                ),
                                onChanged: (v) => x['endTime'] = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 82,
                              child: TextFormField(
                                initialValue: _text(x, 'slotIntervalMinutes'),
                                decoration: const InputDecoration(
                                  labelText: 'Slot',
                                ),
                                onChanged: (v) => x['slotIntervalMinutes'] =
                                    int.tryParse(v) ?? 30,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              FilledButton(
                onPressed: _saveHours,
                child: const Text('Salvar horários'),
              ),
              const SizedBox(height: 18),
              const _Section('Datas bloqueadas'),
              ...blocked.map(
                (x) => AdminMobileCard(
                  onTap: () async {
                    await context.push(
                      '/admin-mobile/availability/blocked-dates/${_text(x, 'id')}/edit',
                    );
                    _load();
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_text(x, 'date')} · ${_text(x, 'reason')}',
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );
}

class AdminBlockedDateFormScreen extends StatefulWidget {
  const AdminBlockedDateFormScreen({super.key, this.id});
  final String? id;
  @override
  State<AdminBlockedDateFormScreen> createState() =>
      _AdminBlockedDateFormScreenState();
}

class _AdminBlockedDateFormScreenState
    extends State<AdminBlockedDateFormScreen> {
  final date = TextEditingController(),
      reason = TextEditingController(),
      start = TextEditingController(),
      end = TextEditingController();
  bool fullDay = true, saving = false;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) _load();
  }

  Future<void> _load() async {
    final x = await _api(context).getBlockedDate(widget.id!);
    date.text = _text(x, 'date').split('T').first;
    reason.text = _text(x, 'reason');
    start.text = _text(x, 'startTime');
    end.text = _text(x, 'endTime');
    fullDay = _flag(x, 'isFullDay', true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    date.dispose();
    reason.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: widget.id == null ? 'Bloquear data' : 'Editar bloqueio',
    saving: saving,
    onSave: () async {
      setState(() => saving = true);
      await _api(context).saveBlockedDate(widget.id, {
        'date': date.text,
        'reason': reason.text,
        'isFullDay': fullDay,
        'startTime': fullDay ? null : start.text,
        'endTime': fullDay ? null : end.text,
      });
      if (mounted) this.context.pop();
    },
    children: [
      TextField(
        controller: date,
        decoration: const InputDecoration(labelText: 'Data (AAAA-MM-DD)'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: reason,
        decoration: const InputDecoration(labelText: 'Motivo'),
      ),
      SwitchListTile(
        value: fullDay,
        onChanged: (v) => setState(() => fullDay = v),
        title: const Text('Dia inteiro'),
      ),
      if (!fullDay)
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: start,
                decoration: const InputDecoration(labelText: 'Início'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: end,
                decoration: const InputDecoration(labelText: 'Fim'),
              ),
            ),
          ],
        ),
      if (widget.id != null) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await _api(context).deleteBlockedDate(widget.id!);
            if (mounted) this.context.pop();
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir bloqueio'),
        ),
      ],
    ],
  );
}

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });
  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) {
    final isHome = GoRouterState.of(context).uri.path == AppRoutes.adminMobile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () {
            if (isHome) {
              context.go(AppRoutes.home);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.adminMobile);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title),
        actions: [
          if (!isHome)
            IconButton(
              tooltip: 'Dashboard',
              onPressed: () => context.go(AppRoutes.adminMobile),
              icon: const Icon(Icons.dashboard_outlined),
            ),
          IconButton(
            tooltip: 'Sair',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) {
                return;
              }
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
    );
  }
}

class AdminMobileCard extends StatelessWidget {
  const AdminMobileCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderGold.withValues(alpha: .48),
          width: .7,
        ),
      ),
      child: child,
    );
    return onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: card,
          );
  }
}

class _SimpleFormScaffold extends StatelessWidget {
  const _SimpleFormScaffold({
    required this.title,
    required this.children,
    required this.onSave,
    required this.saving,
  });
  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;
  final bool saving;
  @override
  Widget build(BuildContext context) => AdminScaffold(
    title: title,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...children,
        const SizedBox(height: 18),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      '$label: ${value.isEmpty ? '-' : value}',
      style: const TextStyle(color: AppColors.textPrimary),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.champagne,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Icon(
    Icons.circle,
    size: 10,
    color: active ? AppColors.success : AppColors.textMuted,
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => AdminMobileCard(
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) => const AdminMobileCard(
    child: Text(
      'Nenhum item encontrado.',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}

const _statuses = [
  'Pending',
  'WaitingPayment',
  'Confirmed',
  'Rejected',
  'Canceled',
  'Rescheduled',
  'OnTheWay',
  'InProgress',
  'Completed',
  'NoShow',
];
String _statusLabel(String status) =>
    const {
      'Pending': 'Pendente',
      'WaitingPayment': 'Aguardando sinal',
      'Confirmed': 'Confirmado',
      'Rejected': 'Recusado',
      'Canceled': 'Cancelado',
      'Rescheduled': 'Remarcado',
      'OnTheWay': 'A caminho',
      'InProgress': 'Em atendimento',
      'Completed': 'Concluído',
      'NoShow': 'Não compareceu',
    }[status] ??
    status;
List<(String, String, String)> _statusActions(String status) =>
    switch (status) {
      'Pending' => [
        ('Confirmed', 'Confirmar', 'Horário confirmado pelo administrador.'),
        (
          'WaitingPayment',
          'Solicitar sinal',
          'Cliente orientado a confirmar o sinal pelo WhatsApp.',
        ),
        ('Rejected', 'Recusar', 'Agendamento recusado pelo administrador.'),
        ('Canceled', 'Cancelar', 'Agendamento cancelado pelo administrador.'),
      ],
      'WaitingPayment' => [
        (
          'Confirmed',
          'Confirmar sinal',
          'Sinal confirmado pelo administrador.',
        ),
        ('Rejected', 'Recusar', 'Agendamento recusado pelo administrador.'),
        ('Canceled', 'Cancelar', 'Agendamento cancelado pelo administrador.'),
      ],
      'Confirmed' => [
        (
          'InProgress',
          'Iniciar atendimento',
          'Atendimento iniciado pelo administrador.',
        ),
        (
          'NoShow',
          'Não compareceu',
          'Não comparecimento registrado pelo administrador.',
        ),
        ('Canceled', 'Cancelar', 'Agendamento cancelado pelo administrador.'),
      ],
      'OnTheWay' => [
        (
          'InProgress',
          'Iniciar atendimento',
          'Atendimento iniciado pelo administrador.',
        ),
        ('Canceled', 'Cancelar', 'Agendamento cancelado pelo administrador.'),
      ],
      'InProgress' => [
        ('Completed', 'Concluir', 'Atendimento concluído pelo administrador.'),
      ],
      _ => [],
    };
