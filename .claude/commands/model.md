# /model - Create New Hive Model

Create a new Hive model with TypeAdapter generation.

## Arguments
- `$ARGUMENTS` - Model name in PascalCase (e.g., `Category`, `Reminder`)

## Instructions

1. Analyze `lib/models/task_model.dart` for the existing pattern
2. Ask user for the model's fields and types
3. Create file at `lib/models/{snake_case_name}.dart`
4. Include Hive annotations:
   - `@HiveType(typeId: X)` - use next available typeId
   - `@HiveField(X)` for each field
5. Run `/generate` to create the `.g.dart` file
6. Register the adapter in the database service

## Template:
```dart
import 'package:hive/hive.dart';

part '{name}.g.dart';

@HiveType(typeId: X)
class ModelName extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  // Constructor, copyWith, etc.
}
```

## Important:
- Check existing typeIds in other models to avoid conflicts
- Register adapter in `lib/services/database_service.dart`
