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
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;
  int get pendingTasks => _tasks.where((t) => !t.isCompleted).length;

  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedTasks = await _repository.getTasks();
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

  void addTask(Task task) {
    _tasks.insert(0, task);
    _errorMessage = null;
    notifyListeners();
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
