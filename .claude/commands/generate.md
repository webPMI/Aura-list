# /generate - Run Code Generation

Run build_runner to generate code (Hive adapters, etc.)

## Instructions

1. Run `dart run build_runner build --delete-conflicting-outputs`
2. Report which files were generated
3. If generation fails, analyze the error and fix the source model
4. Run `flutter analyze` to verify generated code is valid

## Generated files in this project:
- `lib/models/task_model.g.dart` - Hive TypeAdapter for TaskModel
