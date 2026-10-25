import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/screens/add_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/edit_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_list_screen.dart';
import 'package:uts_2415051014_gedesupadma/widgets/task_card.dart';

class MockTaskRepositoryForCourse extends TaskRepository {
  List<Task> storedTasks;
  Map<String, dynamic>? lastCreatedPayload;
  Map<String, dynamic>? lastUpdatedPayload;

  MockTaskRepositoryForCourse({List<Task>? initialTasks})
      : storedTasks = initialTasks != null ? List.from(initialTasks) : [],
        super();

  @override
  Future<List<Task>> getTasks({bool? isArchived}) async {
    if (isArchived != null) {
      return storedTasks.where((t) => t.isArchived == isArchived).toList();
    }
    return List.from(storedTasks);
  }

  @override
  Future<Task> createTask({
    required String title,
    String description = '',
    required String deadline,
    required String priority,
    bool isCompleted = false,
    bool isArchived = false,
    String? courseCategory,
  }) async {
    lastCreatedPayload = {
      'title': title,
      'description': description,
      'deadline': deadline,
      'priority': priority,
      'is_completed': isCompleted,
      'is_archived': isArchived,
      'course_category': courseCategory,
    };

    final newTask = Task(
      id: 'task-test-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      isCompleted: isCompleted,
      isArchived: isArchived,
      courseCategory: courseCategory,
    );
    storedTasks.insert(0, newTask);
    return newTask;
  }

  @override
  Future<Task> updateTask(Task task) async {
    lastUpdatedPayload = task.toSupabaseMap();
    final index = storedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      storedTasks[index] = task;
    }
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    storedTasks.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('Course Category — Task Model & Serializer Tests', () {
    test('Task model correctly parses course_category from Supabase snake_case JSON', () {
      final json = {
        'id': 'task-c1',
        'title': 'Latihan Pemrograman Mobile',
        'description': 'Mengerjakan modul 5',
        'deadline': '30 Okt 2026',
        'priority': 'Tinggi',
        'is_completed': false,
        'is_archived': false,
        'course_category': 'Pemrograman Mobile - Tugas',
        'user_id': 'user-uuid-1',
      };

      final task = Task.fromJson(json);
      expect(task.id, 'task-c1');
      expect(task.courseCategory, 'Pemrograman Mobile - Tugas');
      expect(task.displayCourseCategory, 'Pemrograman Mobile - Tugas');
      expect(task.isCompleted, false);
      expect(task.isArchived, false);
      expect(task.userId, 'user-uuid-1');
    });

    test('Task model provides fallback "Belum ditentukan" when course_category is null or blank', () {
      final jsonWithNull = {
        'id': 'task-c2',
        'title': 'Tugas Tanpa Kategori',
        'deadline': '31 Okt 2026',
        'priority': 'Sedang',
        'is_completed': true,
        'is_archived': false,
        'course_category': null,
      };

      final taskNull = Task.fromJson(jsonWithNull);
      expect(taskNull.courseCategory, isNull);
      expect(taskNull.displayCourseCategory, 'Belum ditentukan');

      final taskEmpty = taskNull.copyWith(courseCategory: '   ');
      expect(taskEmpty.displayCourseCategory, 'Belum ditentukan');
    });

    test('Task toSupabaseMap writes course_category accurately and preserves all attributes', () {
      const task = Task(
        id: 'task-c3',
        title: 'Proyek Basis Data',
        description: 'Normalisasi dan DDL',
        deadline: '15 Nov 2026',
        priority: 'Tinggi',
        isCompleted: true,
        isArchived: true,
        courseCategory: 'Basis Data - Praktikum',
        userId: 'student-99',
      );

      final map = task.toSupabaseMap();
      expect(map['title'], 'Proyek Basis Data');
      expect(map['description'], 'Normalisasi dan DDL');
      expect(map['deadline'], '15 Nov 2026');
      expect(map['priority'], 'Tinggi');
      expect(map['is_completed'], true);
      expect(map['is_archived'], true);
      expect(map['course_category'], 'Basis Data - Praktikum');
      expect(map['user_id'], 'student-99');
    });

    test('Task copyWith updates courseCategory while preserving is_completed, is_archived, and user_id', () {
      const original = Task(
        id: 'task-c4',
        title: 'Tugas Statistika',
        description: 'Uji hipotesis',
        deadline: '20 Nov 2026',
        priority: 'Sedang',
        isCompleted: true,
        isArchived: false,
        courseCategory: 'Statistika - Ujian',
        userId: 'student-77',
      );

      final updated = original.copyWith(
        courseCategory: 'Statistika - Proyek',
      );

      expect(updated.courseCategory, 'Statistika - Proyek');
      expect(updated.isCompleted, true);
      expect(updated.isArchived, false);
      expect(updated.userId, 'student-77');
      expect(updated.title, 'Tugas Statistika');
    });
  });

  group('Course Category — Repository & Provider Integration Tests', () {
    test('TaskRepository creates task with course_category in payload', () async {
      final repo = MockTaskRepositoryForCourse();
      final provider = TaskProvider(repository: repo);

      final task = await provider.createTask(
        title: 'Tugas Akhir Semester',
        description: 'Pengembangan Aplikasi',
        deadline: '10 Des 2026',
        priority: 'Tinggi',
        courseCategory: 'Pemrograman Mobile - Proyek',
      );

      expect(task.courseCategory, 'Pemrograman Mobile - Proyek');
      expect(repo.lastCreatedPayload?['course_category'], 'Pemrograman Mobile - Proyek');
      expect(provider.tasks.first.courseCategory, 'Pemrograman Mobile - Proyek');
    });

    test('TaskProvider editTask updates courseCategory in repository without resetting other flags', () async {
      const initialTask = Task(
        id: 'task-update-1',
        title: 'Latihan SQL',
        description: 'Query Join',
        deadline: '12 Des 2026',
        priority: 'Sedang',
        isCompleted: true,
        isArchived: false,
        courseCategory: 'Basis Data - Praktikum',
      );

      final repo = MockTaskRepositoryForCourse(initialTasks: [initialTask]);
      final provider = TaskProvider(repository: repo, initialTasks: [initialTask]);

      final updatedTask = initialTask.copyWith(
        courseCategory: 'Basis Data - Ujian',
      );

      await provider.editTask(updatedTask);

      expect(repo.lastUpdatedPayload?['course_category'], 'Basis Data - Ujian');
      expect(repo.lastUpdatedPayload?['is_completed'], true);
      expect(repo.lastUpdatedPayload?['is_archived'], false);
      expect(provider.tasks.first.courseCategory, 'Basis Data - Ujian');
    });
  });

  group('Course Category — UI & Screen Integration Tests', () {
    testWidgets('AddTaskScreen saves courseCategory into provider on submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockTaskRepositoryForCourse();
      final provider = TaskProvider(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const AddTaskScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Analisis Algoritma');
      await tester.pumpAndSettle();

      // Tap on suggestion pill '+ Pemrograman Mobile - Tugas'
      final pillFinder = find.text('+ Pemrograman Mobile - Tugas');
      expect(pillFinder, findsOneWidget);
      await tester.ensureVisible(pillFinder);
      await tester.tap(pillFinder);
      await tester.pumpAndSettle();

      // Select deadline via DatePicker & TimePicker
      await tester.tap(
        find.byIcon(Icons.edit_calendar_rounded),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('LANJUT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SIMPAN'));
      await tester.pumpAndSettle();

      // Tap Simpan Tugas Baru button
      final saveButton = find.text('Simpan Tugas Baru');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.title, 'Analisis Algoritma');
      expect(provider.tasks.first.courseCategory, 'Pemrograman Mobile - Tugas');
    });

    testWidgets('EditTaskScreen pre-populates existing courseCategory and allows updating it', (tester) async {
      const existingTask = Task(
        id: 'edit-c1',
        title: 'Praktikum Jaringan Komputer',
        description: 'Konfigurasi Router',
        deadline: '1 Des 2026, 23:59 WITA',
        priority: 'Tinggi',
        isCompleted: true,
        isArchived: false,
        courseCategory: 'Basis Data - Praktikum',
      );

      final repo = MockTaskRepositoryForCourse(initialTasks: [existingTask]);
      final provider = TaskProvider(repository: repo, initialTasks: [existingTask]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: provider,
            child: const EditTaskScreen(task: existingTask),
          ),
        ),
      );

      // Verify pre-populated courseCategory
      expect(find.text('Basis Data - Praktikum'), findsAtLeastNWidgets(1));

      // Click on another suggestion pill: '+ Pemrograman Mobile - Proyek'
      final newPill = find.text('+ Pemrograman Mobile - Proyek');
      await tester.ensureVisible(newPill);
      await tester.tap(newPill);
      await tester.pump();

      // Submit changes
      final saveButton = find.widgetWithText(ElevatedButton, 'Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(provider.tasks.first.courseCategory, 'Pemrograman Mobile - Proyek');
      // Status isCompleted must still be true!
      expect(provider.tasks.first.isCompleted, true);
    });

    testWidgets('TaskDetailScreen displays fallback "Belum ditentukan" when courseCategory is null', (tester) async {
      const taskWithoutCourse = Task(
        id: 'detail-c1',
        title: 'Tugas Belum Ada Kategori',
        description: 'Deskripsi tugas',
        deadline: '5 Des 2026',
        priority: 'Sedang',
        isCompleted: false,
        isArchived: false,
        courseCategory: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskDetailScreen(task: taskWithoutCourse),
        ),
      );

      // Must find 'Mata Kuliah / Kategori' section and 'Belum ditentukan' fallback text
      expect(find.text('Mata Kuliah / Kategori'), findsOneWidget);
      expect(find.text('Belum ditentukan'), findsOneWidget);
    });

    testWidgets('TaskDetailScreen displays courseCategory when set in both badges and info section', (tester) async {
      const taskWithCourse = Task(
        id: 'detail-c2',
        title: 'Ujian Akhir Statistika',
        description: 'Bab 1 sampai 7',
        deadline: '8 Des 2026',
        priority: 'Tinggi',
        isCompleted: false,
        isArchived: false,
        courseCategory: 'Statistika - Ujian',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskDetailScreen(task: taskWithCourse),
        ),
      );

      expect(find.text('Mata Kuliah / Kategori'), findsOneWidget);
      // 'Statistika - Ujian' appears in the top badge and in the info section
      expect(find.text('Statistika - Ujian'), findsAtLeastNWidgets(2));
    });

    testWidgets('TaskListScreen filters tasks by courseCategory keyword in search', (tester) async {
      final tasks = [
        const Task(
          id: 't-1',
          title: 'Tugas Satu',
          description: '',
          deadline: '1 Des 2026',
          priority: 'Sedang',
          isCompleted: false,
          courseCategory: 'Pemrograman Mobile - Tugas',
        ),
        const Task(
          id: 't-2',
          title: 'Tugas Dua',
          description: '',
          deadline: '2 Des 2026',
          priority: 'Rendah',
          isCompleted: false,
          courseCategory: 'Basis Data - Praktikum',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListScreen(tasks: tasks),
        ),
      );

      // Both initially visible
      expect(find.text('Tugas Satu'), findsOneWidget);
      expect(find.text('Tugas Dua'), findsOneWidget);

      // Search by course category
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Basis Data');
      await tester.pump();

      expect(find.text('Tugas Satu'), findsNothing);
      expect(find.text('Tugas Dua'), findsOneWidget);
    });

    testWidgets('TaskCard renders course badge properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TaskCard(
              title: 'Tugas Card Test',
              course: 'Pemrograman Mobile - Proyek',
              deadline: '10 Des 2026',
              priority: 'Tinggi',
              status: 'Belum Selesai',
            ),
          ),
        ),
      );

      expect(find.text('Pemrograman Mobile - Proyek'), findsOneWidget);
    });
  });
}
