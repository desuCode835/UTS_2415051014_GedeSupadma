import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/screens/main_navigation_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_list_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';
import 'package:uts_2415051014_gedesupadma/widgets/empty_state.dart';

class MockTaskRepositoryForInteractions extends TaskRepository {
  List<Task> storedTasks;
  int loadTasksCallCount = 0;
  int toggleCompletionCallCount = 0;
  bool shouldThrowOnToggle;
  bool shouldThrowOnLoad;

  MockTaskRepositoryForInteractions({
    List<Task>? initialTasks,
    this.shouldThrowOnToggle = false,
    this.shouldThrowOnLoad = false,
  })  : storedTasks = initialTasks != null ? List.from(initialTasks) : [],
        super();

  @override
  Future<List<Task>> getTasks({bool? isArchived}) async {
    loadTasksCallCount++;
    if (shouldThrowOnLoad) {
      throw Exception('Gagal memuat tugas dari Supabase.');
    }
    if (isArchived != null) {
      return storedTasks.where((t) => t.isArchived == isArchived).toList();
    }
    return List.from(storedTasks);
  }

  @override
  Future<Task> toggleTaskCompletion(Task task) async {
    toggleCompletionCallCount++;
    if (shouldThrowOnToggle) {
      throw Exception('Simulasi gagal update is_completed di Supabase.');
    }
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    final index = storedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      storedTasks[index] = updated;
    }
    return updated;
  }
}

void main() {
  final sampleTasksForTest = [
    const Task(
      id: 'task-1',
      title: 'Tugas Mobile Flutter',
      description: 'Mengerjakan UTS Pemrograman Mobile',
      deadline: '28 Okt 2026',
      priority: 'Tinggi',
      isCompleted: false,
      isArchived: false,
      courseCategory: 'Pemrograman Mobile - Tugas',
    ),
    const Task(
      id: 'task-2',
      title: 'Praktikum Basis Data',
      description: 'Laporan normalisasi dan SQL query',
      deadline: '29 Okt 2026',
      priority: 'Sedang',
      isCompleted: true,
      isArchived: false,
      courseCategory: 'Basis Data - Praktikum',
    ),
    const Task(
      id: 'task-3',
      title: 'Makalah Etika Profesi',
      description: 'Menulis essay standar etika IT',
      deadline: '30 Okt 2026',
      priority: 'Rendah',
      isCompleted: false,
      isArchived: false,
      courseCategory: 'Etika Profesi - Makalah',
    ),
    const Task(
      id: 'task-archived-1',
      title: 'Tugas Lama Terarsip',
      description: 'Tugas semester lalu',
      deadline: '1 Jan 2026',
      priority: 'Rendah',
      isCompleted: true,
      isArchived: true,
      courseCategory: 'Matematika Diskrit',
    ),
  ];

  group('Tahap 13 — Task Search Interactions', () {
    testWidgets('Search input filters tasks by title in real-time and case-insensitively', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskListScreen(tasks: provider.tasks),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows all 3 unarchived tasks
      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);
      expect(find.text('Praktikum Basis Data'), findsOneWidget);
      expect(find.text('Makalah Etika Profesi'), findsOneWidget);

      // Search for "flutter" with spaces around it
      final searchField = find.byKey(const ValueKey('task_search_field'));
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, '  flutter  ');
      await tester.pumpAndSettle();

      // Only "Tugas Mobile Flutter" should be visible
      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);
      expect(find.text('Praktikum Basis Data'), findsNothing);
      expect(find.text('Makalah Etika Profesi'), findsNothing);

      // Clear search restores full list
      final clearButton = find.byIcon(Icons.close_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);
      expect(find.text('Praktikum Basis Data'), findsOneWidget);
      expect(find.text('Makalah Etika Profesi'), findsOneWidget);

      // Verify original data in provider was never mutated
      expect(provider.tasks.length, 4);
    });

    testWidgets('Search with no matching query displays empty state with reset button', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskListScreen(tasks: provider.tasks),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type non-existent query
      await tester.enterText(find.byKey(const ValueKey('task_search_field')), 'Tugas Yang Tidak Pernah Ada XYZ');
      await tester.pumpAndSettle();

      // EmptyState must be shown
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Tugas Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Reset Filter & Pencarian'), findsOneWidget);

      // Tap reset button
      await tester.tap(find.text('Reset Filter & Pencarian'));
      await tester.pumpAndSettle();

      // All tasks should reappear
      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);
    });
  });

  group('Tahap 13 — Status and Priority Filter Interactions', () {
    testWidgets('Status filter tabs display correct filtered subset', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskListScreen(tasks: provider.tasks),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter: 'Belum Selesai'
      await tester.tap(find.byKey(const ValueKey('filter_chip_Belum Selesai')));
      await tester.pumpAndSettle();

      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);
      expect(find.text('Makalah Etika Profesi'), findsOneWidget);
      expect(find.text('Praktikum Basis Data'), findsNothing); // Completed task filtered out

      // Filter: 'Selesai'
      await tester.tap(find.byKey(const ValueKey('filter_chip_Selesai')));
      await tester.pumpAndSettle();

      expect(find.text('Praktikum Basis Data'), findsOneWidget);
      expect(find.text('Tugas Mobile Flutter'), findsNothing);

      // Filter: 'Arsip'
      await tester.tap(find.byKey(const ValueKey('filter_chip_Arsip')));
      await tester.pumpAndSettle();

      expect(find.text('Tugas Lama Terarsip'), findsOneWidget);
    });

    testWidgets('Priority filter works alone and in combination with status and search', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskListScreen(tasks: provider.tasks),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter by Priority 'Tinggi'
      await tester.tap(find.byKey(const ValueKey('priority_chip_Tinggi')));
      await tester.pumpAndSettle();

      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);
      expect(find.text('Praktikum Basis Data'), findsNothing);
      expect(find.text('Makalah Etika Profesi'), findsNothing);

      // Combine with search: "mobile"
      await tester.enterText(find.byKey(const ValueKey('task_search_field')), 'mobile');
      await tester.pumpAndSettle();
      expect(find.text('Tugas Mobile Flutter'), findsOneWidget);

      // Change search to "basis data" which is priority 'Sedang', while priority 'Tinggi' is active
      await tester.enterText(find.byKey(const ValueKey('task_search_field')), 'basis data');
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget); // 0 tasks match both filters!
    });
  });

  group('Tahap 13 — Task Completion Toggle & DB Sync Interactions', () {
    testWidgets('Tapping completion toggle on TaskCard calls provider and updates status', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: Consumer<TaskProvider>(
              builder: (context, prov, _) => TaskListScreen(tasks: prov.tasks),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Task 1 is uncompleted
      expect(provider.tasks.firstWhere((t) => t.id == 'task-1').isCompleted, isFalse);

      // Find tooltip/checkbox for marking complete
      final uncompletedCheckbox = find.byTooltip('Tandai selesai').first;
      await tester.tap(uncompletedCheckbox);
      await tester.pumpAndSettle();

      // Repository and Provider updated
      expect(repo.toggleCompletionCallCount, 1);
      expect(provider.tasks.firstWhere((t) => t.id == 'task-1').isCompleted, isTrue);
      expect(find.textContaining('ditandai selesai'), findsOneWidget);
    });

    testWidgets('Failure during toggle status shows error SnackBar and does NOT claim success', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(
        initialTasks: sampleTasksForTest,
        shouldThrowOnToggle: true,
      );
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: Consumer<TaskProvider>(
              builder: (context, prov, _) => TaskListScreen(tasks: prov.tasks),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap completion checkbox
      final checkbox = find.byTooltip('Tandai selesai').first;
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Task must remain uncompleted because database failed!
      expect(provider.tasks.firstWhere((t) => t.id == 'task-1').isCompleted, isFalse);

      // Error SnackBar displayed
      expect(find.textContaining('Gagal memperbarui status tugas'), findsOneWidget);
      expect(find.textContaining('ditandai selesai'), findsNothing);
    });

    testWidgets('Detail screen toggle button updates completion and preserves all task attributes', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final originalTask = sampleTasksForTest[0];
      final repo = MockTaskRepositoryForInteractions(initialTasks: [originalTask]);
      final provider = TaskProvider(repository: repo, initialTasks: [originalTask]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskDetailScreen(task: originalTask),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Tandai Selesai" button
      final completeButton = find.widgetWithText(ElevatedButton, 'Tandai Selesai');
      expect(completeButton, findsOneWidget);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();

      final updatedTask = provider.tasks.first;
      expect(updatedTask.isCompleted, isTrue);
      // All other attributes preserved
      expect(updatedTask.id, originalTask.id);
      expect(updatedTask.title, originalTask.title);
      expect(updatedTask.description, originalTask.description);
      expect(updatedTask.deadline, originalTask.deadline);
      expect(updatedTask.priority, originalTask.priority);
      expect(updatedTask.courseCategory, originalTask.courseCategory);
      expect(updatedTask.isArchived, originalTask.isArchived);
    });
  });

  group('Tahap 13 — Pull-to-Refresh & Retry Button Interactions', () {
    testWidgets('Pull-to-refresh triggers onRefresh and updates task data', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      bool refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskListScreen(
              tasks: provider.tasks,
              onRefresh: () async {
                refreshCalled = true;
                await provider.loadTasks();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag to trigger RefreshIndicator
      await tester.drag(find.byType(TaskListScreen), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
      expect(repo.loadTasksCallCount, 1);
    });

    testWidgets('Error state renders "Coba Lagi" button and retries loading when pressed', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListScreen(
            tasks: const [],
            errorMessage: 'Koneksi ke Supabase terputus. Silakan coba lagi.',
            onRetry: () {
              retryCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Tugas'), findsOneWidget);
      expect(find.textContaining('Koneksi ke Supabase terputus'), findsOneWidget);

      final retryBtn = find.byKey(const ValueKey('retry_button'));
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
    });
  });

  group('Tahap 13 — Tab Navigation Interactions', () {
    testWidgets('Switching tabs in MainNavigationScreen changes view and keeps state consistent', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForInteractions(initialTasks: sampleTasksForTest);
      final provider = TaskProvider(repository: repo, initialTasks: sampleTasksForTest);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const MainNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0 is Beranda (Home)
      expect(find.text('TaskMate'), findsOneWidget);
      expect(find.text('Halo, Gede Supadma!'), findsOneWidget);

      // Switch to Tab 1: Tugas
      await tester.tap(find.text('Tugas'));
      await tester.pumpAndSettle();

      // Header of TaskListScreen appears
      expect(find.text('Daftar Tugas'), findsOneWidget);
      expect(find.byKey(const ValueKey('task_search_field')), findsOneWidget);

      // Switch to Tab 2: Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Profil Mahasiswa'), findsOneWidget);
      expect(find.text('2415051014'), findsOneWidget);

      // Switch back to Tab 1
      await tester.tap(find.text('Tugas'));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Tugas'), findsOneWidget);
    });
  });
}
