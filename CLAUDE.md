# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters (required after model changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run                    # Default device
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop

# Build for release
flutter build apk              # Android APK
flutter build web              # Web app
flutter build windows          # Windows executable

# Code quality
flutter analyze                # Static analysis
flutter test                   # Run tests
dart fix --apply               # Auto-fix issues
```

## Architecture Overview

**AuraList** is an offline-first task management app with optional Firebase cloud sync.

### Data Flow

```
UI (ConsumerWidget) ← watches ← Riverpod Providers ← streams ← Hive (local)
                                       ↓
                              Firebase Firestore (async sync)
                                       ↓
                              Sync Queue (retry on failure)
```

### Key Patterns

**Offline-First Strategy:**
- Tasks saved to Hive immediately (optimistic updates)
- UI updates via `Box.watch()` streams through Riverpod
- Firebase sync happens asynchronously after local save
- Failed syncs queued in separate Hive box with exponential backoff retry (3 attempts: 2s, 4s, 6s)
- App functions fully without Firebase connection

**Provider Structure:**
- `tasksProvider(type)` - Family provider, one per task type ('daily', 'weekly', 'monthly', 'yearly', 'once')
- `themeProvider` - Persists theme mode to SharedPreferences
- `databaseServiceProvider` - Singleton for Hive/Firebase operations
- `authServiceProvider` - Firebase anonymous auth with graceful degradation

### Task Model (Hive typeId: 0)

Key fields:
- `type`: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'once'
- `priority`: 0 (Low), 1 (Medium), 2 (High)
- `category`: 'Personal' | 'Trabajo' | 'Hogar' | 'Salud' | 'Otros'
- `dueTimeMinutes`: Minutes since midnight (0-1439) for time-based tasks
- `deadline`: Hard deadline (distinct from suggested dueDate)
- `motivation`: Why accomplish this task
- `reward`: Prize text shown on completion
- `firestoreId`: Cloud document ID (null if not synced)

### Services

- **DatabaseService**: Hive CRUD + Firebase sync + sync queue management
- **AuthService**: Firebase anonymous auth, auth state stream
- **ErrorHandler**: Singleton for classified error handling (database/network/auth/validation)

## Code Conventions

- **Widgets**: Extend `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod
- **Models**: Hive annotations + `copyWith()` method + `toFirestore()`/`fromFirestore()` factories
- **Providers**: `StateNotifierProvider` for stateful logic, watch Hive streams
- **Localization**: All UI text in Spanish

## Slash Commands (Claude Code Skills)

### Development
- `/build [platform]` - Build for apk, web, windows, ios
- `/run [device]` - Run in debug mode
- `/clean` - flutter clean + pub get + build_runner
- `/generate` - Run build_runner for Hive adapters
- `/analyze` - Static analysis
- `/test [file]` - Run tests

### Scaffolding
- `/widget Name` - Create widget in lib/widgets/
- `/provider name` - Create Riverpod provider in lib/providers/
- `/model Name` - Create Hive model in lib/models/
- `/screen Name` - Create screen in lib/screens/
- `/service Name` - Create service in lib/services/

### Improvement System
- `/init` - Orchestrate agents to analyze and suggest improvements
- `/improve-ux` - UX/UI analysis
- `/improve-features` - Productivity features
- `/improve-wellbeing` - User wellbeing features
- `/improve-a11y` - Accessibility audit
- `/improve-code` - Code quality review
- `/roadmap` - View/manage improvement roadmap
- `/implement [id]` - Implement a specific improvement

## Firebase Configuration

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Dart config: `lib/firebase_options.dart`

Firebase is optional - the app gracefully degrades to local-only mode if unavailable.

## Design Philosophy

This app helps people accomplish what matters without adding stress. Every feature should:
- Reduce cognitive load
- Celebrate progress without creating anxiety
- Work offline seamlessly
- Respect users' time and attention
