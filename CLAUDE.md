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

### Data Models (Hive TypeIds)

**Task Model (typeId: 0)**
- `type`: 'daily' | 'weekly' | 'monthly' | 'yearly' | 'once'
- `priority`: 0 (Low), 1 (Medium), 2 (High)
- `category`: 'Personal' | 'Trabajo' | 'Hogar' | 'Salud' | 'Otros'
- `dueTimeMinutes`: Minutes since midnight (0-1439) for time-based tasks
- `deadline`: Hard deadline (distinct from suggested dueDate)
- `motivation`: Why accomplish this task
- `reward`: Prize text shown on completion
- `firestoreId`: Cloud document ID (null if not synced)

**Note Model (typeId: 2)**
- `checklist`: List of ChecklistItem for task-based notes

**Notebook Model (typeId: 3)**
- Organizes notes hierarchically

**ChecklistItem (typeId: 4)**
- `id`, `text`, `isCompleted`, `order`
- Used within Note.checklist field

**Finance Models (typeIds: 14-27)**
- **FinanceCategory (typeId: 14)** - Income/expense categories with icons and colors
- **CategoryType (typeId: 15)** - Enum: 'expense' | 'income'
- **Transaction (typeId: 16)** - Financial transactions
- **RecurringTransaction (typeId: 17-21)** - Auto-repeating transactions with various frequencies
- **Budget (typeId: 22)** - Category budgets with spending limits and alerts
- **CashFlowProjection (typeId: 23-24)** - Future balance predictions based on patterns
- **TaskFinanceLink (typeId: 25)** - Links tasks to transactions for ROI tracking
- **FinanceAlert (typeId: 26-27)** - Budget overspend and anomaly detection alerts

### Services

- **DatabaseService**: Hive CRUD + Firebase sync + sync queue management
- **AuthService**: Firebase anonymous auth, auth state stream
- **ErrorHandler**: Singleton for classified error handling (database/network/auth/validation)
- **RecurringTransactionService**: Manages recurring financial transactions with pattern detection

### Key Dependencies

- **uuid (^4.5.1)**: Generates unique identifiers for transactions and entities
- **hive (^2.2.3)**: Local NoSQL database for offline-first storage
- **firebase_core/auth/firestore**: Optional cloud sync and authentication
- **flutter_riverpod (^2.6.1)**: State management with reactive streams
- **shared_preferences (^2.2.2)**: Persistent key-value storage for settings

## Finance Features

AuraList includes a comprehensive finance management system with:

**Recurring Transactions**
- Automatically repeat transactions on schedules (daily, weekly, monthly, yearly)
- Configurable start/end dates and occurrence limits
- Active/inactive toggle for temporary suspension
- Syncs with Firebase for cross-device consistency

**Budgets**
- Set spending limits per category and time period (weekly, monthly, yearly)
- Real-time tracking of budget utilization percentage
- Automatic alerts when approaching or exceeding limits
- Rollover options for unused budget amounts

**Cash Flow Projections**
- AI-powered predictions of future account balance
- Based on recurring transactions and spending patterns
- Configurable projection periods (1-12 months)
- Confidence scores for reliability assessment

**Task-Finance Integration**
- Link tasks to transactions for ROI tracking
- Visualize financial impact of completing tasks
- Calculate cost-benefit ratios for decision support
- Track rewards and investments tied to goals

**Smart Alerts**
- Budget overspend warnings with customizable thresholds
- Anomaly detection for unusual spending patterns
- Missed recurring transaction notifications
- Low balance predictions based on projections

**Usage Examples:**
```dart
// Create a recurring transaction
final recurring = RecurringTransaction(
  title: 'Monthly Rent',
  amount: 1200.0,
  categoryId: 'housing',
  frequency: RecurrenceFrequency.monthly,
  nextOccurrence: DateTime(2026, 3, 1),
);

// Set a budget
final budget = Budget(
  categoryId: 'food',
  amount: 500.0,
  period: BudgetPeriod.monthly,
  alertThreshold: 0.8, // Alert at 80%
);

// Link task to transaction
final link = TaskFinanceLink(
  taskId: task.id,
  transactionId: transaction.id,
  relationship: 'reward', // or 'cost', 'investment'
);
```

## Code Conventions

- **Widgets**: Extend `ConsumerWidget` or `ConsumerStatefulWidget` for Riverpod
- **Models**: Hive annotations + `copyWith()` method + `toFirestore()`/`fromFirestore()` factories
- **Providers**: `StateNotifierProvider` for stateful logic, watch Hive streams
- **Localization**: All UI text in Spanish

## Documentation

Complete documentation is organized in `docs/`:

- **[docs/README.md](docs/README.md)** - Documentation navigation hub
- **[docs/features/avatars/](docs/features/avatars/)** - Avatar generation system
- **[docs/features/guides/](docs/features/guides/)** - Guide character documentation
- **[docs/architecture/](docs/architecture/)** - Technical architecture
- **[docs/development/](docs/development/)** - Development guides
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines

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

### Deploying Firebase Security Rules and Indexes

**Deploy Firestore Security Rules:**
```bash
# Deploy security rules to Firebase
firebase deploy --only firestore:rules
```

**Deploy Firestore Indexes:**
```bash
# Deploy composite indexes to Firebase
firebase deploy --only firestore:indexes
```

**Deploy Both at Once:**
```bash
# Deploy rules and indexes together
firebase deploy --only firestore
```

**Important Notes:**
- Security rules are defined in `firestore.rules`
- Composite indexes are defined in `firestore.indexes.json`
- Always test rules in the Firebase Console before deploying to production
- Index creation can take several minutes after deployment
- The app includes sharing features for budgets and recurring transactions via the `sharedWith` array in user documents

## Release Build Setup (Critical)

### Android Release Configuration

1. **Generate keystore** (one-time):
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. **Create `android/key.properties`**:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

3. **Update applicationId** in `android/app/build.gradle.kts`:
```kotlin
applicationId = "com.inkenzo.auralist"  // Change from com.example
```

4. **Build**:
```bash
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

### Windows Release

Requires Visual Studio 2022 with "Desktop development with C++" workload.

```bash
flutter build windows --release
```

### iOS Release

Requires:
- Mac with Xcode
- Apple Developer Account ($99/year)
- Bundle ID configured in Xcode
- Code signing configured

```bash
flutter build ipa --release
```

## Design Philosophy

This app helps people accomplish what matters without adding stress. Every feature should:
- Reduce cognitive load
- Celebrate progress without creating anxiety
- Work offline seamlessly
- Respect users' time and attention
