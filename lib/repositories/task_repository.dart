import '../models/task.dart';
import '../services/supabase_service.dart';
import '../data/sample_tasks.dart';

class TaskRepository {
  final SupabaseService _supabaseService;

  TaskRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Mengambil daftar tugas dari Supabase.
  /// Dapat difilter berdasarkan status arsip jika parameter isArchived disediakan.
  /// Bila Supabase belum diinisialisasi (misal saat running unit test tanpa mocking),
  /// menggunakan data contoh dari sampleTasks.
  Future<List<Task>> getTasks({bool? isArchived}) async {
    try {
      if (!_supabaseService.isInitialized) {
        if (isArchived != null) {
          return sampleTasks.where((t) => t.isArchived == isArchived).toList();
        }
        return List<Task>.from(sampleTasks);
      }

      await _supabaseService.ensureAnonymousSession();

      final rawTasks = await _supabaseService.getTasks(isArchived: isArchived);
      return rawTasks.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Menambahkan tugas baru ke Supabase.
  /// Kolom database yang dikirim: title, description, deadline, priority, is_completed, is_archived, course_category.
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
    bool isArchived = false,
    String? courseCategory,
  }) async {
    try {
      final taskMap = <String, dynamic>{
        'title': title,
        'description': description,
        'deadline': deadline,
        'priority': priority,
        'is_completed': isCompleted,
        'is_archived': isArchived,
        'course_category': courseCategory,
      };

      if (!_supabaseService.isInitialized) {
        return Task(
          id: 'task_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          deadline: deadline,
          priority: priority,
          isCompleted: isCompleted,
          isArchived: isArchived,
          courseCategory: courseCategory,
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
      isArchived: task.isArchived,
      courseCategory: task.courseCategory,
    );
  }

  /// Memperbarui data tugas pada database Supabase.
  /// Status isCompleted, isArchived, dan user_id dipertahankan dari task yang diedit.
  /// Bila Supabase belum diinisialisasi (misal saat testing offline),
  /// mengembalikan task yang diberikan.
  Future<Task> updateTask(Task task) async {
    try {
      final taskMap = <String, dynamic>{
        'title': task.title,
        'description': task.description,
        'deadline': task.deadline,
        'priority': task.priority,
        'is_completed': task.isCompleted,
        'is_archived': task.isArchived,
        'course_category': task.courseCategory,
      };

      if (task.userId != null) {
        taskMap['user_id'] = task.userId;
      }

      if (!_supabaseService.isInitialized) {
        return task;
      }

      await _supabaseService.ensureAnonymousSession();

      final updatedData = await _supabaseService.updateTask(task.id, taskMap);
      return Task.fromJson(updatedData);
    } catch (e) {
      rethrow;
    }
  }

  /// Mengubah status selesai tugas (is_completed) dan memperbaruinya di Supabase.
  /// Mempertahankan status isArchived sebelumnya.
  Future<Task> toggleTaskCompletion(Task task) async {
    final toggled = task.copyWith(isCompleted: !task.isCompleted);
    return updateTask(toggled);
  }

  /// Mengarsipkan tugas (is_archived = true) dan memperbaruinya di Supabase.
  /// Mempertahankan status isCompleted sebelumnya.
  Future<Task> archiveTask(Task task) async {
    final archived = task.copyWith(isArchived: true);
    return updateTask(archived);
  }

  /// Memulihkan tugas dari arsip (is_archived = false) dan memperbaruinya di Supabase.
  /// Mempertahankan status isCompleted sebelumnya.
  Future<Task> restoreTask(Task task) async {
    final restored = task.copyWith(isArchived: false);
    return updateTask(restored);
  }

  /// Mengubah status arsip tugas (toggle is_archived) dan memperbaruinya di Supabase.
  Future<Task> toggleTaskArchive(Task task) async {
    final toggled = task.copyWith(isArchived: !task.isArchived);
    return updateTask(toggled);
  }
}


