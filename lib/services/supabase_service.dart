import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient? client;

  SupabaseService({this.client});

  /// Memeriksa apakah SupabaseClient telah diinisialisasi
  bool get isInitialized {
    if (client != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mendapatkan instance SupabaseClient (baik injected atau Supabase.instance.client)
  SupabaseClient get clientInstance {
    final injectedClient = client;
    if (injectedClient != null) return injectedClient;
    return Supabase.instance.client;
  }

  /// Mengambil seluruh data tugas dari tabel 'tasks' di Supabase
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final response = await clientInstance
          .from('tasks')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }
}
