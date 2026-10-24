import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/services/supabase_service.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/data/sample_tasks.dart';

class FakeSupabaseService extends SupabaseService {
  final List<Map<String, dynamic>>? mockData;
  final Exception? exceptionToThrow;
  String? mockUserId;
  Map<String, dynamic>? lastInsertedPayload;

  FakeSupabaseService({
    this.mockData,
    this.exceptionToThrow,
    this.mockUserId = 'fake-anon-user-uuid',
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
  Future<List<Map<String, dynamic>>> getTasks() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
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
}

class FakeTaskRepository extends TaskRepository {
  final List<Task>? tasksToReturn;
  final Exception? exceptionToThrow;
  Task? taskToReturnOnCreate;
  Map<String, dynamic>? lastCreatedTaskArgs;

  FakeTaskRepository({
    this.tasksToReturn,
    this.exceptionToThrow,
    this.taskToReturnOnCreate,
  });

  @override
  Future<List<Task>> getTasks() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
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
    };
    return taskToReturnOnCreate ??
        Task(
          id: 'mock-created-task-uuid',
          title: title,
          description: description,
          deadline: deadline,
          priority: priority,
          isCompleted: isCompleted,
          userId: 'fake-anon-user-uuid',
        );
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
  });
}
