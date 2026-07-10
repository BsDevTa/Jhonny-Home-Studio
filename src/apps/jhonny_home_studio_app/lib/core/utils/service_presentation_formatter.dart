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

  static String estimatedDuration(int minutes) {
    if (minutes <= 0) {
      return 'Tempo a confirmar';
    }

    if (minutes < 60) {
      return minutes == 1
          ? 'Estimativa de 1 minuto'
          : 'Estimativa de $minutes minutos';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return hours == 1 ? 'Estimativa de 1 hora' : 'Estimativa de $hours horas';
    }

    return 'Estimativa de ${hours}h${remainingMinutes.toString().padLeft(2, '0')}';
  }

  static String sanitizeNullableText(String? value) {
    final text = value?.trim() ?? '';
    return text.toLowerCase() == 'null' ? '' : text;
  }
}
