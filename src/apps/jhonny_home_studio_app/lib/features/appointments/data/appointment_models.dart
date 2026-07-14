class CreateAppointmentRequest {
  CreateAppointmentRequest({
    required this.serviceId,
    required this.addressId,
    required this.scheduledAt,
    required this.customerNotes,
  });

  final String serviceId;
  final String addressId;
  final DateTime scheduledAt;
  final String customerNotes;

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'addressId': addressId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'customerNotes': customerNotes.trim().isEmpty
          ? null
          : customerNotes.trim(),
    };
  }
}

class AvailableSlotModel {
  AvailableSlotModel({
    required this.startAt,
    required this.endAt,
    required this.isAvailable,
  });

  final DateTime? startAt;
  final DateTime? endAt;
  final bool isAvailable;

  factory AvailableSlotModel.fromJson(Map<String, dynamic> json) {
    return AvailableSlotModel(
      startAt: _readDate(json, 'startAt'),
      endAt: _readDate(json, 'endAt'),
      isAvailable: _readBool(json, 'isAvailable'),
    );
  }
}

class AppointmentModel {
  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.serviceId,
    required this.serviceName,
    required this.addressId,
    required this.addressText,
    required this.scheduledAt,
    required this.servicePriceSnapshot,
    required this.status,
    required this.customerNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String serviceId;
  final String serviceName;
  final String addressId;
  final String addressText;
  final DateTime? scheduledAt;
  final double servicePriceSnapshot;
  final String status;
  final String customerNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: _readString(json, 'id'),
      customerId: _readString(json, 'customerId'),
      customerName: _readString(json, 'customerName'),
      serviceId: _readString(json, 'serviceId'),
      serviceName: _readString(json, 'serviceName'),
      addressId: _readString(json, 'addressId'),
      addressText: _readString(json, 'addressText'),
      scheduledAt: _readDate(json, 'scheduledAt'),
      servicePriceSnapshot: _readDouble(json, 'servicePriceSnapshot'),
      status: _readString(json, 'status'),
      customerNotes: _readString(json, 'customerNotes'),
      createdAt: _readDate(json, 'createdAt'),
      updatedAt: _readDate(json, 'updatedAt'),
    );
  }
}

class AppointmentListModel {
  AppointmentListModel({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.scheduledAt,
    required this.status,
    required this.servicePriceSnapshot,
  });

  final String id;
  final String customerName;
  final String serviceName;
  final DateTime? scheduledAt;
  final String status;
  final double servicePriceSnapshot;

  factory AppointmentListModel.fromJson(Map<String, dynamic> json) {
    return AppointmentListModel(
      id: _readString(json, 'id'),
      customerName: _readString(json, 'customerName'),
      serviceName: _readString(json, 'serviceName'),
      scheduledAt: _readDate(json, 'scheduledAt'),
      status: _readString(json, 'status'),
      servicePriceSnapshot: _readDouble(json, 'servicePriceSnapshot'),
    );
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return false;
}

DateTime? _readDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
