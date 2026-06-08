// lib/core/utils/responsive.dart
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;

  static bool isWeb(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768;
}