import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/screens/archive_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_list_screen.dart';
import 'package:uts_2415051014_gedesupadma/widgets/empty_state.dart';

class MockTaskRepository extends TaskRepository {
  List<Task> storedTasks;
  bool shouldThrow;

  MockTaskRepository({
    List<Task>? initialTasks,
    this.shouldThrow = false,
  })  : storedTasks = initialTasks != null ? List.from(initialTasks) : [],
        super();

  @override
  Future<List<Task>> getTasks({bool? isArchived}) async {
    if (shouldThrow) throw Exception('Simulated database network error');
    if (isArchived != null) {
      return storedTasks.where((t) => t.isArchived == isArchived).toList();
    }
    return List.from(storedTasks);
  }

  @override
  Future<Task> updateTask(Task task) async {
    if (shouldThrow) throw Exception('Simulated update error in Supabase');
    final index = storedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      storedTasks[index] = task;
    }
    return task;
  }

  @override
  Future<Task> archiveTask(Task task) async {
    final archived = task.copyWith(isArchived: true);
    return updateTask(archived);
  }

  @override
  Future<Task> restoreTask(Task task) async {
    final restored = task.copyWith(isArchived: false);
    return updateTask(restored);
  }
}

void main() {
  group('Fitur Arsip Tugas — Model & Repository Tests', () {
    test('Task model serialization and deserialization of isArchived', () {
      final json = {
        'id': 'task-archived-1',
        'title': 'Tugas Arsip Model Test',
        'description': 'Deskripsi tugas arsip',
        'deadline': '30 Okt 2026',
        'priority': 'Tinggi',
        'is_completed': true,
        'is_archived': true,
        'user_id': 'user-123',
      };

      final task = Task.fromJson(json);
      expect(task.id, 'task-archived-1');
      expect(task.isCompleted, true);
      expect(task.isArchived, true);

      final toSupabase = task.toSupabaseMap();
      expect(toSupabase['is_completed'], true);
      expect(toSupabase['is_archived'], true);
      expect(toSupabase['user_id'], 'user-123');

      final restored = task.copyWith(isArchived: false);
      expect(restored.isArchived, false);
      expect(restored.isCompleted, true); // Status isCompleted tetap terjaga!
    });

    test('Repository archiveTask sets is_archived=true and preserves isCompleted', () async {
      const task = Task(
        id: 't-1',
        title: 'Tugas Belum Selesai',
        description: '',
        deadline: '1 Nov 2026',
        priority: 'Sedang',
        isCompleted: false,
        isArchived: false,
      );

      final mockRepo = MockTaskRepository(initialTasks: [task]);
      final archived = await mockRepo.archiveTask(task);

      expect(archived.isArchived, true);
      expect(archived.isCompleted, false);
      expect(mockRepo.storedTasks.first.isArchived, true);

      final restored = await mockRepo.restoreTask(archived);
      expect(restored.isArchived, false);
      expect(restored.isCompleted, false);
      expect(mockRepo.storedTasks.first.isArchived, false);
    });
  });

  group('Fitur Arsip Tugas — TaskProvider Tests', () {
    test('TaskProvider separates active and archived task counts and lists', () async {
      const activeTask1 = Task(
        id: 'act-1',
        title: 'Tugas Aktif 1',
        description: '',
        deadline: '1 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );
      const activeTask2 = Task(
        id: 'act-2',
        title: 'Tugas Aktif 2 Selesai',
        description: '',
        deadline: '2 Nov 2026',
        priority: 'Sedang',
        isCompleted: true,
        isArchived: false,
      );
      const archivedTask = Task(
        id: 'arc-1',
        title: 'Tugas Arsip 1',
        description: '',
        deadline: '3 Nov 2026',
        priority: 'Rendah',
        isCompleted: false,
        isArchived: true,
      );

      final mockRepo = MockTaskRepository(
        initialTasks: [activeTask1, activeTask2, archivedTask],
      );
      final provider = TaskProvider(repository: mockRepo);

      await provider.loadTasks();

      expect(provider.tasks.length, 3);
      expect(provider.totalTasks, 2); // Hanya tugas aktif (isArchived == false)
      expect(provider.completedTasks, 1);
      expect(provider.pendingTasks, 1);
      expect(provider.archivedTasksCount, 1);
      expect(provider.activeTasks.length, 2);
      expect(provider.archivedTasks.length, 1);
      expect(provider.archivedTasks.first.id, 'arc-1');
    });

    test('archiveTask and restoreTask update provider state and rethrow on failure', () async {
      const task = Task(
        id: 't-err',
        title: 'Tugas Test Error',
        description: '',
        deadline: '1 Nov 2026',
        priority: 'Sedang',
        isCompleted: false,
        isArchived: false,
      );

      final failRepo = MockTaskRepository(
        initialTasks: [task],
        shouldThrow: true,
      );
      final provider = TaskProvider(
        repository: failRepo,
        initialTasks: [task],
      );

      // State awal
      expect(provider.totalTasks, 1);
      expect(provider.archivedTasksCount, 0);

      // Attempt archive with failure
      await expectLater(
        () => provider.archiveTask(task),
        throwsA(isA<Exception>()),
      );
      expect(provider.errorMessage, isNotNull);
      // Status tugas tidak berubah (pertahankan state)
      expect(provider.tasks.first.isArchived, false);
      expect(provider.totalTasks, 1);
    });
  });

  group('Fitur Arsip Tugas — TaskListScreen & Filter Tests', () {
    testWidgets('TaskListScreen filters: Semua, Belum Selesai, Selesai only show active tasks',
        (WidgetTester tester) async {
      const activeUncompleted = Task(
        id: 'a1',
        title: 'Aktif Belum Selesai',
        description: 'Desc',
        deadline: '1 Nov 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );
      const activeCompleted = Task(
        id: 'a2',
        title: 'Aktif Sudah Selesai',
        description: 'Desc',
        deadline: '2 Nov 2026',
        priority: 'Sedang',
        isCompleted: true,
        isArchived: false,
      );
      const archivedTask = Task(
        id: 'a3',
        title: 'Tugas Yang Diarsipkan',
        description: 'Desc',
        deadline: '3 Nov 2026',
        priority: 'Rendah',
        isCompleted: false,
        isArchived: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListScreen(
            tasks: [activeUncompleted, activeCompleted, archivedTask],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter: 'Semua' -> only active tasks appear (2 tasks)
      expect(find.text('Aktif Belum Selesai'), findsOneWidget);
      expect(find.text('Aktif Sudah Selesai'), findsOneWidget);
      expect(find.text('Tugas Yang Diarsipkan'), findsNothing);

      // Filter: 'Belum Selesai' (tap chip by ValueKey)
      await tester.tap(find.byKey(const ValueKey('filter_chip_Belum Selesai')));
      await tester.pumpAndSettle();
      expect(find.text('Aktif Belum Selesai'), findsOneWidget);
      expect(find.text('Aktif Sudah Selesai'), findsNothing);
      expect(find.text('Tugas Yang Diarsipkan'), findsNothing);

      // Filter: 'Selesai' (tap chip by ValueKey)
      await tester.tap(find.byKey(const ValueKey('filter_chip_Selesai')));
      await tester.pumpAndSettle();
      expect(find.text('Aktif Belum Selesai'), findsNothing);
      expect(find.text('Aktif Sudah Selesai'), findsOneWidget);
      expect(find.text('Tugas Yang Diarsipkan'), findsNothing);

      // Filter: 'Arsip' (tap chip by ValueKey) -> shows archived task
      await tester.tap(find.byKey(const ValueKey('filter_chip_Arsip')));
      await tester.pumpAndSettle();
      expect(find.text('Aktif Belum Selesai'), findsNothing);
      expect(find.text('Aktif Sudah Selesai'), findsNothing);
      expect(find.text('Tugas Yang Diarsipkan'), findsOneWidget);
    });

    testWidgets('TaskListScreen app bar has archive button linking to ArchiveScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListScreen(tasks: []),
        ),
      );
      await tester.pumpAndSettle();

      final archiveButton = find.byTooltip('Halaman Arsip');
      expect(archiveButton, findsOneWidget);

      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      expect(find.byType(ArchiveScreen), findsOneWidget);
      expect(find.text('Arsip Tugas'), findsOneWidget);
    });
  });

  group('Fitur Arsip Tugas — ArchiveScreen Tests', () {
    testWidgets('ArchiveScreen displays archived tasks and allows restoring',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const archivedTask = Task(
        id: 'arc-restore-1',
        title: 'Tugas Kuliah Terarsip',
        description: 'Rincian tugas yang berada di arsip',
        deadline: '30 Okt 2026',
        priority: 'Tinggi',
        isCompleted: true,
        isArchived: true,
      );

      final mockRepo = MockTaskRepository(initialTasks: [archivedTask]);
      final provider = TaskProvider(repository: mockRepo);
      await provider.loadTasks();

      await tester.pumpWidget(
        ChangeNotifierProvider<TaskProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ArchiveScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas Kuliah Terarsip'), findsOneWidget);
      expect(find.text('Rincian tugas yang berada di arsip'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget); // Status pengerjaan dipertahankan!
      expect(find.text('Pulihkan'), findsOneWidget);

      // Tap Pulihkan
      await tester.tap(find.text('Pulihkan'));
      await tester.pumpAndSettle();

      // Task is now restored
      expect(mockRepo.storedTasks.first.isArchived, false);
      expect(provider.archivedTasksCount, 0);
      expect(provider.totalTasks, 1);
      expect(find.text('Belum Ada Tugas Terarsip'), findsOneWidget);
    });

    testWidgets('ArchiveScreen shows EmptyState when no archived tasks exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArchiveScreen(tasks: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Belum Ada Tugas Terarsip'), findsOneWidget);
    });
  });

  group('Fitur Arsip Tugas — TaskDetailScreen Archive Action Tests', () {
    testWidgets('TaskDetailScreen displays Arsipkan button and toggles status',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = Task(
        id: 'detail-arc-1',
        title: 'Tugas Detail Arsip Test',
        description: 'Deskripsi tugas',
        deadline: '28 Okt 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
      );

      final mockRepo = MockTaskRepository(initialTasks: [task]);
      final provider = TaskProvider(repository: mockRepo);
      await provider.loadTasks();

      await tester.pumpWidget(
        ChangeNotifierProvider<TaskProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: TaskDetailScreen(task: task),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button: Arsipkan Tugas
      final archiveButton = find.text('Arsipkan Tugas');
      expect(archiveButton, findsOneWidget);
      expect(find.text('Diarsipkan'), findsNothing);

      // Tap Arsipkan Tugas
      await tester.ensureVisible(archiveButton);
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      // Badge 'Diarsipkan' now visible
      expect(find.text('Diarsipkan'), findsOneWidget);
      // Button text becomes 'Pulihkan Tugas'
      expect(find.text('Pulihkan Tugas'), findsOneWidget);
      expect(mockRepo.storedTasks.first.isArchived, true);
    });
  });

  group('Overflow Audit across all screens with Archive Feature (320px, 390px, 700px, 1000px)', () {
    const widths = [320.0, 390.0, 700.0, 1000.0];

    for (final width in widths) {
      testWidgets('ArchiveScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const sample = Task(
          id: 'arc-resp',
          title: 'Tugas Responsif Panjang Sekali Untuk Menguji Overflow Layout',
          description: 'Deskripsi tugas panjang untuk memastikan tidak ada render flex overflow.',
          deadline: '29 Okt 2026, 23:59 WITA',
          priority: 'Tinggi',
          isCompleted: false,
          isArchived: true,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: ArchiveScreen(tasks: [sample]),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('TaskDetailScreen with archive on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        const sample = Task(
          id: 'det-resp',
          title: 'Tugas Detail Responsif Terarsip Panjang Sekali',
          description: 'Deskripsi tugas',
          deadline: '29 Okt 2026',
          priority: 'Tinggi',
          isCompleted: true,
          isArchived: true,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: TaskDetailScreen(task: sample),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
