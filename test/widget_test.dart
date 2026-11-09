import 'package:flutter_test/flutter_test.dart';
import 'package:digital_notes_organizer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('notes organizer opens with sample notes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NotesApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('little notes'), findsOneWidget);
    expect(find.text('Your notes'), findsOneWidget);
    expect(find.text('A slower kind of morning'), findsOneWidget);
  });
}
