/// Route locations used throughout the application.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Primary destinations (navigation bar / rail), in display order.
  static const String home = '/home';
  static const String classify = '/classify';
  static const String history = '/history';
  static const String analytics = '/analytics';
  static const String learn = '/learn';

  static const String result = '/classify/result';
  static String historyDetail(String id) =>
      '/history/${Uri.encodeComponent(id)}';

  static const String settings = '/settings';
  static const String privacy = '/settings/privacy';
  static const String about = '/settings/about';
  static const String modelInfo = '/settings/model';
}
