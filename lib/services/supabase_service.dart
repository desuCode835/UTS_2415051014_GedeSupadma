import 'package:flutter/foundation.dart';
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

  /// Mendapatkan User ID dari sesi autentikasi Supabase yang aktif
  String? get currentUserId {
    if (!isInitialized) return null;
    try {
      return clientInstance.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  /// Memastikan ada sesi autentikasi anonim yang aktif tanpa form login
  Future<void> ensureAnonymousSession() async {
    if (!isInitialized) {
      debugPrint('[SupabaseService] ensureAnonymousSession: Supabase belum diinisialisasi.');
      return;
    }

    try {
      final auth = clientInstance.auth;
      final existingUser = auth.currentUser;
      final existingSession = auth.currentSession;

      if (existingUser != null && existingSession != null) {
        debugPrint(
          '[SupabaseService] Sesi aktif terdeteksi: userId=${existingUser.id}, isAnonymous=${existingUser.isAnonymous}',
        );
        return;
      }

      debugPrint('[SupabaseService] Tidak ada sesi aktif. Memanggil signInAnonymously()...');
      final authResponse = await auth.signInAnonymously();
      debugPrint(
        '[SupabaseService] signInAnonymously() berhasil: userId=${authResponse.user?.id}, isAnonymous=${authResponse.user?.isAnonymous}',
      );
    } catch (e) {
      debugPrint('[SupabaseService] Gagal menjalankan signInAnonymously: $e');
      rethrow;
    }
  }

  /// Mengambil seluruh data tugas dari tabel 'tasks' di Supabase
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final auth = clientInstance.auth;
      final session = auth.currentSession;
      final user = auth.currentUser;
      final hasAccessToken =
          session?.accessToken != null && session!.accessToken.isNotEmpty;

      debugPrint('[SupabaseService] Diagnostic pre-select:');
      debugPrint('  - session exists: ${session != null}');
      debugPrint('  - has access token: $hasAccessToken');
      debugPrint('  - user ID: ${user?.id ?? "null"}');

      final response = await clientInstance
          .from('tasks')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[SupabaseService] getTasks error: $e');
      rethrow;
    }
  }

  /// Menambahkan tugas baru ke tabel 'tasks' di Supabase
  /// Mengisi user_id secara otomatis dari sesi autentikasi aktif
  Future<Map<String, dynamic>> insertTask(Map<String, dynamic> taskData) async {
    try {
      // Pastikan ada sesi sebelum insert
      if (clientInstance.auth.currentUser == null) {
        debugPrint(
          '[SupabaseService] currentUser null sebelum insert, mencoba ensureAnonymousSession()...',
        );
        await ensureAnonymousSession();
      }

      final auth = clientInstance.auth;
      final session = auth.currentSession;
      final user = auth.currentUser;
      final hasAccessToken =
          session?.accessToken != null && session!.accessToken.isNotEmpty;

      // Log diagnostik aman (tanpa mencetak token/key)
      debugPrint('[SupabaseService] Diagnostic pre-insert:');
      debugPrint('  - isInitialized: $isInitialized');
      debugPrint('  - session exists: ${session != null}');
      debugPrint('  - has access token: $hasAccessToken');
      debugPrint('  - user ID: ${user?.id ?? "null"}');
      debugPrint('  - is anonymous: ${user?.isAnonymous ?? false}');

      if (user == null || session == null || !hasAccessToken) {
        throw const AuthException(
          'Gagal menyimpan tugas: Sesi autentikasi Supabase tidak ditemukan (user/session null). '
          'Pastikan fitur Anonymous Sign-Ins sudah diaktifkan di Supabase Dashboard (Authentication > Providers).',
        );
      }

      final payload = Map<String, dynamic>.from(taskData);

      // Gunakan user_id dari sesi autentikasi aktif, bukan dari input form
      payload['user_id'] = user.id;
      debugPrint('  - payload user_id: ${payload['user_id']}');

      final response = await clientInstance
          .from('tasks')
          .insert(payload)
          .select()
          .single();

      debugPrint(
        '[SupabaseService] insertTask sukses. Response ID: ${response['id']}',
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('[SupabaseService] insertTask error: $e');
      rethrow;
    }
  }
}
