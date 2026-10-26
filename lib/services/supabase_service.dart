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
      debugPrint(
        '[SupabaseService] ensureAnonymousSession: Supabase belum diinisialisasi.',
      );
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

      debugPrint(
        '[SupabaseService] Tidak ada sesi aktif. Memanggil signInAnonymously()...',
      );
      final authResponse = await auth.signInAnonymously();
      debugPrint(
        '[SupabaseService] signInAnonymously() berhasil: userId=${authResponse.user?.id}, isAnonymous=${authResponse.user?.isAnonymous}',
      );
    } catch (e) {
      debugPrint('[SupabaseService] Gagal menjalankan signInAnonymously: $e');
      rethrow;
    }
  }

  /// Mengambil seluruh data tugas dari tabel 'tasks' di Supabase.
  /// Dapat difilter berdasarkan kolom is_archived jika parameter disediakan.
  Future<List<Map<String, dynamic>>> getTasks({bool? isArchived}) async {
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
      debugPrint('  - filter isArchived: $isArchived');

      var query = clientInstance.from('tasks').select();
      if (isArchived != null) {
        query = query.eq('is_archived', isArchived);
      }

      final response = await query.order('created_at', ascending: false);

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

      // Normalisasi is_archived jika camelCase
      if (payload.containsKey('isArchived') &&
          !payload.containsKey('is_archived')) {
        payload['is_archived'] = payload.remove('isArchived');
      }

      // Normalisasi course_category jika camelCase
      if (payload.containsKey('courseCategory') &&
          !payload.containsKey('course_category')) {
        payload['course_category'] = payload.remove('courseCategory');
      }

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

  /// Memperbarui tugas pada tabel 'tasks' di Supabase berdasarkan primary key (id).
  /// Menggunakan filter .eq('id', id) agar hanya tugas yang dipilih yang diperbarui.
  /// Memastikan operasi terikat dengan user_id pengguna aktif untuk mematuhi RLS.
  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> taskData,
  ) async {
    try {
      if (clientInstance.auth.currentUser == null) {
        debugPrint(
          '[SupabaseService] currentUser null sebelum update, mencoba ensureAnonymousSession()...',
        );
        await ensureAnonymousSession();
      }

      final auth = clientInstance.auth;
      final session = auth.currentSession;
      final user = auth.currentUser;
      final hasAccessToken =
          session?.accessToken != null && session!.accessToken.isNotEmpty;

      debugPrint('[SupabaseService] Diagnostic pre-update:');
      debugPrint('  - isInitialized: $isInitialized');
      debugPrint('  - target task id: $id');
      debugPrint('  - session exists: ${session != null}');
      debugPrint('  - has access token: $hasAccessToken');
      debugPrint('  - user ID: ${user?.id ?? "null"}');
      debugPrint('  - is anonymous: ${user?.isAnonymous ?? false}');

      if (user == null || session == null || !hasAccessToken) {
        throw const AuthException(
          'Gagal memperbarui tugas: Sesi autentikasi Supabase tidak ditemukan (user/session null). '
          'Pastikan sesi aktif tersedia sebelum melakukan update.',
        );
      }

      final payload = Map<String, dynamic>.from(taskData);
      // Hapus id dari payload agar primary key tidak ikut di-update
      payload.remove('id');

      // Pastikan user_id tetap terikat dengan pemiliknya
      if (!payload.containsKey('user_id') || payload['user_id'] == null) {
        payload['user_id'] = user.id;
      }

      // Normalisasi is_completed jika diberikan dalam format camelCase
      if (payload.containsKey('isCompleted') &&
          !payload.containsKey('is_completed')) {
        payload['is_completed'] = payload.remove('isCompleted');
      }
      debugPrint('  - is_completed payload: ${payload['is_completed']}');

      // Normalisasi is_archived jika diberikan dalam format camelCase
      if (payload.containsKey('isArchived') &&
          !payload.containsKey('is_archived')) {
        payload['is_archived'] = payload.remove('isArchived');
      }
      debugPrint('  - is_archived payload: ${payload['is_archived']}');

      // Normalisasi course_category jika diberikan dalam format camelCase
      if (payload.containsKey('courseCategory') &&
          !payload.containsKey('course_category')) {
        payload['course_category'] = payload.remove('courseCategory');
      }
      debugPrint('  - course_category payload: ${payload['course_category']}');

      final List<dynamic> response = await clientInstance
          .from('tasks')
          .update(payload)
          .eq('id', id)
          .select();

      debugPrint(
        '[SupabaseService] updateTask response count: ${response.length}',
      );

      if (response.isEmpty) {
        debugPrint(
          '[SupabaseService] updateTask gagal: 0 record diperbarui untuk task ID: $id. '
          'Penyebab potensial: ID tidak ditemukan atau RLS UPDATE policy pada tabel "tasks" menolak.',
        );
        throw Exception(
          'Gagal memperbarui tugas: Data tidak ditemukan atau operasi ditolak oleh database (RLS).',
        );
      }

      debugPrint('[SupabaseService] updateTask sukses untuk task ID: $id');
      return Map<String, dynamic>.from(response.first as Map);
    } catch (e) {
      debugPrint('[SupabaseService] updateTask error: $e');
      rethrow;
    }
  }

  /// Memperbarui kolom is_archived secara spesifik untuk tugas berdasarkan id
  Future<Map<String, dynamic>> updateTaskArchiveStatus(
    String id,
    bool isArchived,
  ) async {
    return updateTask(id, {'is_archived': isArchived});
  }

  /// Menghapus tugas dari tabel 'tasks' di Supabase berdasarkan primary key (id).
  /// Menggunakan filter .eq('id', id) agar hanya tugas yang dipilih yang dihapus.
  /// Memastikan sesi autentikasi pengguna aktif untuk mematuhi RLS.
  Future<void> deleteTask(String id) async {
    try {
      if (id.trim().isEmpty) {
        throw ArgumentError('ID tugas tidak boleh kosong untuk operasi delete.');
      }

      if (clientInstance.auth.currentUser == null) {
        debugPrint(
          '[SupabaseService] currentUser null sebelum delete, mencoba ensureAnonymousSession()...',
        );
        await ensureAnonymousSession();
      }

      final auth = clientInstance.auth;
      final session = auth.currentSession;
      final user = auth.currentUser;
      final hasAccessToken =
          session?.accessToken != null && session!.accessToken.isNotEmpty;

      debugPrint('[SupabaseService] Diagnostic pre-delete:');
      debugPrint('  - isInitialized: $isInitialized');
      debugPrint('  - target task id to delete: $id');
      debugPrint('  - user ID: ${user?.id ?? "null"}');
      debugPrint('  - is anonymous: ${user?.isAnonymous ?? false}');

      if (user == null || session == null || !hasAccessToken) {
        throw const AuthException(
          'Gagal menghapus tugas: Sesi autentikasi Supabase tidak ditemukan (user/session null). '
          'Pastikan sesi aktif tersedia sebelum melakukan delete.',
        );
      }

      // Menjalankan query DELETE pada tabel 'tasks' dengan filter ID spesifik.
      // Chaining .select() memastikan PostgREST mengembalikan record yang benar-benar terhapus.
      final List<dynamic> response = await clientInstance
          .from('tasks')
          .delete()
          .eq('id', id)
          .select();

      debugPrint('[SupabaseService] deleteTask response count: ${response.length}');

      // Jika response kosong, PostgREST tidak menghapus record apapun (karena ID tidak ada atau RLS menolak)
      if (response.isEmpty) {
        debugPrint(
          '[SupabaseService] deleteTask gagal: 0 record terhapus untuk task ID: $id. '
          'Penyebab potensial: ID tidak ditemukan, record milik akun lain, atau RLS DELETE policy pada tabel "tasks" '
          'belum mengizinkan user ID: ${user.id}.',
        );
        throw Exception(
          'Gagal menghapus tugas: Data tidak ditemukan atau operasi ditolak oleh database (RLS). '
          'Pastikan policy DELETE pada tabel "tasks" di Supabase telah diizinkan untuk akun pengguna ini.',
        );
      }

      debugPrint('[SupabaseService] deleteTask sukses untuk task ID: $id (${response.length} record terhapus)');
    } catch (e) {
      debugPrint('[SupabaseService] deleteTask error: $e');
      rethrow;
    }
  }

  /// Mengambil data profil pengguna dari tabel 'profiles' di Supabase
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      if (clientInstance.auth.currentUser == null) {
        await ensureAnonymousSession();
      }

      final response = await clientInstance
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('[SupabaseService] getProfile error: $e');
      rethrow;
    }
  }

  /// Memperbarui atau menyimpan data profil pengguna pada tabel 'profiles'
  /// Menggunakan id pengguna aktif untuk mematuhi RLS
  Future<Map<String, dynamic>> upsertProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      if (clientInstance.auth.currentUser == null) {
        await ensureAnonymousSession();
      }

      final auth = clientInstance.auth;
      final user = auth.currentUser;
      final session = auth.currentSession;
      final hasAccessToken =
          session?.accessToken != null && session!.accessToken.isNotEmpty;

      if (user == null || session == null || !hasAccessToken) {
        throw const AuthException(
          'Gagal menyimpan profil: Sesi autentikasi Supabase tidak ditemukan.',
        );
      }

      final payload = Map<String, dynamic>.from(profileData);
      payload['id'] = user.id;
      payload['updated_at'] = DateTime.now().toIso8601String();

      final response = await clientInstance
          .from('profiles')
          .upsert(payload, onConflict: 'id')
          .select()
          .single();

      // Sinkronisasi data ke metadata autentikasi Supabase untuk redundansi
      try {
        await auth.updateUser(
          UserAttributes(
            data: {
              'name': payload['name'],
              'student_id': payload['student_id'],
              'class_name': payload['class_name'],
              'study_program': payload['study_program'],
              'university': payload['university'],
              if (payload['photo_url'] != null)
                'photo_url': payload['photo_url'],
            },
          ),
        );
      } catch (authError) {
        debugPrint('[SupabaseService] updateUser metadata warning: $authError');
      }

      debugPrint(
        '[SupabaseService] upsertProfile sukses untuk user: ${user.id}',
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('[SupabaseService] upsertProfile error: $e');
      rethrow;
    }
  }

  /// Mengunggah berkas foto profil ke Supabase Storage (bucket 'avatars')
  /// Mengembalikan URL publik foto profil yang tersimpan
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    try {
      if (clientInstance.auth.currentUser == null) {
        await ensureAnonymousSession();
      }

      final currentUser = clientInstance.auth.currentUser;

      if (currentUser == null || currentUser.id != userId) {
        throw const AuthException(
          'ID pengguna tidak cocok dengan sesi autentikasi aktif.',
        );
      }

      final ext = fileExtension.replaceAll('.', '').toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/avatar_$timestamp.$ext';

      String contentType = 'image/jpeg';
      if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else if (ext == 'gif') {
        contentType = 'image/gif';
      }

      await clientInstance.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      final publicUrl = clientInstance.storage
          .from('avatars')
          .getPublicUrl(storagePath);
      debugPrint('[SupabaseService] uploadProfilePhoto sukses: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[SupabaseService] uploadProfilePhoto error: $e');
      rethrow;
    }
  }
}
