# /service - Create New Service

Create a new service class following the project's patterns.

## Arguments
- `$ARGUMENTS` - Service name (e.g., `Notification`, `Storage`, `Analytics`)

## Instructions

1. Analyze existing services in `lib/services/` for patterns
2. Create file at `lib/services/{snake_case_name}_service.dart`
3. Determine if it should be:
   - Singleton (like DatabaseService)
   - Riverpod Provider
   - Static utility class
4. Include proper error handling using ErrorHandler patterns
5. Add initialization if needed

## Template:
```dart
import 'error_handler.dart';

class ServiceNameService {
  static final ServiceNameService _instance = ServiceNameService._internal();
  factory ServiceNameService() => _instance;
  ServiceNameService._internal();

  Future<void> initialize() async {
    // Initialization logic
  }

  // Service methods
}
```

## Integration:
- Initialize in main.dart if needed
- Create Riverpod provider if state management required
