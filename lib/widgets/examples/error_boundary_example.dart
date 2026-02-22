/// Ejemplo de uso del ErrorBoundaryConsumer widget.
///
/// Este archivo muestra diferentes formas de usar el ErrorBoundaryConsumer
/// para manejar errores en pantallas criticas.
///
/// NO USAR EN PRODUCCION - Solo para referencia.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../error_boundary_consumer.dart';
import '../../services/error_handler.dart';
import '../../providers/error_provider.dart';

// =============================================================================
// EJEMPLO 1: Uso Basico - Banner en la parte superior
// =============================================================================

class Example1BasicBanner extends ConsumerWidget {
  const Example1BasicBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      // Configuracion basica - muestra banner en la parte superior
      child: Scaffold(
        appBar: AppBar(title: const Text('Ejemplo 1: Banner Basico')),
        body: Column(
          children: [
            const Text('Esta pantalla muestra errores criticos en un banner.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _simulateCriticalError(ref),
              child: const Text('Simular Error Critico'),
            ),
            ElevatedButton(
              onPressed: () => _simulateWarningError(ref),
              child: const Text('Simular Error de Advertencia'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateCriticalError(WidgetRef ref) {
    ref.read(errorStateProvider.notifier).addError(
          FirebasePermissionException(
            message: 'Permission denied for resource',
            userMessage: 'No tienes permiso para realizar esta accion.',
          ),
        );
  }

  void _simulateWarningError(WidgetRef ref) {
    ref.read(errorStateProvider.notifier).addError(
          NetworkException(
            message: 'Network timeout',
            userMessage: 'Sin conexion. Los cambios se guardaran localmente.',
            isRetryable: true,
          ),
        );
  }
}

// =============================================================================
// EJEMPLO 2: Banner en la parte inferior
// =============================================================================

class Example2BottomBanner extends ConsumerWidget {
  const Example2BottomBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      position: ErrorPosition.bottom, // Banner abajo
      child: Scaffold(
        appBar: AppBar(title: const Text('Ejemplo 2: Banner Inferior')),
        body: const Center(
          child: Text('Los errores se muestran en la parte inferior.'),
        ),
      ),
    );
  }
}

// =============================================================================
// EJEMPLO 3: Modo SnackBar
// =============================================================================

class Example3SnackBar extends ConsumerWidget {
  const Example3SnackBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      showAsSnackBar: true, // Usar SnackBar en lugar de banner
      snackBarDuration: const Duration(seconds: 5),
      child: Scaffold(
        appBar: AppBar(title: const Text('Ejemplo 3: SnackBar')),
        body: Column(
          children: [
            const Text('Los errores se muestran como SnackBar.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _simulateError(ref),
              child: const Text('Simular Error'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateError(WidgetRef ref) {
    ref.read(errorStateProvider.notifier).addError(
          ValidationException(
            message: 'Invalid input',
            userMessage: 'El campo nombre es obligatorio.',
            fieldName: 'nombre',
          ),
        );
  }
}

// =============================================================================
// EJEMPLO 4: Con manejador de reintentos personalizado
// =============================================================================

class Example4CustomRetry extends ConsumerWidget {
  const Example4CustomRetry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      allowRetry: true,
      onRetry: (error) {
        // Logica personalizada de reintento segun el tipo de error
        if (error is NetworkException) {
          _retryNetworkOperation(ref);
        } else if (error is SyncException) {
          _retrySyncOperation(ref);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ejemplo 4: Reintento Personalizado')),
        body: Column(
          children: [
            const Text('Presiona reintentar para ejecutar logica personalizada.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _simulateNetworkError(ref),
              child: const Text('Simular Error de Red'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateNetworkError(WidgetRef ref) {
    ref.read(errorStateProvider.notifier).addError(
          NetworkException(
            message: 'Connection timeout',
            userMessage: 'La conexion tardo demasiado. Intenta de nuevo.',
            isRetryable: true,
          ),
        );
  }

  void _retryNetworkOperation(WidgetRef ref) {
    // Aqui va la logica de reintento (ej: refresh provider)
    debugPrint('Reintentando operacion de red...');
  }

  void _retrySyncOperation(WidgetRef ref) {
    // Aqui va la logica de reintento de sincronizacion
    debugPrint('Reintentando sincronizacion...');
  }
}

// =============================================================================
// EJEMPLO 5: Usando la extension
// =============================================================================

class Example5Extension extends ConsumerWidget {
  const Example5Extension({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar el extension method .withErrorBoundary()
    return Scaffold(
      appBar: AppBar(title: const Text('Ejemplo 5: Extension Method')),
      body: const Center(
        child: Text('Usando .withErrorBoundary() extension'),
      ),
    ).withErrorBoundary(
      position: ErrorPosition.bottom,
      allowRetry: true,
    );
  }
}

// =============================================================================
// EJEMPLO 6: Pantalla de tareas con manejo de errores
// =============================================================================

class Example6TaskScreen extends ConsumerWidget {
  const Example6TaskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      // Reintentar cargar tareas si hay error de red
      onRetry: (error) {
        if (error is NetworkException) {
          // ref.refresh(tasksProvider); // Descomentar en produccion
          debugPrint('Recargando tareas...');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ejemplo 6: Pantalla de Tareas'),
        ),
        body: Column(
          children: [
            const Text('Simula errores tipicos en una pantalla de tareas.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _simulateStorageError(ref),
              child: const Text('Error de Almacenamiento (Critico)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _simulateSyncError(ref),
              child: const Text('Error de Sincronizacion (Advertencia)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _simulateValidationError(ref),
              child: const Text('Error de Validacion (Info)'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateStorageError(WidgetRef ref) {
    // Error critico - NO se auto-descarta
    ref.read(errorStateProvider.notifier).addError(
          HiveStorageException(
            message: 'Failed to write to Hive box: tasks',
            userMessage: 'Error al guardar datos localmente. Reinicia la aplicacion.',
            boxName: 'tasks',
            operation: HiveOperation.write,
          ),
        );
  }

  void _simulateSyncError(WidgetRef ref) {
    // Advertencia - se auto-descarta despues de 10 segundos
    ref.read(errorStateProvider.notifier).addError(
          SyncException(
            message: 'Failed to upload data to cloud',
            userMessage: 'No se pudieron subir los datos. Se reintentara automaticamente.',
            direction: SyncDirection.upload,
            failedCount: 3,
            attemptCount: 1,
            isRetryable: true,
          ),
        );
  }

  void _simulateValidationError(WidgetRef ref) {
    // Info - se auto-descarta despues de 10 segundos
    ref.read(errorStateProvider.notifier).addError(
          ValidationException(
            message: 'Required field is empty: title',
            userMessage: 'El campo titulo es obligatorio.',
            fieldName: 'titulo',
          ),
        );
  }
}

// =============================================================================
// PANTALLA DE NAVEGACION DE EJEMPLOS
// =============================================================================

class ErrorBoundaryExamplesScreen extends StatelessWidget {
  const ErrorBoundaryExamplesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplos ErrorBoundaryConsumer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ejemplos de uso del ErrorBoundaryConsumer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildExampleCard(
            context,
            'Ejemplo 1: Banner Basico',
            'Muestra errores en un banner en la parte superior',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Example1BasicBanner()),
            ),
          ),
          _buildExampleCard(
            context,
            'Ejemplo 2: Banner Inferior',
            'Muestra errores en la parte inferior de la pantalla',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Example2BottomBanner()),
            ),
          ),
          _buildExampleCard(
            context,
            'Ejemplo 3: SnackBar',
            'Muestra errores como SnackBar temporal',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Example3SnackBar()),
            ),
          ),
          _buildExampleCard(
            context,
            'Ejemplo 4: Reintento Personalizado',
            'Maneja reintentos con logica personalizada',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Example4CustomRetry()),
            ),
          ),
          _buildExampleCard(
            context,
            'Ejemplo 5: Extension Method',
            'Usa el extension method .withErrorBoundary()',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Example5Extension()),
            ),
          ),
          _buildExampleCard(
            context,
            'Ejemplo 6: Pantalla de Tareas',
            'Simula errores en una pantalla de tareas real',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Example6TaskScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
