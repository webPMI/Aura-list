# /widget - Create New Widget

Create a new Flutter widget following the project's patterns.

## Arguments
- `$ARGUMENTS` - Widget name in PascalCase (e.g., `TaskCard`, `SettingsButton`)

## Instructions

1. Ask the user if they want a StatelessWidget or StatefulWidget
2. Create the file at `lib/widgets/{snake_case_name}.dart`
3. Follow the existing widget patterns in `lib/widgets/`
4. Include necessary imports (flutter/material.dart, riverpod if needed)
5. Add basic documentation comments
6. Run `flutter analyze` to verify no issues

## Template structure:
```dart
import 'package:flutter/material.dart';

class WidgetName extends StatelessWidget {
  const WidgetName({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```
