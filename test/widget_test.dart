import 'package:flutter_test/flutter_test.dart';
import 'package:uts_2415051014_gedesupadma/main.dart';

void main() {
  testWidgets('TaskMate smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify TaskMate title and dashboard elements render
    expect(find.text('TaskMate'), findsOneWidget);
    expect(find.text('Ringkasan Tugas'), findsOneWidget);
    expect(find.text('Tugas Mendatang'), findsOneWidget);
  });
}
