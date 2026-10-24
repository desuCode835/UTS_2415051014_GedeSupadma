import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/main.dart';
import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/screens/main_navigation_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/add_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/edit_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_list_screen.dart';
import 'package:uts_2415051014_gedesupadma/widgets/task_card.dart';

void main() {
  group('Tahap 5 — Navigation & State Management Tests', () {
    testWidgets('NavigationBar renders 3 tabs: Beranda, Tugas, Profil',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Tugas'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('Switching tabs via NavigationBar switches displayed page',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Starts on Beranda
      expect(find.text('Ringkasan Tugas'), findsOneWidget);

      // Switch to Tugas tab
      await tester.tap(find.text('Tugas'));
      await tester.pumpAndSettle();

      expect(find.text('Daftar Tugas'), findsOneWidget);
      expect(find.byType(TaskListScreen), findsOneWidget);

      // Switch to Profil tab
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      expect(find.text('Profil Mahasiswa'), findsOneWidget);
      expect(find.text('Gede Supadma'), findsOneWidget);

      // Switch back to Beranda tab
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();

      expect(find.text('Ringkasan Tugas'), findsOneWidget);
    });

    testWidgets('TaskListScreen navigation to detail passes selected task',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TaskListScreen(
            tasks: const [
              TaskItem(
                id: 'custom-1',
                title: 'Tugas Khusus Mobile',
                course: 'Pemrograman Mobile',
                deadline: '29 Okt 2026, 12:00 WITA',
                priority: 'Tinggi',
                status: 'Belum Selesai',
                description: 'Deskripsi tugas khusus untuk pengujian navigasi.',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas Khusus Mobile'), findsOneWidget);

      // Tap task card
      await tester.tap(find.byType(TaskCard).first);
      await tester.pumpAndSettle();

      // Expect detail screen displaying the exact passed task
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.text('Tugas Khusus Mobile'), findsOneWidget);
      expect(find.text('29 Okt 2026, 12:00 WITA'), findsOneWidget);
      expect(
        find.text('Deskripsi tugas khusus untuk pengujian navigasi.'),
        findsOneWidget,
      );
    });

    testWidgets('Detail screen opens EditTaskScreen with prepopulated task',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const task = TaskItem(
        id: 'edit-test-1',
        title: 'Tugas Lama Sebelum Diedit',
        course: 'Jaringan Komputer',
        deadline: '1 Nov 2026, 10:00 WITA',
        priority: 'Sedang',
        status: 'Belum Selesai',
        description: 'Deskripsi lama.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskDetailScreen(task: task),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit button via Tooltip
      await tester.tap(find.byTooltip('Edit Tugas'));
      await tester.pumpAndSettle();

      expect(find.byType(EditTaskScreen), findsOneWidget);
      expect(find.text('Tugas Lama Sebelum Diedit'), findsOneWidget);
      expect(find.text('Jaringan Komputer'), findsOneWidget);
      expect(find.text('1 Nov 2026, 10:00 WITA'), findsOneWidget);
      expect(find.text('Deskripsi lama.'), findsOneWidget);
    });

    testWidgets('Saving edited task updates task with same ID and reflected in detail',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      TaskItem? updatedResult;
      const initialTask = TaskItem(
        id: 'unique-id-99',
        title: 'Judul Asli',
        course: 'Sistem Operasi',
        deadline: '2 Nov 2026, 18:00 WITA',
        priority: 'Sedang',
        status: 'Belum Selesai',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TaskDetailScreen(
            task: initialTask,
            onTaskUpdated: (task) {
              updatedResult = task;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Edit screen
      await tester.tap(find.byTooltip('Edit Tugas'));
      await tester.pumpAndSettle();

      // Enter new title
      final titleFinder = find.widgetWithText(TextField, 'Judul Asli');
      await tester.enterText(titleFinder, 'Judul Baru yang Diedit');
      await tester.pumpAndSettle();

      // Tap Simpan Perubahan
      final saveButton = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Back on detail screen
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.text('Judul Baru yang Diedit'), findsOneWidget);

      expect(updatedResult, isNotNull);
      expect(updatedResult!.id, 'unique-id-99');
      expect(updatedResult!.title, 'Judul Baru yang Diedit');
    });

    testWidgets('AddTaskScreen validates required title and deadline',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: AddTaskScreen()),
      );
      await tester.pumpAndSettle();

      // Attempt to save empty form
      final saveButton = find.text('Simpan Tugas Baru');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas wajib diisi!'), findsOneWidget);

      // Enter title only, but no deadline
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Tugas Tanpa Deadline');
      await tester.pumpAndSettle();

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Tenggat waktu (deadline) wajib diisi!'), findsOneWidget);
    });

    testWidgets('Canceling AddTaskScreen does not add task to MainNavigationScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Initial task count in dashboard: 5
      expect(find.text('5'), findsWidgets);

      // Open AddTaskScreen via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.byType(AddTaskScreen), findsOneWidget);

      // Cancel / press back
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Still 5 tasks
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.text('5'), findsWidgets);
    });
  });
}
