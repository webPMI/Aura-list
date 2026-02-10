import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This is a minimal smoke test that verifies the app widget can be instantiated
    // Full integration tests would require setting up path_provider and Hive mocks
    await tester.pumpWidget(const ProviderScope(
      child: ChecklistApp(firebaseInitialized: false),
    ));

    // Just verify the widget was created without immediate crashes
    // We can't pump and settle as async operations require platform plugins
    expect(find.byType(ChecklistApp), findsOneWidget);
  });
}
