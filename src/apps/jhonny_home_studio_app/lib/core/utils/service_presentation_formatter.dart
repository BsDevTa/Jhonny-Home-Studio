import 'package:intl/intl.dart';

class ServicePresentationFormatter {
  const ServicePresentationFormatter._();

  static String priceFrom(num price) {
    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(price).replaceAll('\u00A0', ' ');

    return 'A partir de $formatted';
  }

  static String sanitizeNullableText(String? value) {
    final text = value?.trim() ?? '';
    return text.toLowerCase() == 'null' ? '' : text;
  }
}
