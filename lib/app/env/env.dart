class AppEnv {
  const AppEnv({
    required this.appName,
    required this.analyticsEnabled,
  });

  final String appName;
  final bool analyticsEnabled;

  static const defaultEnv = AppEnv(
    appName: 'QR Tool',
    analyticsEnabled: false,
  );
}
