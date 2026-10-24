import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/services/supabase_service.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/data/sample_tasks.dart';

class FakeSupabaseService extends SupabaseService {
  final List<Map<String, dynamic>>? mockData;
  final Exception? exceptionToThrow;

  FakeSupabaseService({this.mockData, this.exceptionToThrow});

  @override
  bool get isInitialized => true;

  @override
  Future<List<Map<String, dynamic>>> getTasks() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return mockData ?? [];
  }
}

class FakeTaskRepository extends TaskRepository {
  final List<Task>? tasksToReturn;
  final Exception? exceptionToThrow;

  FakeTaskRepository({this.tasksToReturn, this.exceptionToThrow});

  @override
  Future<List<Task>> getTasks() async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return tasksToReturn ?? [];
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
      // Default SupabaseService without client in test env has isInitialized == false
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
}
