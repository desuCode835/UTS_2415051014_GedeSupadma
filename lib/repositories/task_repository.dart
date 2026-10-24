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

      final rawTasks = await _supabaseService.getTasks();
      return rawTasks.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
