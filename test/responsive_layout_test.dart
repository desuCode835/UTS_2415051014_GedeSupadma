import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/screens/add_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/edit_task_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/home_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/profile_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_detail_screen.dart';
import 'package:uts_2415051014_gedesupadma/screens/task_list_screen.dart';
import 'package:uts_2415051014_gedesupadma/widgets/summary_card.dart';
import 'package:uts_2415051014_gedesupadma/widgets/task_card.dart';

void main() {
  const widths = [320.0, 390.0, 700.0, 1000.0];

  group('TaskListScreen Responsive Layout Breakpoints', () {
    testWidgets('Lebar < 600 (compact, 400px): crossAxisCount == 1',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: TaskListScreen()),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<GridView>(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
      expect(find.byType(TaskCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lebar 600-839 (wide, 700px): crossAxisCount == 2',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: TaskListScreen()),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<GridView>(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lebar >= 840 (expanded, 900px): crossAxisCount == 3',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: TaskListScreen()),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<GridView>(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen Responsive Dashboard', () {
    testWidgets('Compact (< 600px, 400px): 1 kolom kartu statistik',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      final summaryGridFinder = find.byWidgetPredicate((widget) {
        if (widget is GridView) {
          final delegate = widget.gridDelegate;
          return delegate is SliverGridDelegateWithFixedCrossAxisCount &&
              delegate.crossAxisCount == 1;
        }
        return false;
      });
      expect(summaryGridFinder, findsWidgets);
      expect(find.byType(SummaryCard), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Wide (600-839px, 700px): 2 kolom kartu statistik',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      final wideGridFinder = find.byWidgetPredicate((widget) {
        if (widget is GridView) {
          final delegate = widget.gridDelegate;
          return delegate is SliverGridDelegateWithFixedCrossAxisCount &&
              delegate.crossAxisCount == 2;
        }
        return false;
      });
      expect(wideGridFinder, findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Expanded (>= 840px, 900px): 3 kolom kartu statistik',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      final expandedGridFinder = find.byWidgetPredicate((widget) {
        if (widget is GridView) {
          final delegate = widget.gridDelegate;
          return delegate is SliverGridDelegateWithFixedCrossAxisCount &&
              delegate.crossAxisCount == 3;
        }
        return false;
      });
      expect(expandedGridFinder, findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Overflow Audit across all screens and screen widths (320px, 390px, 700px, 1000px)', () {
    for (final width in widths) {
      testWidgets('HomeScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err != null) {
          debugPrint('OVERFLOW IN TEST: $err');
        }
        expect(err, isNull);
      });

      testWidgets('TaskListScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: TaskListScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err != null) {
          debugPrint('OVERFLOW IN TEST: $err');
        }
        expect(err, isNull);
      });

      testWidgets('TaskDetailScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          debugPrint('--- FLUTTER ERROR CAUGHT ---');
          debugPrint(details.toString());
          originalOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: TaskDetailScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err is FlutterError) {
          debugPrint(err.toStringDeep());
        }
        expect(err, isNull);
      });

      testWidgets('AddTaskScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: AddTaskScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err != null) {
          debugPrint('OVERFLOW IN TEST: $err');
        }
        expect(err, isNull);
      });

      testWidgets('EditTaskScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: EditTaskScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err != null) {
          debugPrint('OVERFLOW IN TEST: $err');
        }
        expect(err, isNull);
      });

      testWidgets('ProfileScreen on ${width}px width has no overflow',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pumpAndSettle();

        final err = tester.takeException();
        if (err != null) {
          debugPrint('OVERFLOW IN TEST: $err');
        }
        expect(err, isNull);
      });
    }
  });
}
