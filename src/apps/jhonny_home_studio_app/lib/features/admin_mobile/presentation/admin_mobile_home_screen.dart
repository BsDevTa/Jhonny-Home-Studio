import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../data/admin_mobile_api.dart';
import 'admin_mobile_screens.dart';

class AdminMobileHomeScreen extends StatefulWidget {
  const AdminMobileHomeScreen({super.key});

  @override
  State<AdminMobileHomeScreen> createState() => _AdminMobileHomeScreenState();
}

class _AdminMobileHomeScreenState extends State<AdminMobileHomeScreen> {
  bool _loading = true;
  String _error = '';
  _AdminMetrics _metrics = _AdminMetrics.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final api = AdminMobileApi(apiClient: context.read<ApiClient>());
      final values = await Future.wait([
        api.getAppointments(),
        api.getCustomers(),
        api.getServices(),
        api.getCategories(),
        api.getStories(),
        api.getMarketplaceProducts(),
        api.getMarketplaceCategories(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _metrics = _AdminMetrics.fromLists(
          appointments: values[0],
          customers: values[1],
          services: values[2],
          serviceCategories: values[3],
          stories: values[4],
          products: values[5],
          productCategories: values[6],
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Painel Administrativo',
      child: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'Painel Administrativo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Gestão rápida do estúdio pelo celular.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else ...[
              if (_error.isNotEmpty) ...[
                _AdminNotice(message: 'Algumas métricas não carregaram.'),
                const SizedBox(height: 12),
              ],
              _MetricGrid(metrics: _metrics),
            ],
            const SizedBox(height: 22),
            const Text(
              'Módulos administrativos',
              style: TextStyle(
                color: AppColors.champagne,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._adminModules.map(
              (module) => _AdminModuleCard(
                module: module,
                onTap: () => context.push(module.path),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final _AdminMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem('Agendamentos hoje', metrics.appointmentsToday),
      _MetricItem('Pendentes', metrics.pendingAppointments),
      _MetricItem('Confirmados', metrics.confirmedAppointments),
      _MetricItem('Clientes cadastrados', metrics.customers),
      _MetricItem('Produtos ativos', metrics.activeProducts),
      _MetricItem('Produtos em destaque', metrics.featuredProducts),
      _MetricItem('Categorias da loja', metrics.productCategories),
      _MetricItem('Serviços ativos', metrics.activeServices),
      _MetricItem('Categorias de serviço', metrics.serviceCategories),
      _MetricItem('Stories ativos', metrics.activeStories),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 3 ? 1.8 : 1.45,
          ),
          itemBuilder: (context, index) => _MetricCard(item: items[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.value?.toString() ?? '--',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminModuleCard extends StatelessWidget {
  const _AdminModuleCard({required this.module, required this.onTap});

  final _AdminModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(module.icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 13),
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
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

class _AdminMetrics {
  const _AdminMetrics({
    required this.appointmentsToday,
    required this.pendingAppointments,
    required this.confirmedAppointments,
    required this.customers,
    required this.activeProducts,
    required this.featuredProducts,
    required this.productCategories,
    required this.activeServices,
    required this.serviceCategories,
    required this.activeStories,
  });

  final int? appointmentsToday;
  final int? pendingAppointments;
  final int? confirmedAppointments;
  final int? customers;
  final int? activeProducts;
  final int? featuredProducts;
  final int? productCategories;
  final int? activeServices;
  final int? serviceCategories;
  final int? activeStories;

  factory _AdminMetrics.empty() {
    return const _AdminMetrics(
      appointmentsToday: null,
      pendingAppointments: null,
      confirmedAppointments: null,
      customers: null,
      activeProducts: null,
      featuredProducts: null,
      productCategories: null,
      activeServices: null,
      serviceCategories: null,
      activeStories: null,
    );
  }

  factory _AdminMetrics.fromLists({
    required List<Map<String, dynamic>> appointments,
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> services,
    required List<Map<String, dynamic>> serviceCategories,
    required List<Map<String, dynamic>> stories,
    required List<Map<String, dynamic>> products,
    required List<Map<String, dynamic>> productCategories,
  }) {
    final today = DateTime.now();
    final todayAppointments = appointments.where((appointment) {
      final scheduledAt = DateTime.tryParse(
        _text(appointment, 'scheduledAt'),
      )?.toLocal();
      return scheduledAt != null &&
          scheduledAt.year == today.year &&
          scheduledAt.month == today.month &&
          scheduledAt.day == today.day;
    }).length;

    return _AdminMetrics(
      appointmentsToday: todayAppointments,
      pendingAppointments: appointments
          .where((appointment) => _statusIs(appointment, 'Pending'))
          .length,
      confirmedAppointments: appointments
          .where((appointment) => _statusIs(appointment, 'Confirmed'))
          .length,
      customers: customers.length,
      activeProducts: products.where(_isActive).length,
      featuredProducts: products
          .where((product) => _boolValue(product, 'isFeatured'))
          .length,
      productCategories: productCategories.length,
      activeServices: services.where(_isActive).length,
      serviceCategories: serviceCategories.length,
      activeStories: stories.where(_isActive).length,
    );
  }
}

class _MetricItem {
  const _MetricItem(this.label, this.value);

  final String label;
  final int? value;
}

class _AdminModule {
  const _AdminModule(this.title, this.subtitle, this.path, this.icon);

  final String title;
  final String subtitle;
  final String path;
  final IconData icon;
}

const _adminModules = [
  _AdminModule(
    'Agenda',
    'Acompanhe agendamentos e status.',
    '${AppRoutes.adminMobile}/appointments',
    Icons.event_note_outlined,
  ),
  _AdminModule(
    'Clientes',
    'Consulte perfis, contatos e fidelidade.',
    '${AppRoutes.adminMobile}/customers',
    Icons.people_outline,
  ),
  _AdminModule(
    'Serviços',
    'Edite catálogo, preço e duração.',
    '${AppRoutes.adminMobile}/services',
    Icons.spa_outlined,
  ),
  _AdminModule(
    'Categorias de Serviços',
    'Organize os tipos de serviço.',
    '${AppRoutes.adminMobile}/categories',
    Icons.category_outlined,
  ),
  _AdminModule(
    'Marketplace / Loja',
    'Visão geral da loja assistida.',
    '${AppRoutes.adminMobile}/marketplace',
    Icons.storefront_outlined,
  ),
  _AdminModule(
    'Categorias da Loja',
    'Organize linhas e famílias de produto.',
    '${AppRoutes.adminMobile}/marketplace/categories',
    Icons.local_offer_outlined,
  ),
  _AdminModule(
    'Produtos da Loja',
    'Cadastre produtos, preços e destaques.',
    '${AppRoutes.adminMobile}/marketplace/products',
    Icons.shopping_bag_outlined,
  ),
  _AdminModule(
    'Stories',
    'Publique fotos e vídeos de divulgação.',
    '${AppRoutes.adminMobile}/stories',
    Icons.auto_awesome_outlined,
  ),
  _AdminModule(
    'Configurações',
    'Atualize marca, WhatsApp e mensagens.',
    '${AppRoutes.adminMobile}/settings',
    Icons.settings_outlined,
  ),
  _AdminModule(
    'Disponibilidade',
    'Horários, slots e datas bloqueadas.',
    '${AppRoutes.adminMobile}/availability',
    Icons.schedule_outlined,
  ),
];

String _text(Map<String, dynamic> item, String key) =>
    item[key]?.toString() ?? '';

bool _isActive(Map<String, dynamic> item) => _boolValue(item, 'isActive', true);

bool _boolValue(
  Map<String, dynamic> item,
  String key, [
  bool fallback = false,
]) {
  return item[key] is bool ? item[key] as bool : fallback;
}

bool _statusIs(Map<String, dynamic> appointment, String status) {
  return _text(appointment, 'status').toLowerCase() == status.toLowerCase();
}
