class UserProfile {
  final String id;
  final String name;
  final String studentId;
  final String className;
  final String studyProgram;
  final String university;
  final String? email;
  final String? photoUrl;
  final bool isAnonymous;

  const UserProfile({
    required this.id,
    required this.name,
    required this.studentId,
    required this.className,
    required this.studyProgram,
    required this.university,
    this.email,
    this.photoUrl,
    this.isAnonymous = false,
  });

  /// Profil baku mahasiswa untuk identitas akademik pengembang/mahasiswa
  static const UserProfile defaultStudent = UserProfile(
    id: 'student-2415051014',
    name: 'Gede Supadma',
    studentId: '2415051014',
    className: 'PTI 5A',
    studyProgram: 'Pendidikan Teknik Informatika',
    university: 'Universitas Pendidikan Ganesha',
    isAnonymous: false,
  );

  /// Profil dinamis untuk sesi autentikasi anonim di Supabase
  factory UserProfile.fromAnonymousUser({
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    final name = metadata?['name'] as String? ?? 'Pengguna Tamu';
    final nim = metadata?['student_id'] as String? ??
        metadata?['nim'] as String? ??
        'Belum Ditautkan';
    final kelas = metadata?['class_name'] as String? ??
        metadata?['kelas'] as String? ??
        'PTI 5A';
    final prodi = metadata?['study_program'] as String? ??
        metadata?['prodi'] as String? ??
        'Pendidikan Teknik Informatika';
    final univ = metadata?['university'] as String? ??
        'Universitas Pendidikan Ganesha';

    return UserProfile(
      id: userId,
      name: name,
      studentId: nim,
      className: kelas,
      studyProgram: prodi,
      university: univ,
      isAnonymous: true,
    );
  }

  /// Inisial nama untuk avatar monogram
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? studentId,
    String? className,
    String? studyProgram,
    String? university,
    String? email,
    String? photoUrl,
    bool? isAnonymous,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      studentId: studentId ?? this.studentId,
      className: className ?? this.className,
      studyProgram: studyProgram ?? this.studyProgram,
      university: university ?? this.university,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'student_id': studentId,
      'class_name': className,
      'study_program': studyProgram,
      'university': university,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photo_url': photoUrl,
      'is_anonymous': isAnonymous,
    };
  }

  /// Format data untuk tabel public.profiles di Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'student_id': studentId,
      'class_name': className,
      'study_program': studyProgram,
      'university': university,
      'photo_url': photoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Pengguna TaskMate',
      studentId: (json['student_id'] ?? json['nim'] ?? json['studentId'] ?? '-') as String,
      className: (json['class_name'] ?? json['kelas'] ?? json['className'] ?? 'PTI 5A') as String,
      studyProgram: (json['study_program'] ?? json['prodi'] ?? json['studyProgram'] ?? 'Pendidikan Teknik Informatika') as String,
      university:
          (json['university'] ?? 'Universitas Pendidikan Ganesha') as String,
      email: json['email'] as String?,
      photoUrl: (json['photo_url'] ?? json['photoUrl']) as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
    );
  }
}
