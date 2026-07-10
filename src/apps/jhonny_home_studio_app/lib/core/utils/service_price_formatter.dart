import 'service_presentation_formatter.dart';

class ServicePriceFormatter {
  ServicePriceFormatter._();

  static String startingAt(num value) {
    return ServicePresentationFormatter.priceFrom(value);
  }
}
