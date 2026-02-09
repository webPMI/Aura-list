# Dialog Widgets

This directory contains reusable dialog widgets for the AuraList app.

## AddTaskDialog

A comprehensive dialog for creating new tasks with all available options.

### Features

- ✨ Material 3 design
- 📱 Responsive layout (bottom sheet on mobile, dialog on desktop)
- 🎯 Task type selector (daily, weekly, monthly, yearly, once)
- ⚡ Priority levels (Low, Medium, High)
- 📁 Category selection
- 📅 Due date and time pickers
- 💪 Motivation field
- 🎁 Reward field
- ⏰ Deadline picker
- ✅ Input validation
- 🔄 Loading states
- ❌ Error handling

### Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/widgets/dialogs/add_task_dialog.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () {
        showAddTaskDialog(
          context: context,
          ref: ref,
          defaultType: 'daily', // or 'weekly', 'monthly', 'yearly', 'once'
          onTaskCreated: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎉 ¡Tarea creada!')),
            );
          },
        );
      },
      child: Icon(Icons.add),
    );
  }
}
```

### Parameters

- `context` (required): BuildContext for showing the dialog
- `ref` (required): WidgetRef for accessing Riverpod providers
- `defaultType` (optional): Default task type ('daily', 'weekly', 'monthly', 'yearly', 'once'). Default: 'daily'
- `onTaskCreated` (optional): Callback function called after task is successfully created

### Behavior

- On screens < 800px height: Shows as a bottom sheet with drag handle
- On screens >= 800px height: Shows as a dialog
- Automatically dismisses on successful task creation
- Shows error messages for validation failures
- Disables submit button while task is being created
- Uses 24-hour time format for time picker

### Integration with Home Screen

You can replace the existing `_showAddTaskDialog` method in `home_screen.dart` with this reusable component:

```dart
// Before (in home_screen.dart)
void _showAddTaskDialog() {
  // Long implementation...
}

// After
import 'package:checklist_app/widgets/dialogs/add_task_dialog.dart';

// Then in your FAB:
FloatingActionButton.extended(
  onPressed: () {
    showAddTaskDialog(
      context: context,
      ref: ref,
      defaultType: _getCurrentType(),
      onTaskCreated: () {
        _showSnackBar('🎉 ¡Tarea creada!');
        _updateSyncCount();
      },
    );
  },
  label: const Text('Nueva Tarea'),
  icon: const Icon(Icons.add_task_rounded),
)
```

This will reduce code duplication and make the dialog reusable across the app.
