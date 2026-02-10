import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(
      child: ChecklistApp(firebaseInitialized: false),
    ));

    // Verify that our app name is present
    //    expect(find.text('AuraList'), findsAtLeastOneWidget);
  });
}
