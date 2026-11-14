enum AppMode { demo, live }

class AppConfig {
  static const mode = String.fromEnvironment('APP_MODE', defaultValue: 'demo');
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static bool get isLive => mode == 'live';
  static bool get configured =>
      Uri.tryParse(url)?.scheme == 'https' && publishableKey.isNotEmpty;
}
