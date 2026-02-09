# /screen - Create New Screen

Create a new screen/page following the project's patterns.

## Arguments
- `$ARGUMENTS` - Screen name (e.g., `Settings`, `TaskDetail`, `Profile`)

## Instructions

1. Analyze `lib/screens/home_screen.dart` for existing patterns
2. Create file at `lib/screens/{snake_case_name}_screen.dart`
3. Include:
   - ConsumerWidget or ConsumerStatefulWidget for Riverpod integration
   - AppBar with proper title
   - Basic scaffold structure
4. Add navigation route if using named routes
5. Run `flutter analyze` to verify

## Template:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScreenNameScreen extends ConsumerWidget {
  const ScreenNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Name'),
      ),
      body: const Center(
        child: Text('Screen content'),
      ),
    );
  }
}
```
