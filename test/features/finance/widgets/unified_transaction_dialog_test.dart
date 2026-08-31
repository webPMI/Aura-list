import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/finance_category.dart';
import 'package:checklist_app/features/finance/widgets/unified_transaction_dialog.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  Widget buildTestWidget({
    FinanceCategoryType initialType = FinanceCategoryType.expense,
    bool isBottomSheet = true,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: UnifiedTransactionDialog(
            initialType: initialType,
            isBottomSheet: isBottomSheet,
          ),
        ),
      ),
    );
  }

  group('UnifiedTransactionDialog Widget Tests', () {
    testWidgets('Renders properly with Gasto title and quick amount chips', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialType: FinanceCategoryType.expense));
      await tester.pumpAndSettle();

      // Verificar que se muestra el título 'Nuevo Gasto'
      expect(find.text('Nuevo Gasto'), findsOneWidget);
      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
      expect(find.text('Registrar Gasto'), findsOneWidget);

      // Verificar que los chips de adición rápida están presentes
      expect(find.text('+5€'), findsOneWidget);
      expect(find.text('+10€'), findsOneWidget);
      expect(find.text('+20€'), findsOneWidget);
      expect(find.text('+50€'), findsOneWidget);
      expect(find.text('+100€'), findsOneWidget);
    });

    testWidgets('Quick amount chip updates the amount field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on +20€ chip
      await tester.tap(find.text('+20€'));
      await tester.pumpAndSettle();

      expect(find.text('20'), findsOneWidget);

      // Tap on +10€ chip -> total 30
      await tester.tap(find.text('+10€'));
      await tester.pumpAndSettle();

      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('Switching between Gasto and Ingreso changes UI style and button label', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialType: FinanceCategoryType.expense));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Gasto'), findsOneWidget);

      // Switch to Ingreso
      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Ingreso'), findsOneWidget);
      expect(find.text('Registrar Ingreso'), findsOneWidget);
    });

    testWidgets('Switching to Recurrente displays recurrence options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on Recurrente tab
      await tester.tap(find.text('Recurrente'));
      await tester.pumpAndSettle();

      expect(find.text('Periodicidad de pago'), findsOneWidget);
      expect(find.text('Número total de cuotas'), findsOneWidget);
      expect(find.text('Programar Recurrente'), findsOneWidget);
      expect(find.text('Automático'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
    });
  });
}
