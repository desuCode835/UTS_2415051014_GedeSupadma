import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../data/sample_tasks.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks;
  bool _isLoading = false;
  String? _errorMessage;

  TaskProvider({List<Task>? initialTasks})
      : _tasks = initialTasks != null ? List.from(initialTasks) : [];

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
      _tasks = List.from(sampleTasks);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat daftar tugas: $e';
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
