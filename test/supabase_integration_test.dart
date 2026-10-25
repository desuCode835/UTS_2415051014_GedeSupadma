import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/models/user_profile.dart';
import 'package:uts_2415051014_gedesupadma/services/supabase_service.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/repositories/profile_repository.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/providers/profile_provider.dart';
import 'package:uts_2415051014_gedesupadma/data/sample_tasks.dart';

class FakeSupabaseService extends SupabaseService {
  final List<Map<String, dynamic>>? mockData;
  final Exception? exceptionToThrow;
  String? mockUserId;
  Map<String, dynamic>? lastInsertedPayload;
  Map<String, dynamic>? mockProfileData;
  Map<String, dynamic>? lastUpsertedProfile;
  Uint8List? lastUploadedPhotoBytes;

  FakeSupabaseService({
    this.mockData,
    this.exceptionToThrow,
    this.mockUserId = 'fake-anon-user-uuid',
    this.mockProfileData,
  });

  @override
  bool get isInitialized => true;

  @override
  String? get currentUserId => mockUserId;

  @override
  Future<void> ensureAnonymousSession() async {
    // Sesi anonim disimulasikan siap
  }

  @override
  Future<List<Map<String, dynamic>>> getTasks({bool? isArchived}) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (isArchived != null && mockData != null) {
      return mockData!.where((m) => m['is_archived'] == isArchived).toList();
    }
    return mockData ?? [];
  }

  @override
  Future<Map<String, dynamic>> insertTask(Map<String, dynamic> taskData) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    final payload = Map<String, dynamic>.from(taskData);
    final userId = currentUserId;
    if (userId != null && userId.isNotEmpty) {
      payload['user_id'] = userId;
    }
    lastInsertedPayload = payload;
    return {
      'id': 'd3b07384-d113-4944-9c8e-8a0b067d5c7f',
      'created_at': '2026-10-24T12:00:00Z',
      ...payload,
    };
  }

  String? lastUpdatedId;
  Map<String, dynamic>? lastUpdatedPayload;

  @override
  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> taskData,
  ) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    lastUpdatedId = id;
    final payload = Map<String, dynamic>.from(taskData);
    payload.remove('id');
    lastUpdatedPayload = payload;
    return {
      'id': id,
      'created_at': '2026-10-24T12:00:00Z',
      ...payload,
    };
  }

  String? lastDeletedId;

  @override
  Future<void> deleteTask(String id) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastDeletedId = id;
    if (mockData != null) {
      final index = mockData!.indexWhere((m) => m['id'] == id);
      if (index == -1) {
        throw Exception(
          'Gagal menghapus tugas: Data tidak ditemukan atau operasi ditolak oleh database (RLS). '
          'Pastikan policy DELETE pada tabel "tasks" di Supabase telah diizinkan untuk akun pengguna ini.',
        );
      }
      mockData!.removeAt(index);
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return mockProfileData;
  }

  @override
  Future<Map<String, dynamic>> upsertProfile(
    Map<String, dynamic> profileData,
  ) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    final payload = Map<String, dynamic>.from(profileData);
    payload['id'] = currentUserId ?? 'mock-user-id';
    lastUpsertedProfile = payload;
    return payload;
  }

  @override
  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    lastUploadedPhotoBytes = bytes;
    return 'https://supabase.co/storage/avatars/$userId/avatar_123456.$fileExtension';
  }
}

class FakeTaskRepository extends TaskRepository {
  final List<Task>? tasksToReturn;
  final Exception? exceptionToThrow;
  Task? taskToReturnOnCreate;
  Map<String, dynamic>? lastCreatedTaskArgs;
  Task? lastUpdatedTask;

  FakeTaskRepository({
    this.tasksToReturn,
    this.exceptionToThrow,
    this.taskToReturnOnCreate,
  });

  @override
  Future<List<Task>> getTasks({bool? isArchived}) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    if (isArchived != null && tasksToReturn != null) {
      return tasksToReturn!.where((t) => t.isArchived == isArchived).toList();
    }
    return tasksToReturn ?? [];
  }

  @override
  Future<Task> createTask({
    required String title,
    String description = '',
    required String deadline,
    required String priority,
    bool isCompleted = false,
    bool isArchived = false,
    String? courseCategory,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    lastCreatedTaskArgs = {
      'title': title,
      'description': description,
      'deadline': deadline,
      'priority': priority,
      'isCompleted': isCompleted,
      'isArchived': isArchived,
      'courseCategory': courseCategory,
    };
    return taskToReturnOnCreate ??
        Task(
          id: 'mock-created-task-uuid',
          title: title,
          description: description,
          deadline: deadline,
          priority: priority,
          isCompleted: isCompleted,
          isArchived: isArchived,
          courseCategory: courseCategory,
          userId: 'fake-anon-user-uuid',
        );
  }

  @override
  Future<Task> updateTask(Task task) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    lastUpdatedTask = task;
    return task;
  }

  String? lastDeletedTaskId;

  @override
  Future<void> deleteTask(String id) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    lastDeletedTaskId = id;
    if (tasksToReturn != null) {
      tasksToReturn!.removeWhere((t) => t.id == id);
    }
  }
}


void main() {
  group('Tahap 9 — Supabase Database Integration Tests', () {
    test('Task.fromJson correctly maps Supabase column names', () {
      final supabaseJson = {
        'id': 'd3b07384-d113-4944-9c8e-8a0b067d5c7f',
        'title': 'Tugas Kuliah Supabase',
        'description': 'Membaca data tugas dari tabel tasks di Supabase.',
        'deadline': '30 Okt 2026, 23:59 WITA',
        'priority': 'Tinggi',
        'is_completed': true,
        'created_at': '2026-10-24T12:00:00Z',
      };

      final task = Task.fromJson(supabaseJson);

      expect(task.id, 'd3b07384-d113-4944-9c8e-8a0b067d5c7f');
      expect(task.title, 'Tugas Kuliah Supabase');
      expect(task.description, 'Membaca data tugas dari tabel tasks di Supabase.');
      expect(task.deadline, '30 Okt 2026, 23:59 WITA');
      expect(task.priority, 'Tinggi');
      expect(task.isCompleted, true);
    });

    test('Task.fromJson handles null description gracefully', () {
      final supabaseJson = {
        'id': 'uuid-1234',
        'title': 'Tugas Tanpa Deskripsi',
        'description': null,
        'deadline': '1 Nov 2026',
        'priority': 'Sedang',
        'is_completed': false,
      };

      final task = Task.fromJson(supabaseJson);

      expect(task.id, 'uuid-1234');
      expect(task.description, '');
      expect(task.isCompleted, false);
    });

    test('TaskRepository maps raw Supabase maps to Task list correctly', () async {
      final fakeService = FakeSupabaseService(
        mockData: [
          {
            'id': 'uuid-1',
            'title': 'Tugas Mandiri Database',
            'description': 'Mempelajari skema relasional.',
            'deadline': '25 Okt 2026',
            'priority': 'Tinggi',
            'is_completed': false,
          },
          {
            'id': 'uuid-2',
            'title': 'Praktikum Mobile PTI',
            'description': 'Menyelesaikan modul 9.',
            'deadline': '26 Okt 2026',
            'priority': 'Sedang',
            'is_completed': true,
          },
        ],
      );

      final repository = TaskRepository(supabaseService: fakeService);
      final tasks = await repository.getTasks();

      expect(tasks.length, 2);
      expect(tasks[0].id, 'uuid-1');
      expect(tasks[0].title, 'Tugas Mandiri Database');
      expect(tasks[0].isCompleted, false);
      expect(tasks[1].id, 'uuid-2');
      expect(tasks[1].isCompleted, true);
    });

    test('TaskRepository falls back to sampleTasks if Supabase is uninitialized', () async {
      final repository = TaskRepository(supabaseService: SupabaseService());
      final tasks = await repository.getTasks();

      expect(tasks.length, sampleTasks.length);
    });

    test('TaskProvider loads tasks from repository and updates state', () async {
      final fakeRepo = FakeTaskRepository(
        tasksToReturn: const [
          Task(
            id: 'cloud-task-1',
            title: 'Tugas dari Cloud Database',
            description: 'Berhasil dimuat dari Supabase.',
            deadline: '28 Okt 2026',
            priority: 'Tinggi',
            isCompleted: false,
          ),
        ],
      );

      final provider = TaskProvider(repository: fakeRepo);
      expect(provider.isLoading, false);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.loadTasks();

      expect(notified, isTrue);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.totalTasks, 1);
      expect(provider.tasks.first.title, 'Tugas dari Cloud Database');
    });

    test('TaskProvider sets errorMessage when repository throws error', () async {
      final fakeRepo = FakeTaskRepository(
        exceptionToThrow: Exception('Koneksi database terputus'),
      );

      final provider = TaskProvider(repository: fakeRepo);
      await provider.loadTasks();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Koneksi database terputus'));
    });
  });

  group('Tahap 10 — Task Creation and Anonymous Auth Integration Tests', () {
    test('Task model maps userId correctly in fromJson and toJson', () {
      final json = {
        'id': 'uuid-task-77',
        'title': 'Tugas Analisis Desain',
        'description': 'Deskripsi analisis desain perangkat lunak.',
        'deadline': '5 Nov 2026, 23:59 WITA',
        'priority': 'Tinggi',
        'is_completed': false,
        'user_id': 'user-uuid-99',
      };

      final task = Task.fromJson(json);
      expect(task.userId, 'user-uuid-99');

      final serialized = task.toJson();
      expect(serialized['user_id'], 'user-uuid-99');
    });

    test('SupabaseService.insertTask attaches current authenticated user_id automatically', () async {
      final fakeService = FakeSupabaseService(mockUserId: 'auth-user-1234');
      final inputData = {
        'title': 'Tugas Baru',
        'description': 'Deskripsi',
        'deadline': '30 Okt 2026',
        'priority': 'Sedang',
        'is_completed': false,
      };

      final result = await fakeService.insertTask(inputData);

      expect(result['id'], isNotNull);
      expect(result['user_id'], 'auth-user-1234');
      expect(fakeService.lastInsertedPayload!['user_id'], 'auth-user-1234');
    });

    test('TaskRepository.createTask sends clean payload without manual id and returns parsed Task', () async {
      final fakeService = FakeSupabaseService(mockUserId: 'auth-user-5678');
      final repo = TaskRepository(supabaseService: fakeService);

      final createdTask = await repo.createTask(
        title: 'Tugas Praktikum Cloud',
        description: 'Implementasi RLS Supabase',
        deadline: '10 Nov 2026, 23:59 WITA',
        priority: 'Tinggi',
      );

      expect(createdTask.id, 'd3b07384-d113-4944-9c8e-8a0b067d5c7f');
      expect(createdTask.title, 'Tugas Praktikum Cloud');
      expect(createdTask.priority, 'Tinggi');
      expect(createdTask.userId, 'auth-user-5678');
      expect(createdTask.isCompleted, isFalse);

      // Pastikan repo tidak mengirim id secara manual ke payload insert
      expect(fakeService.lastInsertedPayload!.containsKey('id'), isFalse);
    });

    test('TaskProvider.createTask handles loading, error, and adds new task to start of list', () async {
      final fakeRepo = FakeTaskRepository();
      final provider = TaskProvider(repository: fakeRepo);

      expect(provider.isLoading, false);
      expect(provider.tasks, isEmpty);

      final task = await provider.createTask(
        title: 'Tugas State Management',
        description: 'Menguji alur provider',
        deadline: '12 Nov 2026',
        priority: 'Sedang',
      );

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'Tugas State Management');
      expect(task.title, 'Tugas State Management');
    });

    test('TaskProvider.createTask sets errorMessage and does not modify list if repository fails', () async {
      final fakeRepo = FakeTaskRepository(
        exceptionToThrow: Exception('new row violates row-level security policy for table "tasks"'),
      );
      final provider = TaskProvider(repository: fakeRepo);

      expect(provider.tasks, isEmpty);

      try {
        await provider.createTask(
          title: 'Tugas Gagal',
          deadline: '15 Nov 2026',
          priority: 'Rendah',
        );
        fail('Harus melempar exception saat repository gagal');
      } catch (e) {
        expect(e.toString(), contains('violates row-level security policy'));
      }

      expect(provider.isLoading, false);
      expect(provider.tasks, isEmpty);
      expect(provider.errorMessage, contains('violates row-level security policy'));
    });

    group('Tahap 11 — Supabase Update Task Tests', () {
      test('SupabaseService.updateTask filters by primary key task ID and excludes id from payload', () async {
        final fakeService = FakeSupabaseService(mockUserId: 'auth-user-1234');
        final updatePayload = {
          'id': 'should-be-removed-from-body',
          'title': 'Judul Diperbarui',
          'description': 'Deskripsi baru',
          'deadline': '5 Nov 2026',
          'priority': 'Tinggi',
          'is_completed': true,
        };

        final result = await fakeService.updateTask('task-target-uuid-88', updatePayload);

        expect(fakeService.lastUpdatedId, 'task-target-uuid-88');
        expect(fakeService.lastUpdatedPayload!.containsKey('id'), isFalse);
        expect(result['id'], 'task-target-uuid-88');
        expect(result['title'], 'Judul Diperbarui');
        expect(result['is_completed'], true);
        expect(result['priority'], 'Tinggi');
      });

      test('TaskRepository.updateTask retains isCompleted and user_id and updates through service', () async {
        final fakeService = FakeSupabaseService(mockUserId: 'auth-user-999');
        final repo = TaskRepository(supabaseService: fakeService);

        const initialTask = Task(
          id: 'task-abc-123',
          title: 'Judul Sebelum Edit',
          description: 'Deskripsi lama',
          deadline: '1 Nov 2026',
          priority: 'Rendah',
          isCompleted: true,
          userId: 'auth-user-999',
        );

        final editedTask = initialTask.copyWith(
          title: 'Judul Sesudah Edit',
          priority: 'Tinggi',
        );

        final result = await repo.updateTask(editedTask);

        expect(result.id, 'task-abc-123');
        expect(result.title, 'Judul Sesudah Edit');
        expect(result.priority, 'Tinggi');
        expect(result.isCompleted, isTrue); // Status isCompleted tidak berubah
        expect(result.userId, 'auth-user-999'); // user_id dipertahankan
        expect(fakeService.lastUpdatedId, 'task-abc-123');
      });

      test('TaskProvider.editTask updates local state only after repository succeeds', () async {
        const initialTask = Task(
          id: 'task-100',
          title: 'Tugas Awal',
          description: 'Awal',
          deadline: '10 Nov 2026',
          priority: 'Sedang',
          isCompleted: false,
        );

        final fakeRepo = FakeTaskRepository(tasksToReturn: [initialTask]);
        final provider = TaskProvider(repository: fakeRepo, initialTasks: [initialTask]);

        expect(provider.tasks.first.title, 'Tugas Awal');

        final updated = initialTask.copyWith(title: 'Tugas Berhasil Diedit');
        final result = await provider.editTask(updated);

        expect(provider.isLoading, false);
        expect(provider.errorMessage, isNull);
        expect(provider.tasks.length, 1);
        expect(provider.tasks.first.title, 'Tugas Berhasil Diedit');
        expect(result.title, 'Tugas Berhasil Diedit');
        expect(fakeRepo.lastUpdatedTask?.id, 'task-100');
      });

      test('TaskProvider.editTask does not modify local task state if repository fails', () async {
        const initialTask = Task(
          id: 'task-100',
          title: 'Tugas Asli Tidak Boleh Berubah',
          description: 'Awal',
          deadline: '10 Nov 2026',
          priority: 'Sedang',
          isCompleted: false,
        );

        final fakeRepo = FakeTaskRepository(
          exceptionToThrow: Exception('42501: new row violates row-level security policy for table "tasks"'),
        );
        final provider = TaskProvider(repository: fakeRepo, initialTasks: [initialTask]);

        expect(provider.tasks.first.title, 'Tugas Asli Tidak Boleh Berubah');

        final attemptedUpdate = initialTask.copyWith(title: 'Judul Ilegal');

        try {
          await provider.editTask(attemptedUpdate);
          fail('Harus melempar exception saat update gagal');
        } catch (e) {
          expect(e.toString(), contains('violates row-level security policy'));
        }

        expect(provider.isLoading, false);
        expect(provider.errorMessage, contains('violates row-level security policy'));
        // State lokal tetap utuh dan tidak berubah
        expect(provider.tasks.first.title, 'Tugas Asli Tidak Boleh Berubah');
      });

      test('TaskRepository.toggleTaskCompletion sends is_completed: true when task is marked complete', () async {
        final fakeService = FakeSupabaseService(mockUserId: 'auth-user-111');
        final repo = TaskRepository(supabaseService: fakeService);

        const uncompletedTask = Task(
          id: 'task-mark-complete-1',
          title: 'Tugas Kuliah Web',
          description: '',
          deadline: '10 Nov 2026',
          priority: 'Sedang',
          isCompleted: false,
          userId: 'auth-user-111',
        );

        final result = await repo.toggleTaskCompletion(uncompletedTask);

        expect(fakeService.lastUpdatedId, 'task-mark-complete-1');
        expect(fakeService.lastUpdatedPayload!['is_completed'], isTrue);
        expect(result.isCompleted, isTrue);
      });

      test('TaskRepository.toggleTaskCompletion sends is_completed: false when task is marked uncomplete', () async {
        final fakeService = FakeSupabaseService(mockUserId: 'auth-user-222');
        final repo = TaskRepository(supabaseService: fakeService);

        const completedTask = Task(
          id: 'task-mark-uncomplete-2',
          title: 'Tugas Kuliah Database',
          description: '',
          deadline: '11 Nov 2026',
          priority: 'Tinggi',
          isCompleted: true,
          userId: 'auth-user-222',
        );

        final result = await repo.toggleTaskCompletion(completedTask);

        expect(fakeService.lastUpdatedId, 'task-mark-uncomplete-2');
        expect(fakeService.lastUpdatedPayload!['is_completed'], isFalse);
        expect(result.isCompleted, isFalse);
      });

      test('TaskProvider.toggleTaskCompletion updates state on success and does not mutate on failure', () async {
        const initialTask = Task(
          id: 'task-provider-toggle-1',
          title: 'Tugas Uji State',
          description: '',
          deadline: '12 Nov 2026',
          priority: 'Sedang',
          isCompleted: false,
        );

        final successRepo = FakeTaskRepository(tasksToReturn: [initialTask]);
        final provider = TaskProvider(repository: successRepo, initialTasks: [initialTask]);

        // 1. Uji keberhasilan toggle
        final updated = await provider.toggleTaskCompletion(initialTask);
        expect(updated.isCompleted, isTrue);
        expect(provider.tasks.first.isCompleted, isTrue);
        expect(provider.errorMessage, isNull);

        // 2. Uji kegagalan toggle: state tidak boleh berubah
        final failingRepo = FakeTaskRepository(
          exceptionToThrow: Exception('42501: RLS update denied'),
        );
        final failingProvider = TaskProvider(repository: failingRepo, initialTasks: [initialTask]);

        try {
          await failingProvider.toggleTaskCompletion(initialTask);
          fail('Harus melempar exception saat toggle gagal di DB');
        } catch (e) {
          expect(e.toString(), contains('RLS update denied'));
        }

        expect(failingProvider.tasks.first.isCompleted, isFalse);
        expect(failingProvider.errorMessage, contains('RLS update denied'));
      });

      test('TaskRepository.deleteTask executes delete on SupabaseService with correct ID', () async {
        final fakeService = FakeSupabaseService(
          mockData: [
            {
              'id': 'task-delete-id-123',
              'title': 'Tugas Uji Delete Supabase',
              'deadline': '1 Des 2026',
              'priority': 'Tinggi',
              'is_completed': false,
            }
          ],
        );
        final repo = TaskRepository(supabaseService: fakeService);

        await repo.deleteTask('task-delete-id-123');

        expect(fakeService.lastDeletedId, 'task-delete-id-123');
        expect(fakeService.mockData!.isEmpty, isTrue);
      });
    });

    group('Profile Supabase & Storage Integration', () {
      test('ProfileRepository.getProfile returns profile from Supabase', () async {
        final fakeService = FakeSupabaseService(
          mockProfileData: {
            'id': 'user-profile-123',
            'name': 'Gede Supadma',
            'student_id': '2415051014',
            'class_name': 'PTI 5A',
            'study_program': 'Pendidikan Teknik Informatika',
            'university': 'Universitas Pendidikan Ganesha',
            'photo_url': 'https://supabase.co/storage/avatars/user-profile-123/avatar.jpg',
          },
        );

        final repo = ProfileRepository(supabaseService: fakeService);
        final profile = await repo.getProfile(userId: 'user-profile-123');

        expect(profile.id, 'user-profile-123');
        expect(profile.name, 'Gede Supadma');
        expect(profile.studentId, '2415051014');
        expect(profile.photoUrl, 'https://supabase.co/storage/avatars/user-profile-123/avatar.jpg');
      });

      test('ProfileRepository.updateProfile uploads photo to storage and upserts profile', () async {
        final fakeService = FakeSupabaseService(
          mockUserId: 'user-profile-456',
        );

        final repo = ProfileRepository(supabaseService: fakeService);
        final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

        final updated = await repo.updateProfile(
          name: 'I Made Developer',
          studentId: '2415051099',
          newPhotoBytes: dummyBytes,
          fileExtension: 'png',
        );

        expect(fakeService.lastUploadedPhotoBytes, dummyBytes);
        expect(fakeService.lastUpsertedProfile!['name'], 'I Made Developer');
        expect(fakeService.lastUpsertedProfile!['student_id'], '2415051099');
        expect(
          fakeService.lastUpsertedProfile!['photo_url'],
          contains('https://supabase.co/storage/avatars/user-profile-456/'),
        );
        expect(updated.name, 'I Made Developer');
        expect(updated.studentId, '2415051099');
      });

      test('ProfileRepository.updateProfile with clearPhoto clears photo_url', () async {
        final fakeService = FakeSupabaseService(
          mockUserId: 'user-profile-789',
        );

        final repo = ProfileRepository(supabaseService: fakeService);

        final updated = await repo.updateProfile(
          name: 'I Ketut Tanpa Foto',
          studentId: '2415051088',
          clearPhoto: true,
        );

        expect(fakeService.lastUpsertedProfile!['photo_url'], isNull);
        expect(updated.photoUrl, isNull);
      });

      test('ProfileProvider manages loading state and isolates errors on save failure', () async {
        final failingService = FakeSupabaseService(
          exceptionToThrow: Exception('42501: permission denied for table profiles'),
        );

        final repo = ProfileRepository(supabaseService: failingService);
        final provider = ProfileProvider(
          repository: repo,
          initialProfile: UserProfile.defaultStudent,
        );

        expect(provider.isLoading, isFalse);

        try {
          await provider.updateProfile(
            name: 'Nama Baru',
            studentId: '2415051000',
          );
          fail('Harus melempar exception saat update gagal');
        } catch (e) {
          expect(e.toString(), contains('permission denied for table profiles'));
        }

        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, contains('permission denied for table profiles'));
        // Profil lama tidak terhapus
        expect(provider.profile.name, UserProfile.defaultStudent.name);
      });
    });
  });
}


