import '../models/task.dart';
import '../services/supabase_service.dart';
import '../data/sample_tasks.dart';

class TaskRepository {
  final SupabaseService _supabaseService;

  TaskRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Mengambil daftar tugas dari Supabase.
  /// Bila Supabase belum diinisialisasi (misal saat running unit test tanpa mocking),
  /// menggunakan data contoh dari sampleTasks.
  Future<List<Task>> getTasks() async {
    try {
      if (!_supabaseService.isInitialized) {
        return List<Task>.from(sampleTasks);
      }

      await _supabaseService.ensureAnonymousSession();

      final rawTasks = await _supabaseService.getTasks();
      return rawTasks.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Menambahkan tugas baru ke Supabase.
  /// Kolom database yang dikirim: title, description, deadline, priority, is_completed.
  /// ID dan created_at dibuat otomatis oleh Supabase.
  /// user_id diisi otomatis dari sesi autentikasi Supabase.
  /// Bila Supabase belum diinisialisasi (misal saat testing offline),
  /// mengembalikan objek Task lokal.
  Future<Task> createTask({
    required String title,
    String description = '',
    required String deadline,
    required String priority,
    bool isCompleted = false,
  }) async {
    try {
      final taskMap = <String, dynamic>{
        'title': title,
        'description': description,
        'deadline': deadline,
        'priority': priority,
        'is_completed': isCompleted,
      };

      if (!_supabaseService.isInitialized) {
        return Task(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          deadline: deadline,
          priority: priority,
          isCompleted: isCompleted,
        );
      }

      await _supabaseService.ensureAnonymousSession();

      final insertedData = await _supabaseService.insertTask(taskMap);
      return Task.fromJson(insertedData);
    } catch (e) {
      rethrow;
    }
  }

  /// Helper untuk menambahkan Task yang sudah berupa instance model
  Future<Task> addTask(Task task) async {
    return createTask(
      title: task.title,
      description: task.description,
      deadline: task.deadline,
      priority: task.priority,
      isCompleted: task.isCompleted,
    );
  }
}
