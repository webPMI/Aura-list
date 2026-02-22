/// Tests para ErrorBoundaryConsumer widget.
///
/// Estos tests verifican:
/// - Renderizado correcto del widget
/// - Manejo de diferentes tipos de errores
/// - Auto-dismiss basado en severidad
/// - Descarte manual
/// - Acciones de reintento
/// - Modos de visualizacion (banner vs SnackBar)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/widgets/error_boundary_consumer.dart';
import 'package:checklist_app/providers/error_provider.dart';
import 'package:checklist_app/services/error_handler.dart';

void main() {
  group('ErrorBoundaryConsumer Widget Tests', () {
    testWidgets('renders child when no errors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(ErrorBoundaryConsumer), findsOneWidget);
    });

    testWidgets('displays error banner when error exists', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar un error critico
      container.read(errorStateProvider.notifier).addError(
            FirebasePermissionException(
              message: 'Permission denied',
              userMessage: 'No tienes permiso.',
            ),
          );

      await tester.pump();

      // Verificar que el error se muestra
      expect(find.text('No tienes permiso.'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('shows dismiss button for all errors', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error
      container.read(errorStateProvider.notifier).addError(
            NetworkException(
              message: 'Network error',
              userMessage: 'Sin conexion.',
              isRetryable: true,
            ),
          );

      await tester.pump();

      // Verificar boton de descarte
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows retry button for retryable errors', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error reintentable
      container.read(errorStateProvider.notifier).addError(
            NetworkException(
              message: 'Network error',
              userMessage: 'Sin conexion.',
              isRetryable: true,
            ),
          );

      await tester.pump();

      // Verificar boton de reintentar
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('dismisses error when close button tapped', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error
      container.read(errorStateProvider.notifier).addError(
            NetworkException(
              message: 'Network error',
              userMessage: 'Sin conexion.',
            ),
          );

      await tester.pump();
      expect(find.text('Sin conexion.'), findsOneWidget);

      // Presionar boton de cerrar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Verificar que el error fue eliminado
      expect(find.text('Sin conexion.'), findsNothing);
    });

    testWidgets('calls onRetry callback when retry button tapped',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      var retryCallCount = 0;
      AppException? retriedError;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              onRetry: (error) {
                retryCallCount++;
                retriedError = error;
              },
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error reintentable
      final testError = NetworkException(
        message: 'Network error',
        userMessage: 'Sin conexion.',
        isRetryable: true,
      );

      container.read(errorStateProvider.notifier).addError(testError);
      await tester.pump();

      // Presionar boton de reintentar
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      // Verificar que se llamo el callback
      expect(retryCallCount, 1);
      expect(retriedError, isA<NetworkException>());
    });

    testWidgets('displays error at bottom when position is bottom',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              position: ErrorPosition.bottom,
              child: const Scaffold(
                body: Center(child: Text('Test Child')),
              ),
            ),
          ),
        ),
      );

      // Agregar error
      container.read(errorStateProvider.notifier).addError(
            ValidationException(
              message: 'Validation error',
              userMessage: 'Campo obligatorio.',
            ),
          );

      await tester.pump();

      // Verificar que el error se encuentra en la parte inferior
      final errorWidget = find.text('Campo obligatorio.');
      expect(errorWidget, findsOneWidget);

      final errorPosition = tester.getTopLeft(errorWidget);
      final childPosition = tester.getTopLeft(find.text('Test Child'));

      // El error deberia estar mas abajo que el hijo
      expect(errorPosition.dy > childPosition.dy, true);
    });

    testWidgets('uses extension method correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const Scaffold(
              body: Text('Test Child'),
            ).withErrorBoundary(
              position: ErrorPosition.bottom,
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(ErrorBoundaryConsumer), findsOneWidget);
    });

    testWidgets('displays different icons for different error types',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      final notifier = container.read(errorStateProvider.notifier);

      // Test NetworkException icon
      notifier.addError(
        NetworkException(
          message: 'Network error',
          userMessage: 'Sin conexion.',
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Clear and test FirebasePermissionException icon
      notifier.clearAll();
      await tester.pump();

      notifier.addError(
        FirebasePermissionException(
          message: 'Permission error',
          userMessage: 'Sin permiso.',
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Clear and test ValidationException icon
      notifier.clearAll();
      await tester.pump();

      notifier.addError(
        ValidationException(
          message: 'Validation error',
          userMessage: 'Campo invalido.',
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('does not show retry button when allowRetry is false',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              allowRetry: false,
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error reintentable
      container.read(errorStateProvider.notifier).addError(
            NetworkException(
              message: 'Network error',
              userMessage: 'Sin conexion.',
              isRetryable: true,
            ),
          );

      await tester.pump();

      // Verificar que NO hay boton de reintentar
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  group('ErrorBoundaryConsumer Severity Tests', () {
    testWidgets('displays critical error with correct styling', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error critico
      container.read(errorStateProvider.notifier).addError(
            HiveStorageException(
              message: 'Storage error',
              userMessage: 'Error de almacenamiento.',
            ),
          );

      await tester.pump();

      // Verificar titulo de severidad
      expect(find.text('Error Critico'), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('displays warning error with correct styling', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error de advertencia
      container.read(errorStateProvider.notifier).addError(
            NetworkException(
              message: 'Network timeout',
              userMessage: 'Conexion lenta.',
              isRetryable: true,
            ),
          );

      await tester.pump();

      // Verificar titulo de severidad
      expect(find.text('Advertencia'), findsOneWidget);
    });

    testWidgets('displays info error with correct styling', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ErrorBoundaryConsumer(
              child: const Scaffold(
                body: Text('Test Child'),
              ),
            ),
          ),
        ),
      );

      // Agregar error informativo
      container.read(errorStateProvider.notifier).addError(
            ValidationException(
              message: 'Validation error',
              userMessage: 'Campo requerido.',
            ),
          );

      await tester.pump();

      // Verificar titulo de severidad
      expect(find.text('Informacion'), findsOneWidget);
    });
  });
}
