import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileRepository _repository;
  UserProfile _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileProvider({
    ProfileRepository? repository,
    UserProfile? initialProfile,
  })  : _repository = repository ?? ProfileRepository(),
        _profile = initialProfile ?? UserProfile.defaultStudent;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Memuat data profil dari database Supabase
  Future<void> loadProfile({String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedProfile = await _repository.getProfile(userId: userId);
      _profile = fetchedProfile;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat profil: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memperbarui data profil dan menyimpannya secara persisten ke Supabase
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _repository.updateProfile(
        name: name,
        studentId: studentId,
        className: className ?? _profile.className,
        studyProgram: studyProgram ?? _profile.studyProgram,
        university: university ?? _profile.university,
        photoUrl: photoUrl ?? _profile.photoUrl,
        newPhotoBytes: newPhotoBytes,
        fileExtension: fileExtension,
        clearPhoto: clearPhoto,
      );

      _profile = updatedProfile;
      _errorMessage = null;
      return updatedProfile;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui profil: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengatur data profil secara langsung (berguna untuk testing atau inisialisasi cepat)
  void setProfile(UserProfile newProfile) {
    _profile = newProfile;
    _errorMessage = null;
    notifyListeners();
  }
}
