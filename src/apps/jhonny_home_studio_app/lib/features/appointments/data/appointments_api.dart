import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import 'appointment_models.dart';

class AppointmentsApi {
  AppointmentsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AvailableSlotModel>> getAvailableSlots(
    String serviceId,
    DateTime date,
  ) async {
    final formattedDate = date.toIso8601String().split('T').first;
    final response = await _apiClient.getJson(
      '/appointments/available-slots?serviceId=$serviceId&date=$formattedDate',
    );
    final data = response['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AvailableSlotModel.fromJson)
        .toList(growable: false);
  }

  Future<AppointmentModel> createAppointment(
    CreateAppointmentRequest request,
  ) async {
    final response = await _apiClient.postJson(
      '/appointments',
      data: request.toJson(),
    );
    return _readAppointment(response['data']);
  }

  Future<List<AppointmentListModel>> getMyAppointments() async {
    final response = await _apiClient.getJson('/appointments/my');
    final data = response['data'];
    if (data is! List) {
      return const [];
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(AppointmentListModel.fromJson)
        .toList(growable: false);
  }

  Future<AppointmentModel> getMyAppointmentById(String appointmentId) async {
    final response = await _apiClient.getJson(
      '/appointments/my/$appointmentId',
    );
    return _readAppointment(response['data']);
  }

  Future<void> cancelMyAppointment(String appointmentId) async {
    await _apiClient.patchJson('/appointments/my/$appointmentId/cancel');
  }

  AppointmentModel _readAppointment(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw ApiException(message: 'Agendamento inválido retornado pela API.');
    }
    return AppointmentModel.fromJson(data);
  }
}
