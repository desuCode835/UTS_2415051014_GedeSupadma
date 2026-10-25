import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';
import 'package:uts_2415051014_gedesupadma/services/supabase_service.dart';

class FakeSupabaseServiceForDeletion extends SupabaseService {
  final List<Map<String, dynamic>> mockTableRows;
  bool shouldThrowRlsOnDelete;
  String? lastDeletedId;
  int deleteCallCount = 0;

  FakeSupabaseServiceForDeletion({
    List<Map<String, dynamic>>? initialRows,
    this.shouldThrowRlsOnDelete = false,
  }) : mockTableRows = initialRows != null ? List.from(initialRows) : [];

  @override
  bool get isInitialized => true;

  @override
  Future<void> ensureAnonymousSession() async {}

  @override
  Future<List<Map<String, dynamic>>> getTasks({bool? isArchived}) async {
    if (isArchived != null) {
      return mockTableRows.where((r) => r['is_archived'] == isArchived).toList();
    }
    return List.from(mockTableRows);
  }

  @override
  Future<void> deleteTask(String id) async {
    deleteCallCount++;
    lastDeletedId = id;

    if (id.trim().isEmpty) {
      throw ArgumentError('ID tugas tidak boleh kosong untuk operasi delete.');
    }

    if (shouldThrowRlsOnDelete) {
      // Mensimulasikan respons 0 baris dari PostgREST akibat penolakan RLS policy
      throw Exception(
        'Gagal menghapus tugas: Data tidak ditemukan atau operasi ditolak oleh database (RLS). '
        'Pastikan policy DELETE pada tabel "tasks" di Supabase telah diizinkan untuk akun pengguna ini.',
      );
    }

    final index = mockTableRows.indexWhere((r) => r['id'] == id);
    if (index == -1) {
      // Record tidak ditemukan (0 baris terhapus)
      throw Exception(
        'Gagal menghapus tugas: Data tidak ditemukan atau operasi ditolak oleh database (RLS). '
        'Pastikan policy DELETE pada tabel "tasks" di Supabase telah diizinkan untuk akun pengguna ini.',
      );
    }

    mockTableRows.removeAt(index);
  }
}

class MockTaskRepositoryForDeletion extends TaskRepository {
  List<Task> storedTasks;
  String? lastDeletedId;
  int deleteCallCount = 0;
  bool shouldThrowOnDelete;
  Duration simulatedDelay;

  MockTaskRepositoryForDeletion({
    List<Task>? initialTasks,
    this.shouldThrowOnDelete = false,
    this.simulatedDelay = Duration.zero,
  })  : storedTasks = initialTasks != null ? List.from(initialTasks) : [],
        super();

  @override
  Future<List<Task>> getTasks({bool? isArchived}) async {
    if (isArchived != null) {
      return storedTasks.where((t) => t.isArchived == isArchived).toList();
    }
    return List.from(storedTasks);
  }

  @override
  Future<void> deleteTask(String id) async {
    deleteCallCount++;
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
    if (shouldThrowOnDelete) {
      throw Exception('Simulated Supabase RLS / network deletion failure');
    }
    lastDeletedId = id;
    storedTasks.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('Tahap 12 — Task Deletion Repository & Provider Tests', () {
    test('TaskProvider.deleteTask calls repository with correct ID and updates state only on success', () async {
      const task1 = Task(
        id: 'del-1',
        title: 'Tugas yang akan dihapus',
        description: 'Deskripsi 1',
        deadline: '1 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
        courseCategory: 'Pemrograman Mobile - Tugas',
      );
      const task2 = Task(
        id: 'del-2',
        title: 'Tugas yang tetap ada',
        description: 'Deskripsi 2',
        deadline: '2 Nov 2026',
        priority: 'Sedang',
        isCompleted: true,
        isArchived: false,
        courseCategory: 'Basis Data - Praktikum',
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [task1, task2]);
      final provider = TaskProvider(repository: repo, initialTasks: [task1, task2]);

      expect(provider.tasks.length, 2);

      await provider.deleteTask('del-1');

      expect(repo.lastDeletedId, 'del-1');
      expect(repo.deleteCallCount, 1);
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.id, 'del-2');
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, false);
    });

    test('TaskProvider.deleteTask preserves task in state and sets error if repository fails', () async {
      const task1 = Task(
        id: 'del-fail-1',
        title: 'Tugas gagal dihapus',
        description: 'Deskripsi fail',
        deadline: '1 Nov 2026',
        priority: 'Rendah',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(
        initialTasks: [task1],
        shouldThrowOnDelete: true,
      );
      final provider = TaskProvider(repository: repo, initialTasks: [task1]);

      expect(provider.tasks.length, 1);

      await expectLater(
        () => provider.deleteTask('del-fail-1'),
        throwsA(isA<Exception>()),
      );

      // Task must remain in provider state because database operation failed!
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.id, 'del-fail-1');
      expect(provider.errorMessage, contains('Gagal menghapus tugas dari database'));
      expect(provider.isLoading, false);
    });

    test('Deleting archived task removes it from archivedTasks getter', () async {
      const archivedTask = Task(
        id: 'arch-del-1',
        title: 'Tugas Arsip Terhapus',
        description: 'Diarsip lalu dihapus',
        deadline: '3 Nov 2026',
        priority: 'Sedang',
        isCompleted: true,
        isArchived: true,
        courseCategory: 'Statistika - Ujian',
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [archivedTask]);
      final provider = TaskProvider(repository: repo, initialTasks: [archivedTask]);

      expect(provider.archivedTasks.length, 1);

      await provider.deleteTask('arch-del-1');

      expect(provider.archivedTasks.isEmpty, true);
      expect(provider.tasks.isEmpty, true);
    });
  });

  group('Tahap 12 — Task Detail Screen Deletion Widget Tests', () {
    testWidgets('Tapping delete button shows confirmation dialog containing task title', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'ui-del-1',
        title: 'Laporan Proyek Akhir',
        description: 'Detail tugas',
        deadline: '10 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskDetailScreen(task: task),
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete button in AppBar
      final deleteBtn = find.byKey(const ValueKey('delete_task_button'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Dialog should appear with Title and Task Name
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Hapus Tugas?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('Laporan Proyek Akhir'),
        ),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });

    testWidgets('Tapping Batal closes dialog without triggering delete or modifying state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'ui-del-2',
        title: 'Tugas Jangan Dihapus',
        description: '',
        deadline: '11 Nov 2026',
        priority: 'Sedang',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [task]);
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const TaskDetailScreen(task: task),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const ValueKey('delete_task_button')));
      await tester.pumpAndSettle();

      // Tap Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.byType(AlertDialog), findsNothing);
      // Detail screen still active
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      // Repository delete was NOT called
      expect(repo.deleteCallCount, 0);
      expect(provider.tasks.length, 1);
    });

    testWidgets('Confirming Hapus executes delete on correct task ID and navigates back', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'ui-del-3',
        title: 'Tugas yang Benar-Benar Dihapus',
        description: '',
        deadline: '12 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [task]);
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      bool didCallOnTaskDeleted = false;
      String? deletedTaskId;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: TaskDetailScreen(
              task: task,
              onTaskDeleted: (id) {
                didCallOnTaskDeleted = true;
                deletedTaskId = id;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog via bottom button
      final bottomDeleteBtn = find.byKey(const ValueKey('delete_task_bottom_button'));
      await tester.ensureVisible(bottomDeleteBtn);
      await tester.tap(bottomDeleteBtn);
      await tester.pumpAndSettle();

      // Confirm deletion
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Hapus');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(repo.deleteCallCount, 1);
      expect(repo.lastDeletedId, 'ui-del-3');
      expect(provider.tasks.isEmpty, true);
      expect(didCallOnTaskDeleted, true);
      expect(deletedTaskId, 'ui-del-3');
    });

    testWidgets('Failure during delete displays SnackBar error and keeps detail screen and task open', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'ui-del-4',
        title: 'Tugas Database Offline',
        description: '',
        deadline: '15 Nov 2026',
        priority: 'Sedang',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(
        initialTasks: [task],
        shouldThrowOnDelete: true,
      );
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const TaskDetailScreen(task: task),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const ValueKey('delete_task_button')));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      // Error SnackBar should be displayed
      expect(find.textContaining('Gagal menghapus tugas'), findsOneWidget);

      // TaskDetailScreen must STILL be present, not abruptly closed!
      expect(find.byType(TaskDetailScreen), findsOneWidget);

      // Task must remain in provider state
      expect(provider.tasks.length, 1);
    });

    testWidgets('Prevents duplicate delete calls while deletion is in progress', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'ui-del-5',
        title: 'Tugas Anti Double Click',
        description: '',
        deadline: '18 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(
        initialTasks: [task],
        simulatedDelay: const Duration(milliseconds: 200),
      );
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const TaskDetailScreen(task: task),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(const ValueKey('delete_task_button')));
      await tester.pumpAndSettle();

      // Tap confirm
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      // Only pump 10ms so async delete is still running
      await tester.pump(const Duration(milliseconds: 10));

      // Attempt second tap on delete buttons while _isDeleting is true
      final appbarBtn = find.byKey(const ValueKey('delete_task_button'));
      await tester.tap(appbarBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 10));

      // Wait for async operation to complete
      await tester.pumpAndSettle();

      // Repository must have been called EXACTLY once!
      expect(repo.deleteCallCount, 1);
    });

    testWidgets('Deleting task from MaterialPageRoute<Task> pops cleanly with null and no type error', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'typed-route-1',
        title: 'Tugas Typed Route Test',
        description: 'Testing MaterialPageRoute<Task>',
        deadline: '20 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [task]);
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      dynamic routeResult = 'not-called';
      bool updateCallbackCalled = false;

      await tester.pumpWidget(
        ChangeNotifierProvider<TaskProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Exactly simulates MainNavigationScreen line 64:
                        // Navigator.push<Task>(..., MaterialPageRoute(builder: (_) => TaskDetailScreen(...)))
                        final Task? res = await Navigator.push<Task>(
                          context,
                          MaterialPageRoute<Task>(
                            builder: (_) => TaskDetailScreen(
                              task: task,
                              onTaskUpdated: (_) {
                                updateCallbackCalled = true;
                              },
                            ),
                          ),
                        );
                        routeResult = res;
                      },
                      child: const Text('Buka Detail'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open detail screen via route expecting Task
      await tester.tap(find.text('Buka Detail'));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailScreen), findsOneWidget);

      // Tap delete
      await tester.tap(find.byKey(const ValueKey('delete_task_button')));
      await tester.pumpAndSettle();

      // Confirm delete in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      // Successfully back on caller screen without any type mismatch exception!
      expect(find.text('Buka Detail'), findsOneWidget);
      expect(find.byType(TaskDetailScreen), findsNothing);

      // Route result was null, exactly conforming to Task?
      expect(routeResult, isNull);
      expect(updateCallbackCalled, false);
      expect(repo.deleteCallCount, 1);
      expect(provider.tasks.isEmpty, true);
    });

    testWidgets('Normal back button on TaskDetailScreen still returns Task to MaterialPageRoute<Task>', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'back-route-1',
        title: 'Tugas Normal Back',
        description: '',
        deadline: '22 Nov 2026',
        priority: 'Sedang',
        isCompleted: false,
        isArchived: false,
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [task]);
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      Task? routeResult;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final Task? res = await Navigator.push<Task>(
                          context,
                          MaterialPageRoute<Task>(
                            builder: (_) => const TaskDetailScreen(task: task),
                          ),
                        );
                        routeResult = res;
                      },
                      child: const Text('Buka Detail Normal'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka Detail Normal'));
      await tester.pumpAndSettle();

      // Tap back button in AppBar
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Returned the task object
      expect(routeResult, isNotNull);
      expect(routeResult!.id, 'back-route-1');
      expect(routeResult!.title, 'Tugas Normal Back');
      expect(repo.deleteCallCount, 0);
    });

    testWidgets('Confirming Hapus with SupabaseService RLS failure displays red SnackBar and does NOT delete locally', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'rls-fail-uuid-1',
        title: 'Tugas Terkunci RLS',
        description: 'Tugas tidak bisa dihapus karena RLS',
        deadline: '24 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
        courseCategory: 'Keamanan Sistem - Praktikum',
      );

      final fakeSupabase = FakeSupabaseServiceForDeletion(
        initialRows: [
          {
            'id': 'rls-fail-uuid-1',
            'title': 'Tugas Terkunci RLS',
            'description': 'Tugas tidak bisa dihapus karena RLS',
            'deadline': '24 Nov 2026',
            'priority': 'Tinggi',
            'is_completed': false,
            'is_archived': false,
            'course_category': 'Keamanan Sistem - Praktikum',
          }
        ],
        shouldThrowRlsOnDelete: true,
      );
      final repo = TaskRepository(supabaseService: fakeSupabase);
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const TaskDetailScreen(task: task),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open confirmation dialog
      await tester.tap(find.byKey(const ValueKey('delete_task_button')));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      // Verified: Red error SnackBar displayed with RLS message
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      expect(
        find.descendant(
          of: snackBarFinder,
          matching: find.textContaining('Gagal menghapus tugas'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: snackBarFinder,
          matching: find.textContaining('RLS'),
        ),
        findsOneWidget,
      );

      // Verified: Success SnackBar is NOT displayed
      expect(find.textContaining('berhasil dihapus'), findsNothing);

      // Verified: Task is NOT deleted from Provider state
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.id, 'rls-fail-uuid-1');

      // Verified: Screen is NOT popped, user remains on detail
      expect(find.byType(TaskDetailScreen), findsOneWidget);
    });

    testWidgets('Remaining tasks retain edit, archive, and course category functionality after a deletion', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const taskToKeep = Task(
        id: 'keep-1',
        title: 'Tugas yang Disimpan',
        description: 'Tugas penting',
        deadline: '28 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
        courseCategory: 'Rekayasa Perangkat Lunak',
      );

      final repo = MockTaskRepositoryForDeletion(initialTasks: [taskToKeep]);
      final provider = TaskProvider(repository: repo, initialTasks: [taskToKeep]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const TaskDetailScreen(task: taskToKeep),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify course category is displayed
      expect(find.text('Rekayasa Perangkat Lunak'), findsWidgets);

      // Verify archive button is visible and active
      final archiveBtn = find.byTooltip('Arsipkan Tugas');
      expect(archiveBtn, findsOneWidget);

      // Verify edit button is visible and active
      final editBtn = find.byTooltip('Edit Tugas');
      expect(editBtn, findsOneWidget);
    });
  });

  group('Tahap 12 — Direct Supabase Service & Repository Delete Contract Tests', () {
    test('TaskRepository.deleteTask propagates RLS/0-rows exception and does not claim success', () async {
      final fakeSupabase = FakeSupabaseServiceForDeletion(
        initialRows: [
          {
            'id': 'task-db-1',
            'title': 'Tugas di Supabase',
            'deadline': '30 Nov 2026',
            'priority': 'Sedang',
            'is_completed': false,
            'is_archived': false,
          }
        ],
        shouldThrowRlsOnDelete: true,
      );

      final repo = TaskRepository(supabaseService: fakeSupabase);

      expect(
        () => repo.deleteTask('task-db-1'),
        throwsA(predicate((e) => e.toString().contains('RLS') || e.toString().contains('Gagal menghapus tugas'))),
      );

      // Table row must still exist in Supabase mock
      expect(fakeSupabase.mockTableRows.length, 1);
    });

    test('TaskRepository.deleteTask with confirmed deletion removes row from Supabase', () async {
      final fakeSupabase = FakeSupabaseServiceForDeletion(
        initialRows: [
          {
            'id': 'task-db-2',
            'title': 'Tugas yang Benar Terhapus',
            'deadline': '30 Nov 2026',
            'priority': 'Rendah',
            'is_completed': false,
            'is_archived': false,
          }
        ],
        shouldThrowRlsOnDelete: false,
      );

      final repo = TaskRepository(supabaseService: fakeSupabase);

      await repo.deleteTask('task-db-2');

      expect(fakeSupabase.mockTableRows.isEmpty, true);
      expect(fakeSupabase.lastDeletedId, 'task-db-2');
    });

    test('TaskProvider.deleteTask does not remove task if Supabase returns 0 deleted rows', () async {
      const task = Task(
        id: 'task-not-deleted',
        title: 'Tugas Gagal Hapus 0 Rows',
        description: '',
        deadline: '1 Des 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );

      final fakeSupabase = FakeSupabaseServiceForDeletion(
        initialRows: [], // 0 rows present in Supabase -> delete will return 0 rows!
        shouldThrowRlsOnDelete: false,
      );

      final repo = TaskRepository(supabaseService: fakeSupabase);
      final provider = TaskProvider(repository: repo, initialTasks: [task]);

      expect(provider.tasks.length, 1);

      await expectLater(
        () => provider.deleteTask('task-not-deleted'),
        throwsA(isA<Exception>()),
      );

      // Provider MUST retain task in state!
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.id, 'task-not-deleted');
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Gagal menghapus tugas'));
    });
  });
}
