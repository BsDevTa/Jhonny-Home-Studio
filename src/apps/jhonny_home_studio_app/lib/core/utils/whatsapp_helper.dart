import 'package:url_launcher/url_launcher.dart';

const whatsAppNotConfiguredMessage =
    'WhatsApp do estúdio ainda não configurado.';

String normalizeBrazilianWhatsAppNumber(String phoneNumber) {
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

  if (digits.length == 11) {
    return '55$digits';
  }

  if (digits.length == 13 && digits.startsWith('55')) {
    return digits;
  }

  return '';
}

bool hasConfiguredWhatsAppNumber(String phoneNumber) {
  return normalizeBrazilianWhatsAppNumber(phoneNumber).isNotEmpty;
}

Uri? buildWhatsAppUri({required String phoneNumber, required String message}) {
  final normalizedNumber = normalizeBrazilianWhatsAppNumber(phoneNumber);
  if (normalizedNumber.isEmpty) {
    return null;
  }

  return Uri.parse(
    'https://wa.me/$normalizedNumber?text=${Uri.encodeComponent(message)}',
  );
}

Future<bool> openWhatsApp({
  required String phoneNumber,
  required String message,
}) async {
  final uri = buildWhatsAppUri(phoneNumber: phoneNumber, message: message);
  if (uri == null) {
    return false;
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
