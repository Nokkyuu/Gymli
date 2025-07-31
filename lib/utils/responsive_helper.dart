/// Helper class to determine the device type and screen size
/// This class provides methods to check if the current device is mobile, tablet, or desktop
/// how to use:
/// import 'responsive_helper.dart';
/// class LandingScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: ResponsiveHelper.isWebMobile(context)
///           ? Row(
///               children: [
///                 // mobile layout
///               ],
///             )
///           : Column(
///               children: [
///                 // desktop layout
///               ],
///             ),
///     );
///   }
/// }
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static bool isWebMobile(BuildContext context) {
    return kIsWeb && isMobile(context);
  }

  static bool isWebDesktop(BuildContext context) {
    return kIsWeb && isDesktop(context);
  }

  static bool isNativeMobile() {
    return !kIsWeb;
  }
}
