class AddressModel {
  AddressModel({
    required this.id,
    required this.customerId,
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.complement,
    required this.referencePoint,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String customerId;
  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String complement;
  final String referencePoint;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: _readString(json, 'id'),
      customerId: _readString(json, 'customerId'),
      street: _readString(json, 'street'),
      number: _readString(json, 'number'),
      neighborhood: _readString(json, 'neighborhood'),
      city: _readString(json, 'city'),
      state: _readString(json, 'state'),
      zipCode: _readString(json, 'zipCode'),
      complement: _readString(json, 'complement'),
      referencePoint: _readString(json, 'referencePoint'),
      isDefault: _readBool(json, 'isDefault'),
      createdAt: _readDate(json, 'createdAt'),
      updatedAt: _readDate(json, 'updatedAt'),
    );
  }

  String get fullAddress {
    final buffer = StringBuffer();
    buffer.write('$street, $number - $neighborhood');
    buffer.write('\n$city/$state - CEP $zipCode');
    if (complement.trim().isNotEmpty) {
      buffer.write('\nComplemento: $complement');
    }
    if (referencePoint.trim().isNotEmpty) {
      buffer.write('\nReferência: $referencePoint');
    }
    return buffer.toString();
  }
}

class CreateAddressRequest {
  CreateAddressRequest({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.complement,
    required this.referencePoint,
  });

  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String complement;
  final String referencePoint;

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'complement': complement.isEmpty ? null : complement,
      'referencePoint': referencePoint.isEmpty ? null : referencePoint,
    };
  }
}

class UpdateAddressRequest {
  UpdateAddressRequest({
    required this.street,
    required this.number,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.complement,
    required this.referencePoint,
    required this.isDefault,
  });

  final String street;
  final String number;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final String complement;
  final String referencePoint;
  final bool isDefault;

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'complement': complement.isEmpty ? null : complement,
      'referencePoint': referencePoint.isEmpty ? null : referencePoint,
      'isDefault': isDefault,
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
