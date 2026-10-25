import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../data/sample_tasks.dart';
import '../repositories/task_repository.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _repository;
  List<Task> _tasks;
  bool _isLoading = false;
  String? _errorMessage;

  TaskProvider({
    TaskRepository? repository,
    List<Task>? initialTasks,
  })  : _repository = repository ?? TaskRepository(),
        _tasks = initialTasks != null ? List.from(initialTasks) : [];

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get activeTasks =>
      List.unmodifiable(_tasks.where((t) => !t.isArchived));
  List<Task> get archivedTasks =>
      List.unmodifiable(_tasks.where((t) => t.isArchived));

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalTasks => _tasks.where((t) => !t.isArchived).length;
  int get completedTasks =>
      _tasks.where((t) => !t.isArchived && t.isCompleted).length;
  int get pendingTasks =>
      _tasks.where((t) => !t.isArchived && !t.isCompleted).length;
  int get archivedTasksCount => _tasks.where((t) => t.isArchived).length;

  Future<void> loadTasks({bool? isArchived}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedTasks = await _repository.getTasks(isArchived: isArchived);
      _tasks = fetchedTasks;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat tugas dari database: $e';
      // Pertahankan data contoh jika database belum tersedia
      if (_tasks.isEmpty) {
        _tasks = List.from(sampleTasks);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menambahkan tugas baru melalui repository ke Supabase.
  /// Mengelola status loading, error, dan menambahkan data ke daftar tugas setelah berhasil.
  Future<Task> createTask({
    required String title,
    String description = '',
    required String deadline,
    required String priority,
    bool isCompleted = false,
    bool isArchived = false,
    String? courseCategory,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTask = await _repository.createTask(
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        isCompleted: isCompleted,
        isArchived: isArchived,
        courseCategory: courseCategory,
      );

      // Masukkan ke daftar hanya jika penyimpanan berhasil
      _tasks.insert(0, newTask);
      _errorMessage = null;
      return newTask;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan tugas ke database: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addTask(Task task) {
    _tasks.insert(0, task);
    _errorMessage = null;
    notifyListeners();
  }

  /// Memperbarui tugas melalui repository ke Supabase.
  /// Mengelola status loading, error, dan hanya memperbarui state lokal setelah operasi database berhasil.
  Future<Task> editTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTask = await _repository.updateTask(task);

      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _errorMessage = null;
      return updatedTask;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui tugas di database: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengubah status selesai tugas (is_completed) dan menyimpannya ke Supabase.
  /// Hanya memperbarui state lokal setelah operasi database berhasil.
  Future<Task> toggleTaskCompletion(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTask = await _repository.toggleTaskCompletion(task);

      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _errorMessage = null;
      return updatedTask;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui status tugas di database: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengarsipkan tugas (is_archived = true) dan memperbaruinya di Supabase.
  /// Hanya memperbarui state lokal setelah operasi database berhasil.
  Future<Task> archiveTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTask = await _repository.archiveTask(task);

      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _errorMessage = null;
      return updatedTask;
    } catch (e) {
      _errorMessage = 'Gagal mengarsipkan tugas di database: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memulihkan tugas dari arsip (is_archived = false) dan memperbaruinya di Supabase.
  /// Hanya memperbarui state lokal setelah operasi database berhasil.
  Future<Task> restoreTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTask = await _repository.restoreTask(task);

      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      _errorMessage = null;
      return updatedTask;
    } catch (e) {
      _errorMessage = 'Gagal memulihkan tugas di database: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengubah status arsip tugas (toggle is_archived) dan menyimpannya ke Supabase.
  Future<Task> toggleTaskArchive(Task task) async {
    if (task.isArchived) {
      return restoreTask(task);
    } else {
      return archiveTask(task);
    }
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _errorMessage = null;
      notifyListeners();
    } else {
      _errorMessage = 'Tugas dengan ID "${updatedTask.id}" tidak ditemukan';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
