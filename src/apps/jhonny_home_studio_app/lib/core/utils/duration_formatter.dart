import 'service_presentation_formatter.dart';

class DurationFormatter {
  const DurationFormatter._();

  static String format(int minutes) {
    if (minutes <= 0) {
      return 'Tempo a confirmar';
    }

    if (minutes < 60) {
      return minutes == 1 ? '1 minuto' : '$minutes minutos';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return hours == 1 ? '1 hora' : '$hours horas';
    }

    return '${hours}h${remainingMinutes.toString().padLeft(2, '0')}';
  }

  static String estimated(int minutes) {
    return ServicePresentationFormatter.estimatedDuration(minutes);
  }
}
