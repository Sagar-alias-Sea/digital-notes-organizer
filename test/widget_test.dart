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

  testWidgets('new note button opens the note editor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NotesApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('New note'));
    await tester.pumpAndSettle();
    expect(find.text('A new thought'), findsOneWidget);
    expect(find.text('Give it a title'), findsOneWidget);
  });

  testWidgets('tapping a note opens it for editing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NotesApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('A slower kind of morning'));
    await tester.pumpAndSettle();
    expect(find.text('Edit note'), findsOneWidget);
    expect(find.text('A slower kind of morning'), findsOneWidget);
  });

  testWidgets('note menu edit action opens the note editor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NotesApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('Note options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit note').last);
    await tester.pumpAndSettle();
    expect(find.text('Edit note'), findsOneWidget);
    expect(find.text('A slower kind of morning'), findsOneWidget);
  });

  testWidgets('top right menu opens', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NotesApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Create a note'), findsOneWidget);
    expect(find.text('View pinned notes'), findsOneWidget);
  });
}
