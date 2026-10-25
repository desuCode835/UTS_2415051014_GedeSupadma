import 'dart:typed_data';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final SupabaseService _supabaseService;

  ProfileRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Mengambil data profil pengguna aktif dari Supabase
  /// Bila Supabase belum diinisialisasi atau data belum ada, mengembalikan profil baku
  Future<UserProfile> getProfile({String? userId}) async {
    try {
      if (!_supabaseService.isInitialized) {
        return UserProfile.defaultStudent;
      }

      await _supabaseService.ensureAnonymousSession();

      final activeUserId = userId ?? _supabaseService.currentUserId;
      if (activeUserId == null || activeUserId.isEmpty) {
        return UserProfile.defaultStudent;
      }

      final profileMap = await _supabaseService.getProfile(activeUserId);
      if (profileMap != null) {
        return UserProfile.fromJson(profileMap);
      }

      // Periksa fallback ke metadata autentikasi Supabase
      try {
        final client = _supabaseService.clientInstance;
        final user = client.auth.currentUser;
        if (user != null && user.userMetadata != null) {
          final metadata = user.userMetadata!;
          if (metadata.containsKey('name') ||
              metadata.containsKey('student_id') ||
              metadata.containsKey('nim')) {
            return UserProfile.fromAnonymousUser(
              userId: user.id,
              metadata: metadata,
            ).copyWith(
              photoUrl: metadata['photo_url'] as String?,
            );
          }
        }
      } catch (_) {}

      return UserProfile.defaultStudent.copyWith(
        id: activeUserId,
        isAnonymous: true,
      );
    } catch (e) {
      // Pertahankan profil fallback jika terjadi error
      return UserProfile.defaultStudent;
    }
  }

  /// Memperbarui data profil pengguna di Supabase
  /// Jika newPhotoBytes diberikan, berkas akan diunggah ke Supabase Storage terlebih dahulu
  Future<UserProfile> updateProfile({
    required String name,
    required String studentId,
    String? className,
    String? studyProgram,
    String? university,
    String? photoUrl,
    Uint8List? newPhotoBytes,
    String? fileExtension,
    bool clearPhoto = false,
  }) async {
    final trimmedName = name.trim();
    final trimmedStudentId = studentId.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Nama tidak boleh kosong');
    }
    if (trimmedStudentId.isEmpty) {
      throw ArgumentError('NIM tidak boleh kosong');
    }

    if (!_supabaseService.isInitialized) {
      return UserProfile.defaultStudent.copyWith(
        name: trimmedName,
        studentId: trimmedStudentId,
        className: className ?? UserProfile.defaultStudent.className,
        studyProgram: studyProgram ?? UserProfile.defaultStudent.studyProgram,
        university: university ?? UserProfile.defaultStudent.university,
        photoUrl: clearPhoto ? null : photoUrl,
      );
    }

    await _supabaseService.ensureAnonymousSession();
    final activeUserId = _supabaseService.currentUserId;
    if (activeUserId == null || activeUserId.isEmpty) {
      throw Exception('Sesi pengguna tidak valid');
    }

    String? finalPhotoUrl = photoUrl;

    if (newPhotoBytes != null && newPhotoBytes.isNotEmpty) {
      finalPhotoUrl = await _supabaseService.uploadProfilePhoto(
        userId: activeUserId,
        bytes: newPhotoBytes,
        fileExtension: fileExtension ?? 'jpg',
      );
    } else if (clearPhoto) {
      finalPhotoUrl = null;
    }

    final profileToSave = UserProfile(
      id: activeUserId,
      name: trimmedName,
      studentId: trimmedStudentId,
      className: className ?? 'PTI 5A',
      studyProgram: studyProgram ?? 'Pendidikan Teknik Informatika',
      university: university ?? 'Universitas Pendidikan Ganesha',
      photoUrl: finalPhotoUrl,
      isAnonymous: true,
    );

    final savedMap = await _supabaseService.upsertProfile(
      profileToSave.toSupabaseMap(),
    );

    return UserProfile.fromJson(savedMap);
  }
}
