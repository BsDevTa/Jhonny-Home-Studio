import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/whatsapp_service.dart';
import '../../../core/utils/appointment_status_helper.dart';
import '../../../core/utils/service_presentation_formatter.dart';
import '../../../shared/responsive/app_breakpoints.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../settings/presentation/app_settings_provider.dart';
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

enum AdminListType { services, appointments, customers, stories }

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
    AdminListType.services => 'Serviços',
    AdminListType.appointments => 'Agenda',
    AdminListType.customers => 'Clientes',
    AdminListType.stories => 'Stories',
  };

  bool get canCreate =>
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
                    (x) => DropdownMenuItem(
                      value: x,
                      child: Text(_statusLabel(x)),
                    ),
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
    AdminListType.services => _text(item, 'name'),
    AdminListType.appointments =>
      '${_text(item, 'customerName')} · ${_text(item, 'serviceName')}',
    AdminListType.customers => _text(item, 'fullName'),
    AdminListType.stories => _text(item, 'title'),
  };
  String get subtitle => switch (type) {
    AdminListType.services =>
      ServicePresentationFormatter.priceFrom(num.tryParse(_text(item, 'price')) ?? 0),
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
      imageUrl = TextEditingController();
  bool active = true, saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = _api(context);
    if (widget.id != null) {
      final x = await api.getService(widget.id!);
      name.text = _text(x, 'name');
      description.text = ServicePresentationFormatter.sanitizeNullableText(
        _text(x, 'description'),
      );
      price.text = _text(x, 'price');
      imageUrl.text = _text(x, 'imageUrl');
      active = _flag(x, 'isActive', true);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    imageUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SimpleFormScaffold(
    title: widget.id == null ? 'Novo serviço' : 'Editar serviço',
    saving: saving,
    onSave: () async {
      final sanitizedDescription =
          ServicePresentationFormatter.sanitizeNullableText(description.text);
      final Map<String, dynamic> payload = {
        'name': name.text.trim(),
        'description': sanitizedDescription.isEmpty
            ? null
            : sanitizedDescription,
        'price': double.tryParse(price.text.replaceAll(',', '.')) ?? 0,
        'imageUrl': imageUrl.text.trim().isEmpty ? null : imageUrl.text.trim(),
        'isActive': widget.id == null ? true : active,
      };
      debugPrint('Payload serviço: ${jsonEncode(payload)}');
      setState(() => saving = true);
      try {
        await _api(context).saveService(widget.id, payload);
        if (mounted) this.context.pop();
      } catch (error) {
        if (!mounted) return;
        _showMessage(_readServiceSaveError(error));
      } finally {
        if (mounted) {
          setState(() => saving = false);
        }
      }
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
      const SizedBox(height: 12),
      TextField(
        controller: price,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Preço a partir de'),
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readServiceSaveError(Object error) {
    final apiError = _apiException(error);
    final message = _readApiError(
      error,
      fallback: 'Nao foi possivel salvar o servico. Tente novamente.',
    );

    if (apiError?.statusCode == 401) {
      return 'Sessao expirada. Faca login novamente.';
    }

    if (apiError?.statusCode == 400) {
      return message;
    }

    return message;
  }

  String _readApiError(
    Object error, {
    String fallback = 'Nao foi possivel concluir a operacao.',
  }) {
    final apiError = _apiException(error);
    if (apiError != null) {
      if (apiError.errors.isNotEmpty) {
        return apiError.errors.join(' ');
      }
      if (apiError.message.isNotEmpty) {
        return apiError.message;
      }
    }
    return fallback;
  }

  ApiException? _apiException(Object error) {
    if (error is ApiException) {
      return error;
    }
    if (error is DioException && error.error is ApiException) {
      return error.error! as ApiException;
    }
    return null;
  }
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
  bool sendingWhatsApp = false;
  String lastWhatsAppStatus = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    item = await _api(context).getAppointment(widget.id);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _sendWhatsApp({String? statusOverride}) async {
    if (sendingWhatsApp) {
      return;
    }

    setState(() => sendingWhatsApp = true);
    final settings = context.read<AppSettingsProvider>().settings;
    final statusToSend = statusOverride ?? _text(item, 'status');
    final result = await WhatsAppService().sendAppointmentStatus(
      studioWhatsAppNumber: settings.whatsAppNumber,
      customerName: _text(item, 'customerName'),
      customerPhone: _text(item, 'customerPhone'),
      serviceName: _text(item, 'serviceName'),
      scheduledAt: DateTime.tryParse(_text(item, 'scheduledAt')),
      servicePrice: num.tryParse(_text(item, 'servicePriceSnapshot')) ?? 0,
      status: statusToSend,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      sendingWhatsApp = false;
      if (result.success) {
        lastWhatsAppStatus = statusToSend;
      }
    });

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Não foi possível abrir o WhatsApp agora.',
          ),
        ),
      );
    }
  }

  void _showStatusUpdatedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Status atualizado com sucesso.'),
        action: SnackBarAction(
          label: 'Enviar WhatsApp',
          onPressed: () => _sendWhatsApp(),
        ),
      ),
    );
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
                    _Info('Última atualização', _date(item['updatedAt'])),
                    _Info(
                      'Último status enviado via WhatsApp',
                      lastWhatsAppStatus.isEmpty
                          ? '-'
                          : _statusLabel(lastWhatsAppStatus),
                    ),
                    _Info(
                      'Preço',
                      ServicePresentationFormatter.priceFrom(
                        num.tryParse(_text(item, 'servicePriceSnapshot')) ?? 0,
                      ),
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
                      if (!mounted) return;
                      _showStatusUpdatedSnackBar();
                    },
                    child: Text(action.$2),
                  ),
                ),
              ),
              if (lastWhatsAppStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: sendingWhatsApp
                      ? null
                      : () => _sendWhatsApp(statusOverride: lastWhatsAppStatus),
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                    sendingWhatsApp ? 'Abrindo...' : 'Reenviar WhatsApp',
                  ),
                ),
              ],
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
  Uint8List? mediaPreviewBytes;
  String mediaPreviewName = '';
  bool mediaPreviewIsVideo = false;
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
    try {
      final bytes = await file.readAsBytes();
      debugPrint('Arquivo selecionado: ${file.name}');
      debugPrint('Preview local: bytes=${bytes.length}');
      final result = await api.uploadStoryMedia(bytes, fileName: file.name);
      final uploadedUrl = readUploadUrl(result);
      debugPrint('URL definitiva recebida: $uploadedUrl');
      if (uploadedUrl.isEmpty) {
        throw ApiException(
          message: 'Upload concluído, mas a API não retornou a URL da mídia.',
        );
      }

      if (!mounted) return;
      setState(() {
        mediaUrl.text = uploadedUrl;
        mediaPreviewBytes = bytes;
        mediaPreviewName = file.name;
        mediaPreviewIsVideo = video;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(_readApiError(error));
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
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
      final uploadedUrl = mediaUrl.text.trim();
      if (uploadedUrl.startsWith('blob:')) {
        _showMessage(
          'A URL temporária de prévia não pode ser salva. Aguarde o upload concluir.',
        );
        return;
      }

      if (mediaPreviewName.isNotEmpty && uploadedUrl.isEmpty) {
        _showMessage(
          'A mídia foi selecionada, mas a URL do upload está vazia.',
        );
        return;
      }

      final payload = {
        'title': title.text,
        'subtitle': subtitle.text,
        'imageUrl': uploadedUrl,
        'serviceId': serviceId.isEmpty ? null : serviceId,
        'displayOrder': int.tryParse(order.text) ?? 0,
        'isActive': active,
      };
      debugPrint('Payload Story: $payload');

      setState(() => saving = true);
      try {
        await _api(context).saveStory(widget.id, payload);
        if (mounted) this.context.pop();
      } catch (error) {
        if (!mounted) return;
        _showMessage(_readSaveError(error));
      } finally {
        if (mounted) {
          setState(() => saving = false);
        }
      }
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
      if (mediaPreviewBytes != null) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: mediaPreviewIsVideo
                ? Row(
                    children: [
                      const Icon(Icons.videocam, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mediaPreviewName.isEmpty
                              ? 'Vídeo selecionado'
                              : mediaPreviewName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      mediaPreviewBytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
      ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readSaveError(Object error) {
    final apiError = _apiException(error);
    final message = _readApiError(
      error,
      fallback: 'Nao foi possivel salvar o story. Tente novamente.',
    );
    final normalized = message.toLowerCase();

    if (normalized.contains('titulo') || normalized.contains('title')) {
      return 'Informe um título para o story.';
    }

    if (apiError?.statusCode == 400) {
      return message;
    }

    return message;
  }

  String _readApiError(
    Object error, {
    String fallback = 'Nao foi possivel concluir a operacao.',
  }) {
    final apiError = _apiException(error);
    if (apiError?.statusCode == 401) {
      return 'Sessao expirada. Faca login novamente.';
    }
    if (apiError != null) {
      if (apiError.errors.isNotEmpty) {
        return apiError.errors.join(' ');
      }
      if (apiError.message.isNotEmpty) {
        return apiError.message;
      }
    }
    return fallback;
  }

  ApiException? _apiException(Object error) {
    if (error is ApiException) {
      return error;
    }
    if (error is DioException && error.error is ApiException) {
      return error.error! as ApiException;
    }
    return null;
  }
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
    final path = GoRouterState.of(context).uri.path;
    final isHome = path == AppRoutes.adminMobile;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = AppBreakpoints.isDesktopWidth(width);
    final showContextPanel = width >= 1280;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isDesktop ? null : const _AdminDrawer(),
      appBar: isDesktop
          ? null
          : AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: isHome ? 'Menu' : 'Voltar',
                  onPressed: () {
                    if (isHome) {
                      Scaffold.of(context).openDrawer();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.adminMobile);
                    }
                  },
                  icon: Icon(isHome ? Icons.menu_rounded : Icons.arrow_back),
                ),
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
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  const _AdminNavigationPanel(width: 272),
                  Expanded(
                    child: Column(
                      children: [
                        _AdminTopBar(title: title, path: path, isHome: isHome),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                  if (showContextPanel) const _AdminContextPanel(),
                ],
              )
            : child,
      ),
    );
  }
}

class _AdminNavigationPanel extends StatelessWidget {
  const _AdminNavigationPanel({this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jhonny ERP',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sistema administrativo premium',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _AdminDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  path: AppRoutes.adminMobile,
                  selected: path == AppRoutes.adminMobile,
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.event_note_outlined,
                  title: 'Agenda',
                  path: '${AppRoutes.adminMobile}/appointments',
                  selected: path.startsWith(
                    '${AppRoutes.adminMobile}/appointments',
                  ),
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.people_outline,
                  title: 'Clientes',
                  path: '${AppRoutes.adminMobile}/customers',
                  selected: path.startsWith(
                    '${AppRoutes.adminMobile}/customers',
                  ),
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Produtos',
                  path: '${AppRoutes.adminMobile}/marketplace/products',
                  selected: path.startsWith(
                    '${AppRoutes.adminMobile}/marketplace/products',
                  ),
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.storefront_outlined,
                  title: 'Marketplace',
                  path: '${AppRoutes.adminMobile}/marketplace',
                  selected: path == '${AppRoutes.adminMobile}/marketplace',
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.spa_outlined,
                  title: 'Servicos',
                  path: '${AppRoutes.adminMobile}/services',
                  selected: path.startsWith(
                    '${AppRoutes.adminMobile}/services',
                  ),
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Clube VIP',
                  path: AppRoutes.adminMobile,
                  selected: false,
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.loyalty_outlined,
                  title: 'Fidelidade',
                  path: AppRoutes.adminMobile,
                  selected: false,
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Stories',
                  path: '${AppRoutes.adminMobile}/stories',
                  selected: path.startsWith('${AppRoutes.adminMobile}/stories'),
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.schedule_outlined,
                  title: 'Disponibilidade',
                  path: '${AppRoutes.adminMobile}/availability',
                  selected: path.startsWith(
                    '${AppRoutes.adminMobile}/availability',
                  ),
                  closeOnTap: false,
                ),
                _AdminDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Configuracoes',
                  path: '${AppRoutes.adminMobile}/settings',
                  selected: path.startsWith(
                    '${AppRoutes.adminMobile}/settings',
                  ),
                  closeOnTap: false,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) {
                    return;
                  }
                  context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.path,
    required this.isHome,
  });

  final String title;
  final String path;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.75)),
        ),
      ),
      child: Row(
        children: [
          if (!isHome) ...[
            IconButton(
              tooltip: 'Voltar',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.adminMobile);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  path == AppRoutes.adminMobile
                      ? 'Dashboard executivo'
                      : path.replaceFirst('/admin-mobile', 'ERP'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                context.go('${AppRoutes.adminMobile}/appointments'),
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('Agenda'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () =>
                context.go('${AppRoutes.adminMobile}/services/new'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Novo servico'),
          ),
        ],
      ),
    );
  }
}

class _AdminContextPanel extends StatelessWidget {
  const _AdminContextPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 316,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        border: Border(
          left: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: ListView(
        children: const [
          _ContextPanelHeader(),
          SizedBox(height: 14),
          _ContextPanelItem(
            icon: Icons.event_available_outlined,
            title: 'Proximos horarios',
            value: 'Agenda do dia',
          ),
          _ContextPanelItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Produtos mais vendidos',
            value: 'Marketplace',
          ),
          _ContextPanelItem(
            icon: Icons.workspace_premium_outlined,
            title: 'Clientes VIP',
            value: 'Relacionamento',
          ),
          _ContextPanelItem(
            icon: Icons.receipt_long_outlined,
            title: 'Ultimos pedidos',
            value: 'Operacao',
          ),
          _ContextPanelItem(
            icon: Icons.notifications_active_outlined,
            title: 'Notificacoes',
            value: 'Sem alertas criticos',
          ),
        ],
      ),
    );
  }
}

class _ContextPanelHeader extends StatelessWidget {
  const _ContextPanelHeader();

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Painel contextual',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Sinais rapidos para acompanhar a operacao em tempo real.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextPanelItem extends StatelessWidget {
  const _ContextPanelItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AdminMobileCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Painel Administrativo',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gestão mobile do estúdio',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _AdminDrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    path: AppRoutes.adminMobile,
                    selected: path == AppRoutes.adminMobile,
                  ),
                  _AdminDrawerItem(
                    icon: Icons.event_note_outlined,
                    title: 'Agenda',
                    path: '${AppRoutes.adminMobile}/appointments',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/appointments',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.people_outline,
                    title: 'Clientes',
                    path: '${AppRoutes.adminMobile}/customers',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/customers',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.spa_outlined,
                    title: 'Serviços',
                    path: '${AppRoutes.adminMobile}/services',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/services',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.storefront_outlined,
                    title: 'Marketplace',
                    path: '${AppRoutes.adminMobile}/marketplace',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/marketplace',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Stories',
                    path: '${AppRoutes.adminMobile}/stories',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/stories',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Configurações',
                    path: '${AppRoutes.adminMobile}/settings',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/settings',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.schedule_outlined,
                    title: 'Disponibilidade',
                    path: '${AppRoutes.adminMobile}/availability',
                    selected: path.startsWith(
                      '${AppRoutes.adminMobile}/availability',
                    ),
                  ),
                  _AdminDrawerItem(
                    icon: Icons.visibility_outlined,
                    title: 'Ver app como cliente',
                    path: AppRoutes.home,
                    selected: false,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) {
                      return;
                    }
                    context.go(AppRoutes.login);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  const _AdminDrawerItem({
    required this.icon,
    required this.title,
    required this.path,
    required this.selected,
    this.closeOnTap = true,
  });

  final IconData icon;
  final String title;
  final String path;
  final bool selected;
  final bool closeOnTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.10)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(
            icon,
            color: selected ? AppColors.gold : AppColors.textSecondary,
            size: 18,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () {
            if (closeOnTap) {
              context.pop();
            }
            context.go(path);
          },
        ),
      ),
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
String _statusLabel(String status) => appointmentStatusLabel(status);
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
