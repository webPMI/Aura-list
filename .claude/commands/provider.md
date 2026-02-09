# /provider - Create New Riverpod Provider

Create a new Riverpod provider following the project's patterns.

## Arguments
- `$ARGUMENTS` - Provider name (e.g., `settings`, `user`, `notifications`)

## Instructions

1. Analyze existing providers in `lib/providers/` for patterns
2. Ask user what type of provider they need:
   - StateNotifierProvider (for complex state)
   - Provider (for simple computed values)
   - FutureProvider (for async data)
   - StreamProvider (for real-time data)
3. Create file at `lib/providers/{name}_provider.dart`
4. Include proper imports and type definitions
5. Export from a barrel file if one exists

## Example pattern (StateNotifierProvider):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NameNotifier extends StateNotifier<NameState> {
  NameNotifier() : super(NameState.initial());

  // Methods to modify state
}

final nameProvider = StateNotifierProvider<NameNotifier, NameState>((ref) {
  return NameNotifier();
});
```
