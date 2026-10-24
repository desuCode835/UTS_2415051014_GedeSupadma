import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Supabase project URL dimuat dari .env
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase publishable (anon) API key dimuat dari .env
  static String get publishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      dotenv.env['SUPABASE_ANON_KEY'] ??
      '';

  /// Alias anonKey untuk kompatibilitas
  static String get anonKey => publishableKey;

  /// Memeriksa apakah konfigurasi URL dan Publishable Key telah tersedia
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
