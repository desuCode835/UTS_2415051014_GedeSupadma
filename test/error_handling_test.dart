import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:uts_2415051014_gedesupadma/models/task.dart';
import 'package:uts_2415051014_gedesupadma/models/quote.dart';
import 'package:uts_2415051014_gedesupadma/models/user_profile.dart';
import 'package:uts_2415051014_gedesupadma/services/api_service.dart';
import 'package:uts_2415051014_gedesupadma/repositories/task_repository.dart';
import 'package:uts_2415051014_gedesupadma/repositories/quote_repository.dart';
import 'package:uts_2415051014_gedesupadma/repositories/profile_repository.dart';
import 'package:uts_2415051014_gedesupadma/providers/task_provider.dart';
import 'package:uts_2415051014_gedesupadma/providers/quote_provider.dart';
import 'package:uts_2415051014_gedesupadma/providers/profile_provider.dart';
import 'package:uts_2415051014_gedesupadma/screens/home_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_list_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/archive_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/add_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/edit_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';

// ==========================================
// MOCK & FAKE TEST IMPLEMENTATIONS
// ==========================================

class TestHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  TestHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class FakeErrorQuoteRepository extends QuoteRepository {
  Quote? quoteToReturn;
  Exception? exceptionToThrow;
  int callCount = 0;

  FakeErrorQuoteRepository({this.quoteToReturn, this.exceptionToThrow});

  @override
  Future<Quote> getRandomQuote() async {
    callCount++;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return quoteToReturn ??
        const Quote(
          id: 1,
          quote: 'Kutipan pengujian error handling sukses.',
          author: 'Penulis Uji',
        );
  }
}

class FakeErrorTaskRepository extends TaskRepository {
  List<Task>? tasksToReturn;
  final Exception? getTasksException;
  final Exception? createException;
  final Exception? updateException;
  final Exception? deleteException;

  int getTasksCallCount = 0;
  int createTaskCallCount = 0;
  int updateTaskCallCount = 0;
  int deleteTaskCallCount = 0;

  FakeErrorTaskRepository({
    List<Task>? initialTasks,
    List<Task>? tasksToReturn,
    this.getTasksException,
    this.createException,
    this.updateException,
    this.deleteException,
  }) : tasksToReturn = initialTasks != null
            ? List.from(initialTasks)
            : tasksToReturn;

  @override
  Future<List<Task>> getTasks({bool? isArchived}) async {
    getTasksCallCount++;
    if (getTasksException != null) throw getTasksException!;
    if (isArchived != null && tasksToReturn != null) {
      return tasksToReturn!.where((t) => t.isArchived == isArchived).toList();
    }
    return tasksToReturn != null ? List.from(tasksToReturn!) : [];
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
    createTaskCallCount++;
    if (createException != null) throw createException!;
    final newTask = Task(
      id: 'created-task-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      deadline: deadline,
      priority: priority,
      isCompleted: isCompleted,
      isArchived: isArchived,
      courseCategory: courseCategory,
    );
    tasksToReturn?.insert(0, newTask);
    return newTask;
  }

  @override
  Future<Task> updateTask(Task task) async {
    updateTaskCallCount++;
    if (updateException != null) throw updateException!;
    if (tasksToReturn != null) {
      final index = tasksToReturn!.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        tasksToReturn![index] = task;
      }
    }
    return task;
  }

  @override
  Future<Task> toggleTaskCompletion(Task task) async {
    return updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  @override
  Future<Task> toggleTaskArchive(Task task) async {
    return updateTask(task.copyWith(isArchived: !task.isArchived));
  }

  @override
  Future<Task> archiveTask(Task task) async {
    return updateTask(task.copyWith(isArchived: true));
  }

  @override
  Future<Task> restoreTask(Task task) async {
    return updateTask(task.copyWith(isArchived: false));
  }

  @override
  Future<void> deleteTask(String id) async {
    deleteTaskCallCount++;
    if (deleteException != null) throw deleteException!;
    tasksToReturn?.removeWhere((t) => t.id == id);
  }
}

class FakeErrorProfileRepository extends ProfileRepository {
  final Exception? updateException;
  final Exception? getException;
  int updateCallCount = 0;

  FakeErrorProfileRepository({this.updateException, this.getException});

  @override
  Future<UserProfile> getProfile({String? userId}) async {
    if (getException != null) throw getException!;
    return UserProfile.defaultStudent;
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String studentId,
    String? className,
    String? studyProgram,
    String? university,
    String? photoUrl,
    dynamic newPhotoBytes,
    String? fileExtension,
    bool clearPhoto = false,
  }) async {
    updateCallCount++;
    if (updateException != null) throw updateException!;
    return UserProfile.defaultStudent.copyWith(
      name: name.trim(),
      studentId: studentId.trim(),
    );
  }
}

// ==========================================
// TEST SUITE
// ==========================================

void main() {
  group('Tahap 14 — REST API & External Data Error Handling', () {
    test('1.1: ApiService handles network disconnection (SocketException) cleanly', () async {
      final client = TestHttpClient((request) async {
        throw const SocketException('Failed host lookup: dummyjson.com');
      });

      final service = ApiService(client: client);
      expect(
        () => service.getRandomQuote(),
        throwsA(isA<SocketException>().having(
          (e) => e.message,
          'message',
          contains('Koneksi internet bermasalah'),
        )),
      );
    });

    test('1.2: ApiService handles timeout (TimeoutException) without crash', () async {
      final client = TestHttpClient((request) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      });

      final service = ApiService(client: client);
      expect(
        () => service.getRandomQuote(timeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>().having(
          (e) => e.message,
          'message',
          contains('timeout'),
        )),
      );
    });

    test('1.3: ApiService handles non-200 HTTP status and empty response body', () async {
      // 500 Server Error
      final errorClient = TestHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final errorService = ApiService(client: errorClient);
      expect(
        () => errorService.getRandomQuote(),
        throwsA(isA<HttpException>().having(
          (e) => e.message,
          'message',
          contains('500'),
        )),
      );

      // 200 with Empty Body
      final emptyBodyClient = TestHttpClient((request) async {
        return http.Response('   ', 200);
      });
      final emptyBodyService = ApiService(client: emptyBodyClient);
      expect(
        () => emptyBodyService.getRandomQuote(),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('kosong'),
        )),
      );
    });

    test('1.4: ApiService handles invalid JSON structure or missing quote string', () async {
      // Invalid JSON list
      final listClient = TestHttpClient((request) async {
        return http.Response('["quote 1", "quote 2"]', 200);
      });
      expect(
        () => ApiService(client: listClient).getRandomQuote(),
        throwsA(isA<FormatException>()),
      );

      // Map without quote key
      final missingKeyClient = TestHttpClient((request) async {
        return http.Response(jsonEncode({'author': 'Aristotle'}), 200);
      });
      expect(
        () => ApiService(client: missingKeyClient).getRandomQuote(),
        throwsA(isA<FormatException>()),
      );
    });

    test('1.5: QuoteProvider sets clean user-facing errorMessage and stops loading on error', () async {
      final fakeRepo = FakeErrorQuoteRepository(
        exceptionToThrow: const SocketException('No Internet connection'),
      );
      final provider = QuoteProvider(repository: fakeRepo);

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);

      await provider.fetchQuote();

      expect(provider.isLoading, isFalse);
      expect(provider.quote, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('koneksi internet'));
    });

    test('1.6: QuoteProvider handles TimeoutException and ends loading', () async {
      final fakeRepo = FakeErrorQuoteRepository(
        exceptionToThrow: TimeoutException('Connection timed out'),
      );
      final provider = QuoteProvider(repository: fakeRepo);

      await provider.fetchQuote();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('waktu habis'));
    });

    test('1.7: QuoteProvider retains previous quote when subsequent refresh fails', () async {
      final fakeRepo = FakeErrorQuoteRepository(
        quoteToReturn: const Quote(
          id: 10,
          quote: 'Kutipan pertama yang berhasil disimpan.',
          author: 'Penulis Pertama',
        ),
      );
      final provider = QuoteProvider(repository: fakeRepo);

      await provider.fetchQuote();
      expect(provider.quote?.quote, 'Kutipan pertama yang berhasil disimpan.');
      expect(provider.errorMessage, isNull);

      // Refresh fails with SocketException
      fakeRepo.exceptionToThrow = const SocketException('Lost connection');
      await provider.fetchQuote(isRefresh: true);

      // Previous quote must be preserved, not overwritten or wiped
      expect(provider.quote, isNotNull);
      expect(provider.quote?.quote, 'Kutipan pertama yang berhasil disimpan.');
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    testWidgets('1.8: HomeScreen displays error card and retry button when QuoteProvider fails',
        (WidgetTester tester) async {
      final fakeRepo = FakeErrorQuoteRepository(
        exceptionToThrow: const SocketException('Offline simulated'),
      );
      final quoteProvider = QuoteProvider(repository: fakeRepo);
      await quoteProvider.fetchQuote();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<QuoteProvider>.value(
            value: quoteProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('GAGAL MEMUAT KUTIPAN'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // When Coba Lagi is pressed, fetchQuote is re-triggered
      fakeRepo.exceptionToThrow = null;
      fakeRepo.quoteToReturn = const Quote(
        id: 7,
        quote: 'Kutipan sukses setelah Coba Lagi.',
        author: 'Penulis Sukses',
      );

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('GAGAL MEMUAT KUTIPAN'), findsNothing);
      expect(find.text('“Kutipan sukses setelah Coba Lagi.”'), findsOneWidget);
    });
  });

  group('Tahap 14 — Supabase Operations & Error Propagation', () {
    const testTask = Task(
      id: 'task-err-001',
      title: 'Tugas Error Handling',
      description: 'Deskripsi uji coba kegagalan operasi.',
      deadline: '28 Okt 2026, 23:59 WITA',
      priority: 'Tinggi',
      isCompleted: false,
      isArchived: false,
    );

    test('2.1: TaskProvider.createTask rethrows error, sets errorMessage, ends loading, and preserves list', () async {
      final failingRepo = FakeErrorTaskRepository(
        createException: Exception('42501: RLS policy violated on insert'),
      );
      final provider = TaskProvider(repository: failingRepo, initialTasks: [testTask]);

      expect(provider.isLoading, isFalse);
      expect(provider.tasks.length, 1);

      try {
        await provider.createTask(
          title: 'Tugas Gagal',
          deadline: '29 Okt 2026',
          priority: 'Sedang',
        );
        fail('createTask harus melempar exception saat repository gagal');
      } catch (e) {
        expect(e.toString(), contains('RLS policy violated'));
      }

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('RLS policy violated'));
      // Daftar tugas lokal tidak bertambah
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.id, testTask.id);
    });

    test('2.2: TaskProvider.editTask rethrows error, sets errorMessage, ends loading, and preserves old attributes', () async {
      final failingRepo = FakeErrorTaskRepository(
        updateException: Exception('42501: RLS update denied'),
      );
      final provider = TaskProvider(repository: failingRepo, initialTasks: [testTask]);

      final modified = testTask.copyWith(title: 'Judul Baru Yang Ditolak');

      try {
        await provider.editTask(modified);
        fail('editTask harus melempar exception saat repository gagal');
      } catch (e) {
        expect(e.toString(), contains('RLS update denied'));
      }

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('RLS update denied'));
      // Judul tugas lokal tidak berubah
      expect(provider.tasks.first.title, testTask.title);
    });

    test('2.3: TaskProvider.deleteTask rethrows error, sets errorMessage, ends loading, and preserves task in state', () async {
      final failingRepo = FakeErrorTaskRepository(
        deleteException: Exception('Gagal menghapus tugas dari database: 0 record terhapus'),
      );
      final provider = TaskProvider(repository: failingRepo, initialTasks: [testTask]);

      try {
        await provider.deleteTask(testTask.id);
        fail('deleteTask harus melempar exception saat repository gagal');
      } catch (e) {
        expect(e.toString(), contains('0 record terhapus'));
      }

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
      // Tugas TIDAK dihapus dari state provider jika database gagal
      expect(provider.tasks.length, 1);
      expect(provider.tasks.first.id, testTask.id);
    });

    test('2.4: TaskProvider.toggleTaskCompletion rethrows error and preserves completion state', () async {
      final failingRepo = FakeErrorTaskRepository(
        updateException: Exception('Database update timeout'),
      );
      final provider = TaskProvider(repository: failingRepo, initialTasks: [testTask]);

      try {
        await provider.toggleTaskCompletion(testTask);
        fail('toggleTaskCompletion harus melempar exception');
      } catch (e) {
        expect(e.toString(), contains('Database update timeout'));
      }

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Database update timeout'));
      // Status isCompleted tetap false
      expect(provider.tasks.first.isCompleted, isFalse);
    });

    test('2.5: TaskProvider.archiveTask and restoreTask rethrow error and preserve archive state', () async {
      final failingRepo = FakeErrorTaskRepository(
        updateException: Exception('Database connection lost'),
      );
      final provider = TaskProvider(repository: failingRepo, initialTasks: [testTask]);

      try {
        await provider.archiveTask(testTask);
        fail('archiveTask harus melempar exception');
      } catch (e) {
        expect(e.toString(), contains('Database connection lost'));
      }

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.tasks.first.isArchived, isFalse);
    });

    test('2.6: ProfileProvider.updateProfile rethrows error, terminates loading, and isolates failure', () async {
      final failingRepo = FakeErrorProfileRepository(
        updateException: Exception('42501: permission denied for profiles'),
      );
      final provider = ProfileProvider(
        repository: failingRepo,
        initialProfile: UserProfile.defaultStudent,
      );

      try {
        await provider.updateProfile(
          name: 'Nama Diubah',
          studentId: '2415051099',
        );
        fail('updateProfile harus melempar exception');
      } catch (e) {
        expect(e.toString(), contains('permission denied for profiles'));
      }

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('permission denied for profiles'));
      expect(provider.profile.name, UserProfile.defaultStudent.name);
    });
  });

  group('Tahap 14 — Loading, Error, Empty, and Success State Differentiation', () {
    test('3.1: TaskProvider.loadTasks differentiates load failure from empty state without fake sample data', () async {
      final failingRepo = FakeErrorTaskRepository(
        getTasksException: Exception('Koneksi database Supabase terputus'),
      );
      final provider = TaskProvider(repository: failingRepo);

      expect(provider.tasks, isEmpty);
      await provider.loadTasks();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('Koneksi database Supabase terputus'));
      // HARUS tetap kosong dan TIDAK diisi sample data palsu saat terjadi error
      expect(provider.tasks, isEmpty);
    });

    testWidgets('3.2: TaskListScreen renders loading state when isLoading is true on empty list',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListScreen(
            tasks: [],
            isLoading: true,
          ),
        ),
      );

      expect(find.text('Memuat daftar tugas...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('3.3: TaskListScreen renders error state and Coba Lagi button when loading failed on empty list',
        (WidgetTester tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TaskListScreen(
            tasks: const [],
            isLoading: false,
            errorMessage: 'Gagal memuat tugas dari database: Network error',
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      expect(find.text('Gagal Memuat Tugas'), findsOneWidget);
      expect(find.text('Gagal memuat tugas dari database: Network error'), findsOneWidget);
      expect(find.byKey(const ValueKey('retry_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('retry_button')));
      await tester.pump();
      expect(retryCalled, isTrue);
    });

    testWidgets('3.4: TaskListScreen renders empty state when successfully loaded with 0 tasks',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListScreen(
            tasks: [],
            isLoading: false,
            errorMessage: null,
          ),
        ),
      );

      expect(find.text('Belum Ada Tugas'), findsOneWidget);
      expect(find.text('Tambah Tugas Baru'), findsOneWidget);
      expect(find.text('Gagal Memuat Tugas'), findsNothing);
    });

    testWidgets('3.5: TaskListScreen search empty state is distinct from load failure error state',
        (WidgetTester tester) async {
      const taskA = Task(
        id: 't-1',
        title: 'Pemrograman Web',
        description: 'Tugas praktikum web.',
        deadline: '28 Okt 2026',
        priority: 'Tinggi',
        isCompleted: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListScreen(
            tasks: [taskA],
            isLoading: false,
            errorMessage: null,
          ),
        ),
      );

      expect(find.text('Pemrograman Web'), findsOneWidget);

      // Search non-existent keyword
      final searchField = find.byKey(const ValueKey('task_search_field'));
      await tester.enterText(searchField, 'NonExistentMataKuliah999');
      await tester.pumpAndSettle();

      expect(find.text('Tugas Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Reset Filter & Pencarian'), findsOneWidget);
      expect(find.text('Gagal Memuat Tugas'), findsNothing);
    });

    testWidgets('3.6: TaskListScreen preserves old tasks and displays banner when refresh fails',
        (WidgetTester tester) async {
      const existingTask = Task(
        id: 't-persist',
        title: 'Tugas Tersimpan Sebelumnya',
        description: 'Tugas lama yang sudah ada.',
        deadline: '28 Okt 2026',
        priority: 'Sedang',
        isCompleted: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: TaskListScreen(
            tasks: [existingTask],
            isLoading: false,
            errorMessage: 'Pembaruan data tugas gagal.',
          ),
        ),
      );

      // Old tasks remain visible!
      expect(find.text('Tugas Tersimpan Sebelumnya'), findsOneWidget);
      // Warning banner with Coba Lagi is visible
      expect(find.text('Pembaruan data tugas gagal.'), findsOneWidget);
      expect(find.byKey(const ValueKey('banner_retry_button')), findsOneWidget);
    });

    testWidgets('3.7: HomeScreen renders task error container and retry button on empty task failure',
        (WidgetTester tester) async {
      final fakeRepo = FakeErrorTaskRepository(
        getTasksException: Exception('Koneksi terputus ke Supabase'),
      );
      final taskProvider = TaskProvider(repository: fakeRepo);
      await taskProvider.loadTasks();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home_tasks_error_view')), findsOneWidget);
      expect(find.text('GAGAL MEMUAT TUGAS'), findsOneWidget);
      expect(find.byKey(const ValueKey('home_retry_tasks_button')), findsOneWidget);
    });

    testWidgets('3.8: HomeScreen renders task empty state when tasks list is empty and no error',
        (WidgetTester tester) async {
      final fakeRepo = FakeErrorTaskRepository(tasksToReturn: const []);
      final taskProvider = TaskProvider(repository: fakeRepo);
      await taskProvider.loadTasks();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Tugas Mendatang'), findsOneWidget);
      expect(find.byKey(const ValueKey('home_tasks_error_view')), findsNothing);
    });

    testWidgets('3.9: HomeScreen preserves old tasks and displays warning banner when refresh fails',
        (WidgetTester tester) async {
      const existing = Task(
        id: 'home-persist-1',
        title: 'Tugas Home Preserved',
        description: 'Deskripsi tugas tersimpan di home.',
        deadline: '28 Okt 2026',
        priority: 'Tinggi',
        isCompleted: false,
      );

      final fakeRepo = FakeErrorTaskRepository(
        tasksToReturn: [existing],
      );
      final taskProvider = TaskProvider(repository: fakeRepo, initialTasks: [existing]);

      // Simulate a refresh failure: sets errorMessage while keeping tasks
      failingRefresh() async {
        try {
          await fakeRepo.getTasks();
        } catch (e) {
          // not thrown yet
        }
      }
      await failingRefresh();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<TaskProvider>.value(
            value: taskProvider,
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas Home Preserved'), findsOneWidget);
    });

    testWidgets('3.10: ArchiveScreen renders empty state when no tasks are archived',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArchiveScreen(tasks: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Tugas Terarsip'), findsOneWidget);
    });
  });

  group('Tahap 14 — Form Validation & Duplicate Action Prevention', () {
    testWidgets('4.1: AddTaskScreen rejects whitespace-only title before request is sent',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = FakeErrorTaskRepository();
      final provider = TaskProvider(repository: mockRepo);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: AddTaskScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter only whitespace
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, '     ');
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Tugas Baru');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Judul tugas wajib diisi!'), findsOneWidget);
      // Repository never called
      expect(mockRepo.createTaskCallCount, 0);
    });

    testWidgets('4.2: AddTaskScreen rejects empty deadline before request is sent',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = FakeErrorTaskRepository();
      final provider = TaskProvider(repository: mockRepo);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: AddTaskScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Judul Tugas Valid');
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Tugas Baru');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Tenggat waktu (deadline) wajib diisi!'), findsOneWidget);
      expect(mockRepo.createTaskCallCount, 0);
    });

    testWidgets('4.3: AddTaskScreen keeps form open and preserves entered inputs when save fails',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = FakeErrorTaskRepository(
        createException: Exception('Database constraint violation'),
      );
      final provider = TaskProvider(repository: mockRepo);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: AddTaskScreen(
              initialDeadline: '28 Okt 2026, 23:59 WITA',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter fields
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Judul Tugas Preserved');
      await tester.enterText(textFields.at(1), 'Mata Kuliah PTI');
      await tester.enterText(textFields.at(3), 'Deskripsi rinci tugas.');
      await tester.pumpAndSettle();

      // Select priority
      await tester.tap(find.text('Tinggi'));
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Tugas Baru');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Form remains OPEN
      expect(find.byType(AddTaskScreen), findsOneWidget);
      // Inputs remain intact
      expect(find.text('Judul Tugas Preserved'), findsOneWidget);
      expect(find.text('Mata Kuliah PTI'), findsOneWidget);
      expect(find.text('28 Okt 2026, 23:59 WITA'), findsOneWidget);
      expect(find.text('Deskripsi rinci tugas.'), findsOneWidget);
      // Error SnackBar displayed
      expect(find.textContaining('Gagal menyimpan tugas'), findsOneWidget);
    });

    testWidgets('4.4: EditTaskScreen keeps form open and preserves inputs when edit fails',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const sampleTask = Task(
        id: 'edit-preserve-task',
        title: 'Judul Asli',
        description: 'Deskripsi Asli',
        deadline: '28 Okt 2026',
        priority: 'Sedang',
        isCompleted: false,
      );

      final mockRepo = FakeErrorTaskRepository(
        updateException: Exception('42501: RLS policy violated on update'),
      );
      final provider = TaskProvider(repository: mockRepo, initialTasks: [sampleTask]);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: EditTaskScreen(task: sampleTask)),
        ),
      );
      await tester.pumpAndSettle();

      final titleField = find.widgetWithText(TextField, 'Judul Asli');
      await tester.enterText(titleField, 'Perubahan Judul Baru');
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Form stays open
      expect(find.byType(EditTaskScreen), findsOneWidget);
      // Input is preserved
      expect(find.text('Perubahan Judul Baru'), findsOneWidget);
      // Error SnackBar is shown
      expect(find.textContaining('Gagal memperbarui tugas'), findsOneWidget);
    });

    testWidgets('4.5: TaskDetailScreen prevents duplicate delete and keeps task on failure',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const taskToDelete = Task(
        id: 'delete-fail-task',
        title: 'Tugas Gagal Hapus',
        description: 'Deskripsi tugas gagal hapus.',
        deadline: '28 Okt 2026',
        priority: 'Tinggi',
        isCompleted: false,
      );

      final mockRepo = FakeErrorTaskRepository(
        deleteException: Exception('Delete operation timed out'),
      );
      final provider = TaskProvider(repository: mockRepo, initialTasks: [taskToDelete]);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TaskDetailScreen(task: taskToDelete)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap delete icon in AppBar
      final deleteIcon = find.byTooltip('Hapus Tugas');
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('Hapus Tugas?'), findsOneWidget);

      // Confirm delete in dialog
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      // Detail screen remains OPEN because deletion failed
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.text('Tugas Gagal Hapus'), findsOneWidget);
      // Red error snackbar displayed
      expect(find.textContaining('Gagal menghapus tugas'), findsOneWidget);
      // Task remains in provider
      expect(provider.tasks.length, 1);
    });
  });

  group('Tahap 14 — Regression & Continuity of Tahap 11, 12, 13 Features', () {
    const activeTask = Task(
      id: 'reg-task-1',
      title: 'Tugas Regresi Mobile',
      description: 'Deskripsi tugas regresi.',
      deadline: '30 Okt 2026',
      priority: 'Tinggi',
      courseCategory: 'Pemrograman Mobile - Tugas',
      isCompleted: false,
      isArchived: false,
    );

    testWidgets('5.1: Successful completion toggle updates status and synchronizes provider',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = FakeErrorTaskRepository(initialTasks: [activeTask]);
      final provider = TaskProvider(repository: mockRepo);
      await provider.loadTasks();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: Consumer<TaskProvider>(
            builder: (context, p, _) => MaterialApp(
              home: TaskListScreen(
                tasks: p.tasks,
                isLoading: p.isLoading,
                errorMessage: p.errorMessage,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas Regresi Mobile'), findsOneWidget);

      // Tap completion toggle circle on card
      final toggleButton = find.byTooltip('Tandai selesai');
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(provider.tasks.first.isCompleted, isTrue);
      expect(find.textContaining('ditandai selesai'), findsOneWidget);
    });

    testWidgets('5.2: Successful archive toggle moves task to archive list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = FakeErrorTaskRepository(initialTasks: [activeTask]);
      final provider = TaskProvider(repository: mockRepo);
      await provider.loadTasks();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TaskDetailScreen(task: activeTask)),
        ),
      );
      await tester.pumpAndSettle();

      final archiveButton = find.text('Arsipkan Tugas');
      await tester.ensureVisible(archiveButton);
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      // State updated in provider
      expect(provider.tasks.first.isArchived, isTrue);
      expect(provider.archivedTasks.map((t) => t.id), contains('reg-task-1'));
      expect(find.textContaining('berhasil diarsipkan'), findsOneWidget);

      // Verify task moved to ArchiveScreen
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: ArchiveScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas Regresi Mobile'), findsOneWidget);
      expect(find.text('Pulihkan'), findsOneWidget);
    });

    testWidgets('5.3: Successful deletion removes task from provider and closes detail screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = FakeErrorTaskRepository(initialTasks: [activeTask]);
      final provider = TaskProvider(repository: mockRepo);
      await provider.loadTasks();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: TaskDetailScreen(task: activeTask)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Hapus Tugas'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      expect(provider.tasks, isEmpty);
      expect(find.byType(TaskDetailScreen), findsNothing);
    });
  });
}
