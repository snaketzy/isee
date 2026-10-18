import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 640.0;
  static const double tablet = 1024.0;
  static const double desktop = 1280.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}
