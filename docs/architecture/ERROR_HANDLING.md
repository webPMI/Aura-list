# Error Handling Architecture

A comprehensive guide to error handling in AuraList, covering severity-based auto-dismiss logic, the ErrorBoundaryConsumer widget, and best practices for critical screen error management.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Implementation Guide](#implementation-guide)
4. [Visual Examples](#visual-examples)
5. [API Reference](#api-reference)
6. [Testing Guide](#testing-guide)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

Get started with error handling in 5 minutes!

### Step 1: Import the Widget

```dart
import 'package:checklist_app/widgets/error_boundary_consumer.dart';
```

### Step 2: Wrap Your Screen

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      child: Scaffold(
        appBar: AppBar(title: Text('My Screen')),
        body: MyContent(),
      ),
    );
  }
}
```

### Step 3: Done! 🎉

Errors will now automatically display with smart auto-dismiss behavior.

### Common Use Cases

#### Critical Data Screen (Tasks, Notes)

```dart
ErrorBoundaryConsumer(
  onRetry: (error) {
    if (error is NetworkException) {
      ref.refresh(tasksProvider);
    }
  },
  child: TaskListScreen(),
)
```

**What You Get:**
- Critical storage errors stay visible
- Network errors auto-dismiss after 10s
- Retry button for network errors

#### Settings Screen

```dart
ErrorBoundaryConsumer(
  showAsSnackBar: true,
  child: SettingsScreen(),
)
```

**What You Get:**
- Validation errors shown as SnackBars
- Auto-dismiss after 4 seconds
- Clean UI without persistent banners

#### Bottom Position Banner

```dart
ErrorBoundaryConsumer(
  position: ErrorPosition.bottom,
  child: MyScreen(),
)
```

**What You Get:**
- Error banner appears at bottom
- Header content always visible
- Same auto-dismiss logic

#### Using Extension Method (Quickest!)

```dart
Scaffold(
  appBar: AppBar(title: Text('My Screen')),
  body: MyContent(),
).withErrorBoundary()
```

**What You Get:**
- One-line integration
- Default settings (top banner, auto-dismiss)
- Same functionality

### Decision Tree: Which Configuration?

```
Do you have critical data operations?
├─ YES → Use Banner Mode (default)
│         ErrorBoundaryConsumer(child: ...)
│
└─ NO  → Is UI space limited?
          ├─ YES → Use SnackBar Mode
          │         ErrorBoundaryConsumer(showAsSnackBar: true, ...)
          │
          └─ NO  → Use Banner at Bottom
                    ErrorBoundaryConsumer(position: ErrorPosition.bottom, ...)
```

---

## Architecture Overview

### Design Philosophy

This implementation follows AuraList's core design philosophy:

- **Reduce cognitive load** - Smart auto-dismiss based on severity
- **Celebrate progress** - Color-coded, friendly error messages
- **Work offline seamlessly** - Network errors auto-dismiss (normal operation)
- **Respect time and attention** - Only critical errors require manual action

### Error Severity Levels

The system automatically classifies errors into severity levels that determine display behavior:

| Severity | Definition | Auto-Dismiss | Examples |
|----------|-----------|--------------|----------|
| **Critical** | Must have user attention, unrecoverable | Never | FirebasePermissionException, HiveStorageException, non-retryable AuthException |
| **Error** | Needs attention, can be retried | Never | Retryable errors that need user awareness |
| **Warning** | Temporary issue, will retry automatically | After 10s | Retryable NetworkException, retryable SyncException |
| **Info** | Informational, can auto-dismiss | After 10s | ValidationException, input errors |

### Severity Auto-Detection

The system automatically determines severity based on error type:

```dart
CRITICAL → Never auto-dismiss
  - FirebasePermissionException
  - HiveStorageException
  - Non-retryable AuthException
  - Any non-retryable error

ERROR → Never auto-dismiss
  - Retryable errors that need attention

WARNING → Auto-dismiss after 10s
  - Retryable NetworkException
  - Retryable SyncException

INFO → Auto-dismiss after 10s
  - ValidationException
```

### Data Flow

```
UI (ConsumerWidget)
      ↑
      watches
      │
      v
Riverpod Providers (errorStateProvider)
      ↑
      │ provides errors to
      │
ErrorBoundaryConsumer Widget
      ↓
      displays error banner/snackbar
      │
      → applies severity-based styling
      → sets auto-dismiss timer (if applicable)
      → waits for user action
      → removes error when dismissed/expired
```

### File Structure

- **`lib/providers/error_provider.dart`** - Severity detection and auto-dismiss logic
- **`lib/widgets/error_boundary_consumer.dart`** - Consumer widget for displaying errors
- **`lib/core/exceptions/app_exceptions.dart`** - Exception types and definitions
- **`lib/services/error_handler.dart`** - Error classification service

---

## Implementation Guide

### Core Components

#### 1. Error Provider (`lib/providers/error_provider.dart`)

Modified `ErrorStateNotifier` with severity-based auto-dismiss logic:

**Key Methods:**

- `addError(error, {severity})` - Add error with optional severity
- `_detectSeverity(error)` - Automatically classify error severity
- `_shouldAutoDismiss(severity)` - Determine if error should auto-dismiss
- `removeError(error)` - Remove error from state

**Severity Classification Logic:**

```dart
ErrorSeverity _detectSeverity(AppException error) {
  if (error is FirebasePermissionException) return ErrorSeverity.critical;
  if (error is HiveStorageException) return ErrorSeverity.critical;
  if (error is AuthException && !error.isRetryable) return ErrorSeverity.critical;
  if (!error.isRetryable) return ErrorSeverity.critical;

  if (error is AuthException) return ErrorSeverity.error;
  if (error is NetworkException) return error.isRetryable ? ErrorSeverity.warning : ErrorSeverity.error;
  if (error is SyncException) return error.isRetryable ? ErrorSeverity.warning : ErrorSeverity.error;
  if (error is ValidationException) return ErrorSeverity.info;

  return ErrorSeverity.error;
}

bool _shouldAutoDismiss(ErrorSeverity severity) {
  return severity == ErrorSeverity.warning || severity == ErrorSeverity.info;
}
```

#### 2. Error Boundary Consumer Widget (`lib/widgets/error_boundary_consumer.dart`)

Main widget for displaying errors on critical screens.

**Features:**
- Watches `errorStateProvider` for errors
- Two display modes: Banner and SnackBar
- Color-coded by severity (Material 3)
- Manual dismissal for all errors
- Retry support for retryable errors
- Position control (top/bottom for banners)
- Extension method for easy integration

**Widget API:**

```dart
ErrorBoundaryConsumer({
  required Widget child,                          // Child widget to wrap
  bool showAsSnackBar = false,                   // Use SnackBar instead of banner
  ErrorPosition position = ErrorPosition.top,    // Banner position (top/bottom)
  Duration snackBarDuration = Duration(seconds: 4), // SnackBar duration
  bool allowRetry = true,                        // Show retry button
  Function(AppException)? onRetry,               // Custom retry handler
  bool showOnlyLatest = true,                    // Show only most recent error
})
```

**Extension Method:**

```dart
Widget.withErrorBoundary({
  ErrorPosition position = ErrorPosition.top,
  bool showAsSnackBar = false,
  Function(AppException)? onRetry,
  bool allowRetry = true,
})
```

### Display Modes

#### Banner Mode (Default)

Persistent banner displayed at top or bottom of screen:

```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  Error Critico                                      ✕    │
│    No tienes permiso para realizar esta accion.             │
│                                            [Reintentar]      │
└─────────────────────────────────────────────────────────────┘
```

Best for: Critical screens with important operations (data sync, auth, storage)

#### SnackBar Mode

Temporary notification bar at bottom:

```
┌─────────────────────────────────────────────────────────────┐
│ ℹ️  Informacion                                        ✕    │
│    El campo titulo es obligatorio.       [Reintentar]       │
└─────────────────────────────────────────────────────────────┘
```

Best for: Settings, preferences, or less critical screens

### Integration Steps

#### Step 1: Wrap Critical Screens

Identify screens with critical operations and wrap them:

```dart
// Before
class TaskListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(...);
  }
}

// After
class TaskListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      child: Scaffold(...),
    );
  }
}
```

#### Step 2: Add Custom Retry Logic (Optional)

For screens with specific retry operations:

```dart
ErrorBoundaryConsumer(
  onRetry: (error) {
    if (error is NetworkException) {
      ref.refresh(tasksProvider);
    } else if (error is SyncException) {
      ref.read(databaseServiceProvider).retrySyncQueue();
    } else if (error is AuthException) {
      ref.read(authServiceProvider).signInAnonymously();
    }
  },
  child: Scaffold(...),
)
```

#### Step 3: Choose Display Mode

For less critical screens, use SnackBar mode:

```dart
ErrorBoundaryConsumer(
  showAsSnackBar: true,
  snackBarDuration: Duration(seconds: 5),
  child: SettingsScreen(),
)
```

### Color Scheme (Material 3)

| Severity | Background | Text | Icon | Use Case |
|----------|-----------|------|------|----------|
| **Info** | `primaryContainer` | `onPrimaryContainer` | `info_outline` | Validation errors, informational messages |
| **Warning** | `tertiaryContainer` | `onTertiaryContainer` | `warning_amber` | Network issues, sync retries |
| **Error** | `errorContainer` | `onErrorContainer` | `error_outline` | General errors requiring attention |
| **Critical** | `error` (bright red) | `onError` | `error` | Permission denied, storage failures, auth issues |

### Auto-Dismiss Behavior Table

| Error Type | Severity | Auto-Dismiss | Timeline |
|------------|----------|--------------|----------|
| ValidationException | Info | ✅ Yes | After 10s |
| NetworkException (retryable) | Warning | ✅ Yes | After 10s |
| SyncException (retryable) | Warning | ✅ Yes | After 10s |
| AuthException (non-retryable) | Error | ❌ No | Manual dismiss |
| FirebasePermissionException | Critical | ❌ No | Manual dismiss |
| HiveStorageException | Critical | ❌ No | Manual dismiss |
| Any non-retryable error | Critical | ❌ No | Manual dismiss |

---

## Visual Examples

### Display Modes Visualization

#### Banner Mode (Top Position)

```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  Error Critico                                      ✕    │
│    No tienes permiso para realizar esta accion.             │
│                                            [Reintentar]      │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    App Bar Title                            │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│                  Main Content Area                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Banner Mode (Bottom Position)

```
┌─────────────────────────────────────────────────────────────┐
│                    App Bar Title                            │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│                  Main Content Area                          │
│                                                             │
┌─────────────────────────────────────────────────────────────┐
│ 📡  Advertencia                                        ✕    │
│    Sin conexion. Los cambios se guardaran localmente.       │
│                                            [Reintentar]      │
└─────────────────────────────────────────────────────────────┘
```

#### SnackBar Mode

```
┌─────────────────────────────────────────────────────────────┐
│                    App Bar Title                            │
└─────────────────────────────────────────────────────────────┘
│                                                             │
│                  Main Content Area                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ℹ️  El campo nombre es obligatorio. [Reintentar] ✕ │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Severity Color Coding

#### Critical Error (Red Background)

```
┌─────────────────────────────────────────────────────────────┐
│ 🔒  Error Critico                                      ✕    │
│    No tienes permiso para realizar esta accion.             │
│                                                              │
│ Background: colorScheme.error (bright red)                  │
│ Text: colorScheme.onError (white)                           │
│ Auto-Dismiss: ❌ NEVER                                      │
└─────────────────────────────────────────────────────────────┘
```

#### Error (Light Red Background)

```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️  Error                                              ✕    │
│    Ocurrio un error inesperado.                             │
│                                            [Reintentar]      │
│ Background: colorScheme.errorContainer (light red)          │
│ Text: colorScheme.onErrorContainer (dark red)               │
│ Auto-Dismiss: ❌ NEVER                                      │
└─────────────────────────────────────────────────────────────┘
```

#### Warning (Orange/Tertiary Background)

```
┌─────────────────────────────────────────────────────────────┐
│ 📡  Advertencia                                        ✕    │
│    Sin conexion. Los cambios se guardaran localmente.       │
│                                            [Reintentar]      │
│ Background: colorScheme.tertiaryContainer (orange)          │
│ Text: colorScheme.onTertiaryContainer (dark orange)         │
│ Auto-Dismiss: ✅ After 10 seconds                           │
└─────────────────────────────────────────────────────────────┘
```

#### Info (Blue/Primary Background)

```
┌─────────────────────────────────────────────────────────────┐
│ ℹ️  Informacion                                        ✕    │
│    El campo titulo es obligatorio.                          │
│                                                              │
│ Background: colorScheme.primaryContainer (blue)             │
│ Text: colorScheme.onPrimaryContainer (dark blue)            │
│ Auto-Dismiss: ✅ After 10 seconds                           │
└─────────────────────────────────────────────────────────────┘
```

### Error Type Icons

```
Network Error        Permission Error     Storage Error
┌──────────┐        ┌──────────┐         ┌──────────┐
│   📡      │        │   🔒      │         │   💾      │
│ wifi_off │        │lock_outline│        │ storage  │
└──────────┘        └──────────┘         └──────────┘

Sync Error          Auth Error           Validation Error
┌──────────┐        ┌──────────┐         ┌──────────┐
│   🔄      │        │   👤      │         │   ⚠️      │
│sync_problem│      │person_off │        │warning_amber│
└──────────┘        └──────────┘         └──────────┘

Unknown Error
┌──────────┐
│   ❌      │
│error_outline│
└──────────┘
```

### Auto-Dismiss Timeline

#### Critical/Error Severity (No Auto-Dismiss)

```
Time: 0s ──────────────────────────────────────────────> ∞
     │                                                   │
     │ ┌────────────────────────────────────────────┐  │
     │ │ 🔒 Error Critico                       ✕  │  │
     │ │    No tienes permiso...                     │  │
     │ └────────────────────────────────────────────┘  │
     │                                                   │
     │         STAYS VISIBLE UNTIL MANUALLY DISMISSED   │
     │                                                   │
```

#### Warning/Info Severity (Auto-Dismiss After 10s)

```
Time: 0s ────────────────────────────> 10s ──────────> ∞
     │                                  │               │
     │ ┌──────────────────────────────┐ │               │
     │ │ ℹ️  Informacion           ✕ │ │               │
     │ │    Campo obligatorio.         │ │  AUTO-DISMISSED│
     │ └──────────────────────────────┘ │               │
     │                                  ▼               │
     │         VISIBLE FOR 10 SECONDS   GONE            │
```

### User Interaction Flows

#### Scenario 1: Critical Error - Manual Dismiss Required

```
┌───────────────────────────────────────────────────────────┐
│ 1. Error Occurs                                           │
│    ↓                                                      │
│ 2. ErrorStateNotifier.addError(criticalError)            │
│    ↓                                                      │
│ 3. _detectSeverity() → ErrorSeverity.critical            │
│    ↓                                                      │
│ 4. _shouldAutoDismiss() → false                          │
│    ↓                                                      │
│ 5. ErrorBoundaryConsumer displays banner (RED)           │
│    ↓                                                      │
│ 6. ⏰ Time passes... error STAYS visible                 │
│    ↓                                                      │
│ 7. 👤 User taps [X] button                               │
│    ↓                                                      │
│ 8. Error dismissed                                        │
└───────────────────────────────────────────────────────────┘
```

#### Scenario 2: Warning Error - Auto-Dismiss

```
┌───────────────────────────────────────────────────────────┐
│ 1. Error Occurs                                           │
│    ↓                                                      │
│ 2. ErrorStateNotifier.addError(networkError)             │
│    ↓                                                      │
│ 3. _detectSeverity() → ErrorSeverity.warning             │
│    ↓                                                      │
│ 4. _shouldAutoDismiss() → true                           │
│    ↓                                                      │
│ 5. ErrorBoundaryConsumer displays banner (ORANGE)        │
│    ↓                                                      │
│ 6. ⏰ 10 seconds timer starts                            │
│    ↓                                                      │
│ 7. ⏰ Timer completes                                     │
│    ↓                                                      │
│ 8. Error auto-dismissed ✅                                │
└───────────────────────────────────────────────────────────┘
```

#### Scenario 3: Retryable Error - User Retries

```
┌───────────────────────────────────────────────────────────┐
│ 1. Network Error Occurs                                   │
│    ↓                                                      │
│ 2. ErrorBoundaryConsumer displays banner with [Reintentar]│
│    ┌────────────────────────────────────────────┐        │
│    │ 📡 Advertencia                        ✕   │        │
│    │    Sin conexion.         [Reintentar]      │        │
│    └────────────────────────────────────────────┘        │
│    ↓                                                      │
│ 3. 👤 User taps [Reintentar]                             │
│    ↓                                                      │
│ 4. onRetry callback executed                              │
│    ↓                                                      │
│ 5. Operation retried (e.g., ref.refresh(provider))       │
│    ↓                                                      │
│ 6. Error dismissed                                        │
│    ↓                                                      │
│ 7. If retry fails, new error is shown                    │
└───────────────────────────────────────────────────────────┘
```

### Error Classification Decision Tree

```
                          Error Occurs
                               │
                               ▼
              ┌────────────────────────────────┐
              │   What type is the error?      │
              └────────────────┬───────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐    ┌────────────────┐    ┌────────────────┐
│ Permission/   │    │  Network/Sync  │    │  Validation    │
│ Storage/Auth  │    │  (retryable)   │    │  Error         │
│ (critical)    │    │                │    │                │
└───────┬───────┘    └────────┬───────┘    └────────┬───────┘
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐    ┌────────────────┐    ┌────────────────┐
│ CRITICAL      │    │   WARNING      │    │     INFO       │
│ Red Banner    │    │ Orange Banner  │    │  Blue Banner   │
│ NO Auto-      │    │ Auto-dismiss   │    │ Auto-dismiss   │
│ Dismiss       │    │ after 10s      │    │ after 10s      │
│ Manual ✕ only │    │ Can dismiss ✕  │    │ Can dismiss ✕  │
│ May retry 🔄  │    │ May retry 🔄   │    │ No retry       │
└───────────────┘    └────────────────┘    └────────────────┘
```

### Integration Patterns

#### Pattern 1: Wrap Entire Screen

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorBoundaryConsumer(
      child: Scaffold(
        appBar: AppBar(...),
        body: MyContent(),
      ),
    );
  }
}
```

Visual Result:
```
┌─────────────────────────────────────────────────────────┐
│ ErrorBoundaryConsumer                                   │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ [Error Banner if error exists]                      │ │
│ ├─────────────────────────────────────────────────────┤ │
│ │ Scaffold                                            │ │
│ │ ┌───────────────────────────────────────────────┐   │ │
│ │ │ AppBar                                        │   │ │
│ │ ├───────────────────────────────────────────────┤   │ │
│ │ │ Body: MyContent                               │   │ │
│ │ └───────────────────────────────────────────────┘   │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

#### Pattern 2: Using Extension Method

```dart
Widget build(BuildContext context, WidgetRef ref) {
  return Scaffold(...).withErrorBoundary(
    position: ErrorPosition.bottom,
  );
}
```

Visual Result (Same as Pattern 1, but with banner at bottom):
```
┌─────────────────────────────────────────────────────────┐
│ ErrorBoundaryConsumer                                   │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Scaffold                                            │ │
│ │ ┌───────────────────────────────────────────────┐   │ │
│ │ │ AppBar                                        │   │ │
│ │ ├───────────────────────────────────────────────┤   │ │
│ │ │ Body: MyContent                               │   │ │
│ │ └───────────────────────────────────────────────┘   │ │
│ ├─────────────────────────────────────────────────────┤ │
│ │ [Error Banner if error exists]                      │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Multiple Errors Behavior

#### When Multiple Errors Exist (showOnlyLatest = true, default)

```
State: [Error1, Error2, Error3]  (Error3 is most recent)
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│ 🔒 Error Critico                                   ✕   │
│    Only Error3 (most recent) is shown                  │
└─────────────────────────────────────────────────────────┘
```

#### When Multiple Errors Exist (showOnlyLatest = false)

```
State: [Error1, Error2, Error3]
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│ 🔒 Error Critico                                   ✕   │
│    Error3 message                                       │
└─────────────────────────────────────────────────────────┘
  (After dismissing Error3, Error2 appears, then Error1)
```

---

## API Reference

### ErrorBoundaryConsumer

#### Constructor

```dart
ErrorBoundaryConsumer({
  required Widget child,
  bool showAsSnackBar = false,
  ErrorPosition position = ErrorPosition.top,
  Duration snackBarDuration = Duration(seconds: 4),
  bool allowRetry = true,
  Function(AppException)? onRetry,
  bool showOnlyLatest = true,
})
```

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | Child widget to wrap with error boundary |
| `showAsSnackBar` | `bool` | `false` | Use SnackBar instead of persistent banner |
| `position` | `ErrorPosition` | `ErrorPosition.top` | Banner position (top/bottom) - ignored if `showAsSnackBar` is true |
| `snackBarDuration` | `Duration` | `4 seconds` | Duration to show SnackBar before auto-dismiss |
| `allowRetry` | `bool` | `true` | Show retry button for retryable errors |
| `onRetry` | `Function(AppException)?` | `null` | Custom callback when retry button is tapped |
| `showOnlyLatest` | `bool` | `true` | Show only most recent error (true) or all errors in queue (false) |

#### Extension Method

```dart
extension WidgetErrorBoundaryExt on Widget {
  Widget withErrorBoundary({
    ErrorPosition position = ErrorPosition.top,
    bool showAsSnackBar = false,
    Function(AppException)? onRetry,
    bool allowRetry = true,
  });
}
```

### ErrorPosition Enum

```dart
enum ErrorPosition {
  top,    // Banner displayed at top (default)
  bottom, // Banner displayed at bottom
}
```

### ErrorSeverity Enum

```dart
enum ErrorSeverity {
  info,       // Auto-dismiss after 10s
  warning,    // Auto-dismiss after 10s
  error,      // Manual dismiss only
  critical,   // Manual dismiss only
}
```

### ErrorStateNotifier Methods

#### addError()

Adds an error to the error state with optional severity.

```dart
void addError(
  AppException error, {
  bool autoDismiss = true,
  ErrorSeverity? severity,
})
```

**Parameters:**
- `error` - The exception to display
- `autoDismiss` - Whether to auto-dismiss (respects severity)
- `severity` - Optional explicit severity (auto-detected if not provided)

**Example:**

```dart
// Auto-detect severity
ref.read(errorStateProvider.notifier).addError(
  NetworkException(
    message: 'Network error',
    userMessage: 'Sin conexion.',
    isRetryable: true,
  ),
);

// Explicit severity
ref.read(errorStateProvider.notifier).addError(
  myError,
  severity: ErrorSeverity.critical,
);
```

#### removeError()

Removes a specific error from state.

```dart
void removeError(AppException error)
```

#### clearErrors()

Removes all errors from state.

```dart
void clearErrors()
```

---

## Testing Guide

### Manual Test Cases

#### Test 1: Critical Error (No Auto-Dismiss)

1. Trigger a critical error:
```dart
ref.read(errorStateProvider.notifier).addError(
  FirebasePermissionException(
    message: 'Permission denied',
    userMessage: 'No tienes permiso para realizar esta accion.',
  ),
);
```

2. Expected behavior:
   - Red error banner appears
   - Icon shows lock symbol
   - Text is white on red background
   - Banner stays visible indefinitely
   - Retry button not shown (non-retryable)
   - Dismiss button is visible and functional

#### Test 2: Warning Error (Auto-Dismiss)

1. Trigger a warning error:
```dart
ref.read(errorStateProvider.notifier).addError(
  NetworkException(
    message: 'Network timeout',
    userMessage: 'Sin conexion. Los cambios se guardaran localmente.',
    isRetryable: true,
  ),
);
```

2. Expected behavior:
   - Orange warning banner appears
   - Icon shows network symbol
   - Banner auto-dismisses after 10 seconds
   - Retry button appears and is functional
   - Dismiss button is visible and functional

#### Test 3: Info Error (Auto-Dismiss)

1. Trigger an info error:
```dart
ref.read(errorStateProvider.notifier).addError(
  ValidationException(
    message: 'Required field',
    userMessage: 'El campo titulo es obligatorio.',
  ),
);
```

2. Expected behavior:
   - Blue info banner appears
   - Icon shows info symbol
   - Banner auto-dismisses after 10 seconds
   - No retry button (validation errors don't retry)
   - Dismiss button is visible

#### Test 4: Manual Dismiss

1. Display any error banner
2. Tap the X (dismiss) button
3. Expected: Error disappears immediately

#### Test 5: Retry Action

1. Display a warning/error with retryable cause:
```dart
ref.read(errorStateProvider.notifier).addError(
  NetworkException(
    message: 'Network error',
    userMessage: 'Sin conexion.',
    isRetryable: true,
  ),
);
```

2. Tap [Reintentar] button
3. Expected: onRetry callback is executed with error as parameter

#### Test 6: SnackBar Mode

1. Create screen with `showAsSnackBar: true`:
```dart
ErrorBoundaryConsumer(
  showAsSnackBar: true,
  child: MyScreen(),
)
```

2. Trigger an error
3. Expected:
   - SnackBar appears at bottom instead of banner
   - Auto-dismisses based on severity
   - Retry and dismiss buttons work same as banner

#### Test 7: Bottom Position Banner

1. Create screen with `position: ErrorPosition.bottom`:
```dart
ErrorBoundaryConsumer(
  position: ErrorPosition.bottom,
  child: MyScreen(),
)
```

2. Trigger an error
3. Expected:
   - Banner appears at bottom of screen
   - Header and app content remain visible
   - All dismiss/retry functionality works normally

#### Test 8: Multiple Errors (showOnlyLatest = true)

1. Add three errors in sequence:
```dart
ref.read(errorStateProvider.notifier).addError(error1);
ref.read(errorStateProvider.notifier).addError(error2);
ref.read(errorStateProvider.notifier).addError(error3);
```

2. Expected:
   - Only error3 is displayed
   - When error3 is dismissed, error2 appears
   - When error2 is dismissed, error1 appears

#### Test 9: Multiple Errors (showOnlyLatest = false)

1. Create screen with `showOnlyLatest: false`
2. Add multiple errors
3. Expected: All errors displayed (implementation may vary)

#### Test 10: Custom Retry Handler

1. Create screen with custom onRetry:
```dart
ErrorBoundaryConsumer(
  onRetry: (error) {
    if (error is NetworkException) {
      print('Network retry!');
    }
  },
  child: MyScreen(),
)
```

2. Trigger network error and tap retry
3. Expected: Custom handler is called with error

### Automated Testing

Example test file structure:

```dart
void main() {
  group('ErrorBoundaryConsumer', () {
    testWidgets('Displays critical error with red background', (WidgetTester tester) async {
      // Test implementation
    });

    testWidgets('Auto-dismisses warning errors after 10s', (WidgetTester tester) async {
      // Test implementation
    });

    testWidgets('Manual dismiss removes error immediately', (WidgetTester tester) async {
      // Test implementation
    });

    testWidgets('Retry button executes onRetry callback', (WidgetTester tester) async {
      // Test implementation
    });

    testWidgets('SnackBar mode displays errors as snackbars', (WidgetTester tester) async {
      // Test implementation
    });
  });
}
```

---

## Troubleshooting

### Problem: Errors not showing

**Possible Causes:**
1. Widget is not a `ConsumerWidget` or `ConsumerStatefulWidget`
2. `ErrorBoundaryConsumer` not wrapping the screen
3. `errorStateProvider` not being watched

**Solution:**

```dart
// ❌ Wrong - StatelessWidget doesn't support Riverpod
class MyScreen extends StatelessWidget {
  @override
  Widget build(context) {
    return ErrorBoundaryConsumer(child: ...);
  }
}

// ✅ Correct - ConsumerWidget watches providers
class MyScreen extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    return ErrorBoundaryConsumer(child: ...);
  }
}
```

### Problem: Errors auto-dismissing when they shouldn't

**Possible Causes:**
1. Error marked as retryable when it shouldn't be
2. Wrong error type being used

**Solution:**

Check error properties:

```dart
// This auto-dismisses (warning severity)
NetworkException(
  message: 'Network error',
  userMessage: 'Sin conexion.',
  isRetryable: true,  // ← Makes it warning
)

// This stays visible (critical severity)
NetworkException(
  message: 'Network error',
  userMessage: 'Sin conexion.',
  isRetryable: false,  // ← Makes it critical
)
```

Or force severity explicitly:

```dart
ref.read(errorStateProvider.notifier).addError(
  myError,
  severity: ErrorSeverity.critical,  // Force critical
);
```

### Problem: Errors auto-dismissing when they shouldn't (continued)

**Check Retryability:**

```dart
// ❌ Auto-dismisses (retryable)
NetworkException(
  message: 'Timeout',
  userMessage: 'Connection timed out.',
  isRetryable: true,
)

// ✅ Stays visible (non-retryable)
NetworkException(
  message: 'Timeout',
  userMessage: 'Connection timed out.',
  isRetryable: false,
)
```

### Problem: Want to force specific severity

**Solution:**

Pass severity explicitly when adding error:

```dart
ref.read(errorStateProvider.notifier).addError(
  myError,
  severity: ErrorSeverity.critical,  // Override auto-detection
);
```

### Problem: Retry button not showing

**Possible Causes:**
1. Error is not retryable (`isRetryable = false`)
2. `allowRetry = false` on ErrorBoundaryConsumer
3. Error type doesn't support retry

**Solution:**

```dart
// Make error retryable
NetworkException(
  message: 'Network error',
  isRetryable: true,  // ← Enable retry
)

// Ensure allowRetry is true (default)
ErrorBoundaryConsumer(
  allowRetry: true,  // ← Default, explicitly shown
  child: MyScreen(),
)
```

### Problem: Retry button doesn't do anything

**Possible Causes:**
1. No `onRetry` handler provided
2. `onRetry` handler doesn't perform the retry

**Solution:**

Provide proper `onRetry` implementation:

```dart
ErrorBoundaryConsumer(
  onRetry: (error) {
    // Must perform actual retry operation
    if (error is NetworkException) {
      ref.refresh(tasksProvider);  // Refresh data
    } else if (error is SyncException) {
      ref.read(databaseServiceProvider).retrySyncQueue();
    }
  },
  child: MyScreen(),
)
```

### Problem: SnackBar appears but doesn't auto-dismiss

**Possible Causes:**
1. Error severity is critical or error (non-auto-dismiss)
2. `snackBarDuration` too short

**Solution:**

1. Check error severity - only info/warning auto-dismiss
2. Adjust duration:
```dart
ErrorBoundaryConsumer(
  showAsSnackBar: true,
  snackBarDuration: Duration(seconds: 8),  // Increase duration
  child: MyScreen(),
)
```

### Problem: Can't find error types/exceptions

**Location:**
- Exception definitions: `lib/core/exceptions/app_exceptions.dart`
- Error provider: `lib/providers/error_provider.dart`
- Consumer widget: `lib/widgets/error_boundary_consumer.dart`

### Problem: Combining with other error handling

**Solution:**

Use both ErrorBoundary and ErrorBoundaryConsumer:

```dart
ErrorBoundary(  // Catches widget build errors
  child: ErrorBoundaryConsumer(  // Shows provider errors
    child: MyScreen(),
  ),
)
```

### Problem: Text not appearing in Spanish

**Check:**
1. Error messages use Spanish text in `userMessage` field
2. Button labels are hardcoded in Spanish in widget

**Solution:**

Ensure exceptions pass Spanish messages:

```dart
NetworkException(
  message: 'Network timeout',  // English (internal)
  userMessage: 'Sin conexion. Reintentando...',  // Spanish (user-facing)
)
```

### Problem: Colors don't match design system

**Check:**
1. Material 3 color scheme is configured
2. No custom color overrides

**Solution:**

Verify Material 3 theme colors are properly defined in your `ThemeData`:

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
  ),
)
```

---

## Best Practices

### Do's

✅ **Do wrap critical screens** - Always use ErrorBoundaryConsumer on screens with important operations

✅ **Do provide meaningful messages** - Write clear, actionable error messages in Spanish

✅ **Do use custom retry handlers** - Implement specific retry logic for your screen's operations

✅ **Do test error scenarios** - Simulate errors during development to verify display

✅ **Do consider severity** - Think about whether an error needs immediate user attention

✅ **Do use extension method** for quick integration:
```dart
Scaffold(...).withErrorBoundary()
```

### Don'ts

❌ **Don't wrap deeply nested widgets** - Wrap at screen level, not inside content

❌ **Don't create multiple boundaries on same screen** - One ErrorBoundaryConsumer per screen is sufficient

❌ **Don't ignore critical errors** - Never mark critical operations as non-retryable dismissible

❌ **Don't override severity without reason** - Let auto-detection handle it

❌ **Don't create screens with StatelessWidget** - Use ConsumerWidget for Riverpod integration

### Integration Checklist

When adding ErrorBoundaryConsumer to a new screen:

- [ ] Import `error_boundary_consumer.dart`
- [ ] Change to `ConsumerWidget` or `ConsumerStatefulWidget`
- [ ] Wrap entire `Scaffold` with `ErrorBoundaryConsumer`
- [ ] Choose display mode (banner vs SnackBar)
- [ ] Add custom `onRetry` if needed
- [ ] Test with simulated errors
- [ ] Verify critical errors stay visible
- [ ] Verify warnings auto-dismiss
- [ ] Check Spanish text in messages

---

## Summary

The Error Handling Architecture provides:

- **Severity-based auto-dismiss logic** - Critical errors stay visible, minor errors auto-dismiss
- **Error boundary consumer widget** - Easy integration with flexible configuration
- **Color-coded display** - Material 3 design with clear visual hierarchy
- **Automatic error classification** - Smart severity detection based on error type
- **Customizable retry behavior** - Per-screen retry logic
- **Spanish UI text** - All user-facing text in Spanish
- **Backward compatibility** - Works with existing error handling

For implementation support, refer to:
- Example code: `lib/widgets/examples/error_boundary_example.dart`
- Exception types: `lib/core/exceptions/app_exceptions.dart`
- Error provider: `lib/providers/error_provider.dart`
- Consumer widget: `lib/widgets/error_boundary_consumer.dart`
