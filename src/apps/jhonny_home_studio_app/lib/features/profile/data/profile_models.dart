class CustomerProfileModel {
  CustomerProfileModel({
    required this.customerId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.documentNumber,
    required this.birthDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String customerId;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String documentNumber;
  final DateTime? birthDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      customerId: _readString(json, 'customerId'),
      userId: _readString(json, 'userId'),
      fullName: _readString(json, 'fullName'),
      email: _readString(json, 'email'),
      phone: _readString(json, 'phone'),
      documentNumber: _readString(json, 'documentNumber'),
      birthDate: _readDate(json, 'birthDate'),
      isActive: _readBool(json, 'isActive', defaultValue: true),
      createdAt: _readDate(json, 'createdAt'),
      updatedAt: _readDate(json, 'updatedAt'),
    );
  }
}

class UpdateCustomerProfileRequest {
  UpdateCustomerProfileRequest({
    required this.fullName,
    required this.phone,
    required this.documentNumber,
    required this.birthDate,
  });

  final String fullName;
  final String phone;
  final String documentNumber;
  final DateTime? birthDate;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone.isEmpty ? null : phone,
      'documentNumber': documentNumber.isEmpty ? null : documentNumber,
      'birthDate': birthDate?.toIso8601String(),
    };
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

DateTime? _readDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  bool defaultValue = false,
}) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  return defaultValue;
}
