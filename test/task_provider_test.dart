import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/data/sample_tasks.dart';

void main() {
  group('Tahap 7 — TaskProvider Tests', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider();
    });

    test('Initial state is empty and not loading', () {
      expect(provider.tasks, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.totalTasks, 0);
      expect(provider.completedTasks, 0);
      expect(provider.pendingTasks, 0);
    });

    test('loadTasks() memuat data contoh dan mengakhiri status loading', () async {
      expect(provider.isLoading, false);
      expect(provider.tasks, isEmpty);

      await provider.loadTasks();

      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.tasks.length, sampleTasks.length);
      expect(provider.totalTasks, sampleTasks.length);
      expect(
        provider.completedTasks,
        sampleTasks.where((t) => t.isCompleted).length,
      );
      expect(
        provider.pendingTasks,
        sampleTasks.where((t) => !t.isCompleted).length,
      );
    });

    test('addTask() menambahkan tugas baru di awal daftar', () async {
      await provider.loadTasks();
      final initialCount = provider.totalTasks;

      const newTask = Task(
        id: 'new-task-1',
        title: 'Tugas Tambahan Baru',
        description: 'Deskripsi tugas baru.',
        deadline: '31 Okt 2026, 23:59 WITA',
        priority: 'Tinggi',
        isCompleted: false,
      );

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.addTask(newTask);

      expect(notified, isTrue);
      expect(provider.totalTasks, initialCount + 1);
      expect(provider.tasks.first.id, 'new-task-1');
      expect(provider.tasks.first.title, 'Tugas Tambahan Baru');
      expect(provider.errorMessage, isNull);
    });

    test('updateTask() memperbarui tugas berdasarkan ID', () async {
      await provider.loadTasks();
      final targetTask = provider.tasks.first;

      final updatedTask = targetTask.copyWith(
        title: 'Judul Tugas Diperbarui',
        isCompleted: !targetTask.isCompleted,
      );

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.updateTask(updatedTask);

      expect(notified, isTrue);
      final found = provider.tasks.firstWhere((t) => t.id == targetTask.id);
      expect(found.title, 'Judul Tugas Diperbarui');
      expect(found.isCompleted, !targetTask.isCompleted);
      expect(provider.errorMessage, isNull);
    });

    test('Tugas dengan ID yang tidak ditemukan ditangani dengan benar', () async {
      await provider.loadTasks();

      const nonExistentTask = Task(
        id: 'id-yang-pasti-tidak-ada-999',
        title: 'Tugas Hantu',
        description: 'Tidak ada di list.',
        deadline: '1 Jan 2030',
        priority: 'Rendah',
        isCompleted: false,
      );

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      provider.updateTask(nonExistentTask);

      expect(notified, isTrue);
      expect(provider.errorMessage, isNotNull);
      expect(
        provider.errorMessage,
        contains('id-yang-pasti-tidak-ada-999'),
      );
    });

    test('clearError() menghapus pesan error', () {
      const nonExistentTask = Task(
        id: 'not-found',
        title: 'Unknown',
        description: '',
        deadline: '',
        priority: 'Rendah',
        isCompleted: false,
      );

      provider.updateTask(nonExistentTask);
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });

    test('Getter daftar tugas tidak memungkinkan modifikasi langsung', () async {
      await provider.loadTasks();

      const rogueTask = Task(
        id: 'rogue',
        title: 'Modifikasi Ilegal',
        description: '',
        deadline: '',
        priority: 'Tinggi',
        isCompleted: false,
      );

      expect(() => provider.tasks.add(rogueTask), throwsUnsupportedError);
    });
  });
}
