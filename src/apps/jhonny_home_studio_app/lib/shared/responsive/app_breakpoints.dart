import 'package:flutter/widgets.dart';

enum AppScreenClass { mobile, tablet, desktop, ultraWide }

class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;
  static const double ultraWide = 1440;

  static AppScreenClass ofWidth(double width) {
    if (width >= ultraWide) {
      return AppScreenClass.ultraWide;
    }
    if (width >= desktop) {
      return AppScreenClass.desktop;
    }
    if (width >= tablet) {
      return AppScreenClass.tablet;
    }
    return AppScreenClass.mobile;
  }

  static AppScreenClass of(BuildContext context) {
    return ofWidth(MediaQuery.sizeOf(context).width);
  }

  static bool isDesktopWidth(double width) => width >= desktop;

  static bool isDesktop(BuildContext context) {
    return isDesktopWidth(MediaQuery.sizeOf(context).width);
  }

  static double horizontalPadding(double width) {
    return switch (ofWidth(width)) {
      AppScreenClass.mobile => 20,
      AppScreenClass.tablet => 28,
      AppScreenClass.desktop => 32,
      AppScreenClass.ultraWide => 40,
    };
  }

  static double maxContentWidth(double width) {
    return switch (ofWidth(width)) {
      AppScreenClass.mobile => double.infinity,
      AppScreenClass.tablet => 820,
      AppScreenClass.desktop => 1180,
      AppScreenClass.ultraWide => 1360,
    };
  }
}
