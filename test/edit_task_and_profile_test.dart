import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/models/user_profile.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/providers/profile_provider.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/repositories/profile_repository.dart';
import 'package:uts_2415051014_gedesupadma/screens/edit_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/edit_profile_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/profile_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';

class MockTaskRepository extends TaskRepository {
  final bool shouldFail;
  final String errorMessage;
  Task? lastUpdatedTask;

  MockTaskRepository({
    this.shouldFail = false,
    this.errorMessage = '42501: new row violates row-level security policy for table "tasks"',
  });

  @override
  Future<Task> updateTask(Task task) async {
    if (shouldFail) {
      throw Exception(errorMessage);
    }
    lastUpdatedTask = task;
    return task;
  }
}

class MockProfileRepository extends ProfileRepository {
  final bool shouldFail;
  final String errorMessage;
  UserProfile? lastUpdatedProfile;

  MockProfileRepository({
    this.shouldFail = false,
    this.errorMessage = '42501: permission denied for table profiles',
  });

  @override
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
    if (shouldFail) {
      throw Exception(errorMessage);
    }
    final updated = UserProfile(
      id: 'mock-user-123',
      name: name.trim(),
      studentId: studentId.trim(),
      className: className ?? 'PTI 5A',
      studyProgram: studyProgram ?? 'Pendidikan Teknik Informatika',
      university: university ?? 'Universitas Pendidikan Ganesha',
      photoUrl: clearPhoto
          ? null
          : (newPhotoBytes != null
              ? 'https://supabase.co/storage/mock_avatar.jpg'
              : photoUrl),
    );
    lastUpdatedProfile = updated;
    return updated;
  }
}

void main() {
  group('Tahap 11 — Edit Task Form & Validations', () {
    const sampleTask = Task(
      id: 'task-edit-1',
      title: 'Laporan Algoritma',
      description: 'Laporan praktikum modul sorting.',
      deadline: '28 Okt 2026, 23:59 WITA',
      priority: 'Tinggi',
      isCompleted: true,
      userId: 'user-owner-123',
    );

    testWidgets('EditTaskScreen opens and pre-populates existing task data',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: EditTaskScreen(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Tugas'), findsOneWidget);
      expect(find.text('Laporan Algoritma'), findsOneWidget);
      expect(find.text('Laporan praktikum modul sorting.'), findsOneWidget);
      expect(find.text('28 Okt 2026, 23:59 WITA'), findsOneWidget);
      expect(find.text('Tinggi'), findsWidgets);
      // Status isCompleted dipertahankan
      expect(
        find.text('Status tugas: Selesai (dipertahankan)'),
        findsOneWidget,
      );
    });

    testWidgets('Detail screen edit button opens EditTaskScreen with selected task',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskDetailScreen(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Detail Tugas'), findsOneWidget);
      expect(find.text('Laporan Algoritma'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit Tugas'));
      await tester.pumpAndSettle();

      expect(find.byType(EditTaskScreen), findsOneWidget);
      expect(find.text('Laporan Algoritma'), findsOneWidget);
    });

    testWidgets('EditTaskScreen validates empty and whitespace-only title',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: EditTaskScreen(task: sampleTask),
        ),
      );
      await tester.pumpAndSettle();

      // Kosongkan judul dengan spasi saja
      final titleField = find.widgetWithText(TextField, 'Laporan Algoritma');
      await tester.enterText(titleField, '    ');
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas wajib diisi!'), findsOneWidget);
    });

    testWidgets('EditTaskScreen validates empty deadline', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final taskWithEmptyDeadline = sampleTask.copyWith(deadline: '');

      await tester.pumpWidget(
        MaterialApp(
          home: EditTaskScreen(task: taskWithEmptyDeadline),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Tenggat waktu (deadline) wajib diisi!'), findsOneWidget);
    });


    testWidgets('EditTaskScreen saves valid edit and preserves isCompleted',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockTaskRepository();
      final provider = TaskProvider(
        repository: mockRepo,
        initialTasks: [sampleTask],
      );

      Task? updatedResult;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    updatedResult = await Navigator.push<Task>(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const EditTaskScreen(task: sampleTask),
                      ),
                    );
                  },
                  child: const Text('Buka Edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(EditTaskScreen), findsOneWidget);

      // Ubah judul dan prioritas
      final titleField = find.widgetWithText(TextField, 'Laporan Algoritma');
      await tester.enterText(titleField, 'Laporan Algoritma & Struktur Data');
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Form ditutup kembali ke halaman pemanggil
      expect(find.byType(EditTaskScreen), findsNothing);
      expect(updatedResult, isNotNull);
      expect(updatedResult!.id, 'task-edit-1');
      expect(updatedResult!.title, 'Laporan Algoritma & Struktur Data');
      expect(updatedResult!.isCompleted, isTrue); // isCompleted tidak berubah
      expect(updatedResult!.userId, 'user-owner-123'); // user_id dipertahankan

      // Provider lokal terupdate
      expect(
        provider.tasks.first.title,
        'Laporan Algoritma & Struktur Data',
      );
    });

    testWidgets(
        'EditTaskScreen keeps form open and preserves input if save fails',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final failingRepo = MockTaskRepository(
        shouldFail: true,
        errorMessage: '42501: new row violates row-level security policy for table "tasks"',
      );
      final provider = TaskProvider(
        repository: failingRepo,
        initialTasks: [sampleTask],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: EditTaskScreen(task: sampleTask),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Masukkan judul baru yang diedit
      final titleField = find.widgetWithText(TextField, 'Laporan Algoritma');
      await tester.enterText(titleField, 'Perubahan Judul Yang Akan Gagal');
      await tester.pumpAndSettle();

      // Tap Simpan
      final saveButton = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verifikasi form tetap terbuka
      expect(find.byType(EditTaskScreen), findsOneWidget);

      // Verifikasi input pengguna tidak hilang
      expect(find.text('Perubahan Judul Yang Akan Gagal'), findsOneWidget);

      // Verifikasi SnackBar error muncul
      expect(
        find.textContaining('Gagal memperbarui tugas'),
        findsOneWidget,
      );

      // Verifikasi state provider tidak berubah
      expect(provider.tasks.first.title, 'Laporan Algoritma');
    });
  });

  group('Tahap 11 — Menandai Tugas Selesai (Toggle Completion)', () {
    const uncompletedTask = Task(
      id: 'task-detail-toggle-1',
      title: 'Tugas Praktikum Algoritma',
      description: 'Implementasi graph BFS',
      deadline: '29 Okt 2026, 23:59 WITA',
      priority: 'Tinggi',
      isCompleted: false,
      userId: 'user-toggle-1',
    );

    testWidgets('TaskDetailScreen toggles completion and sends is_completed: true to provider',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockTaskRepository();
      final provider = TaskProvider(
        repository: mockRepo,
        initialTasks: [uncompletedTask],
      );

      Task? updatedFromCallback;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: TaskDetailScreen(
              task: uncompletedTask,
              onTaskUpdated: (t) {
                updatedFromCallback = t;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Selesai (Dalam Proses)'), findsOneWidget);
      expect(find.text('Tandai Selesai'), findsOneWidget);

      // Tap Tandai Selesai
      final completeButton = find.text('Tandai Selesai');
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      // Verifikasi repository menerima task dengan isCompleted: true
      expect(mockRepo.lastUpdatedTask?.id, 'task-detail-toggle-1');
      expect(mockRepo.lastUpdatedTask?.isCompleted, isTrue);

      // Verifikasi UI berubah menjadi Selesai Dikerjakan dan label tombol berubah
      expect(find.text('Selesai Dikerjakan'), findsOneWidget);
      expect(find.text('Tandai Belum'), findsOneWidget);

      // Verifikasi callback terpanggil dengan status true
      expect(updatedFromCallback?.isCompleted, isTrue);

      // Verifikasi SnackBar sukses muncul
      expect(find.text('Tugas ditandai selesai.'), findsOneWidget);

      // Verifikasi Provider state terupdate
      expect(provider.tasks.first.isCompleted, isTrue);
    });

    testWidgets('TaskDetailScreen toggles completion and sends is_completed: false when already completed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final completedTask = uncompletedTask.copyWith(isCompleted: true);
      final mockRepo = MockTaskRepository();
      final provider = TaskProvider(
        repository: mockRepo,
        initialTasks: [completedTask],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: TaskDetailScreen(
              task: completedTask,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selesai Dikerjakan'), findsOneWidget);
      expect(find.text('Tandai Belum'), findsOneWidget);

      // Tap Tandai Belum
      final uncompleteButton = find.text('Tandai Belum');
      await tester.ensureVisible(uncompleteButton);
      await tester.tap(uncompleteButton);
      await tester.pumpAndSettle();

      // Verifikasi repository menerima task dengan isCompleted: false
      expect(mockRepo.lastUpdatedTask?.isCompleted, isFalse);
      expect(find.text('Belum Selesai (Dalam Proses)'), findsOneWidget);
      expect(find.text('Tandai Selesai'), findsOneWidget);
      expect(provider.tasks.first.isCompleted, isFalse);
    });

    testWidgets('TaskDetailScreen shows error SnackBar and does not change status if DB fails',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final failingRepo = MockTaskRepository(
        shouldFail: true,
        errorMessage: '42501: new row violates row-level security policy for table "tasks"',
      );
      final provider = TaskProvider(
        repository: failingRepo,
        initialTasks: [uncompletedTask],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: TaskDetailScreen(
              task: uncompletedTask,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Selesai (Dalam Proses)'), findsOneWidget);

      // Tap Tandai Selesai
      final completeButton = find.text('Tandai Selesai');
      await tester.ensureVisible(completeButton);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      // Verifikasi status tugas TIDAK berubah karena database gagal
      expect(find.text('Belum Selesai (Dalam Proses)'), findsOneWidget);
      expect(find.text('Tandai Selesai'), findsOneWidget);
      expect(provider.tasks.first.isCompleted, isFalse);

      // Verifikasi SnackBar error muncul
      expect(find.textContaining('Gagal memperbarui status tugas'), findsOneWidget);
    });
  });

  group('Tahap 11 — Perbaikan Profil Mahasiswa & UserProfile', () {

    const testCustomProfile = UserProfile(
      id: 'custom-user-uuid-777',
      name: 'I Putu Arya Wira',
      studentId: '2415051099',
      className: 'PTI 5B',
      studyProgram: 'Pendidikan Teknik Informatika',
      university: 'Universitas Pendidikan Ganesha',
      isAnonymous: true,
    );

    testWidgets('ProfileScreen renders dynamic user profile and initials',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(profile: testCustomProfile),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('I Putu Arya Wira'), findsOneWidget);
      expect(find.text('NIM: 2415051099 • PTI 5B'), findsOneWidget);
      expect(find.text('2415051099'), findsOneWidget);
      expect(find.text('PTI 5B'), findsOneWidget);
      expect(find.text('Pendidikan Teknik Informatika'), findsOneWidget);
      expect(find.text('Status Akun & Penyimpanan'), findsNothing);
      expect(find.text('IW'), findsOneWidget); // Inisial I Putu Arya Wira -> IW
    });


    testWidgets('Photo upload options displays persistent storage and camera/gallery choices',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(profile: testCustomProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Unggah / Ganti Foto
      await tester.tap(find.text('Unggah / Ganti Foto'));
      await tester.pumpAndSettle();

      expect(find.text('Foto Profil Pengguna'), findsOneWidget);
      expect(
        find.textContaining('Supabase Storage'),
        findsOneWidget,
      );
      expect(find.text('Pilih dari Galeri Foto'), findsOneWidget);
      expect(find.text('Ambil Foto Kamera'), findsOneWidget);
      expect(find.text('Formulir Edit Profil Lengkap'), findsOneWidget);
    });

    testWidgets('Edit Profil button on ProfileScreen opens EditProfileScreen with pre-filled data',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(profile: testCustomProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Tombol Edit Profil tersedia di layar
      final editButton = find.byKey(const Key('btn_edit_profile'));
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      // Terbuka layar EditProfileScreen
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('I Putu Arya Wira'), findsWidgets);
      expect(find.text('2415051099'), findsOneWidget);
      expect(find.text('PTI 5B'), findsOneWidget);
    });

    testWidgets('EditProfileScreen validates empty name and empty studentId',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: EditProfileScreen(profile: testCustomProfile),
        ),
      );
      await tester.pumpAndSettle();

      // Kosongkan nama
      final nameField = find.widgetWithText(TextFormField, 'I Putu Arya Wira');
      await tester.enterText(nameField, '   ');

      // Kosongkan NIM
      final nimField = find.widgetWithText(TextFormField, '2415051099');
      await tester.enterText(nimField, '   ');

      // Tekan tombol simpan
      final saveButton = find.byKey(const Key('btn_save_profile'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validasi muncul
      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
      expect(find.text('NIM tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('EditProfileScreen updates name and NIM and reflects immediately',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockProfileRepository();
      final provider = ProfileProvider(
        repository: mockRepo,
        initialProfile: testCustomProfile,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('I Putu Arya Wira'), findsOneWidget);
      expect(find.text('2415051099'), findsOneWidget);

      // Buka Edit Profile
      await tester.tap(find.byKey(const Key('btn_edit_profile')));
      await tester.pumpAndSettle();

      // Ubah nama dan NIM
      final nameField = find.widgetWithText(TextFormField, 'I Putu Arya Wira');
      await tester.enterText(nameField, 'Gede Supadma Baru');

      final nimField = find.widgetWithText(TextFormField, '2415051099');
      await tester.enterText(nimField, '2415051014');

      final saveButton = find.byKey(const Key('btn_save_profile'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Form tertutup dan kembali ke ProfileScreen dengan data terbaru
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('Gede Supadma Baru'), findsOneWidget);
      expect(find.text('2415051014'), findsOneWidget);
      expect(find.text('Profil berhasil diperbarui.'), findsOneWidget);

      // Verifikasi state provider terupdate
      expect(provider.profile.name, 'Gede Supadma Baru');
      expect(provider.profile.studentId, '2415051014');
      expect(mockRepo.lastUpdatedProfile?.name, 'Gede Supadma Baru');
      expect(mockRepo.lastUpdatedProfile?.studentId, '2415051014');
    });

    testWidgets('EditProfileScreen shows error SnackBar and preserves inputs if save fails',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final failingRepo = MockProfileRepository(
        shouldFail: true,
        errorMessage: '42501: new row violates row-level security policy for table "profiles"',
      );
      final provider = ProfileProvider(
        repository: failingRepo,
        initialProfile: testCustomProfile,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: EditProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'I Putu Arya Wira');
      await tester.enterText(nameField, 'Nama Uji Coba');

      final saveButton = find.byKey(const Key('btn_save_profile'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verifikasi SnackBar error muncul
      expect(find.textContaining('Gagal menyimpan profil'), findsOneWidget);

      // Verifikasi input form tetap terjaga
      expect(find.text('Nama Uji Coba'), findsOneWidget);

      // Profile lama tidak terhapus
      expect(provider.profile.name, 'I Putu Arya Wira');
    });

    testWidgets('ProfileScreen and EditTaskScreen render without overflow on all supported widths',
        (tester) async {
      const screenWidths = [320.0, 390.0, 700.0, 1000.0];

      for (final width in screenWidths) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        // Audit ProfileScreen
        await tester.pumpWidget(
          const MaterialApp(
            home: ProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'ProfileScreen overflow on ${width}px');

        // Audit EditProfileScreen
        await tester.pumpWidget(
          const MaterialApp(
            home: EditProfileScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'EditProfileScreen overflow on ${width}px');

        // Audit EditTaskScreen
        await tester.pumpWidget(
          const MaterialApp(
            home: EditTaskScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'EditTaskScreen overflow on ${width}px');
      }

      tester.view.resetPhysicalSize();
    });
  });
}
