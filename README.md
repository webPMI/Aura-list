# AuraList

A powerful offline-first task management app with optional cloud sync, built with Flutter and Firebase.

## Features

### Task Management
- **Multi-platform**: Android, iOS, Windows, and Web (PWA)
- **Offline-first**: All data stored locally with Hive, works without internet
- **Cloud sync**: Optional real-time sync via Firebase Firestore
- **Task organization**: Daily, Weekly, Monthly, Yearly, and One-time tasks
- **Notes system**: Rich notes with checklists, tags, and color coding
- **Motivation tracking**: Add personal motivation and rewards to tasks
- **Anonymous auth**: Simple Firebase authentication with graceful degradation

### Finance Management (New in v2.0)
- **Transaction tracking**: Record income and expenses with categories
- **Recurring transactions**: Automatically generate periodic transactions
- **Smart budgets**: Set spending limits with customizable alerts (80%, 90%, 100%)
- **Budget rollover**: Transfer unused budget to next period
- **Cash flow projections**: Forecast future balance based on patterns
- **Financial alerts**: Get notified about budget status and unusual spending
- **Task-finance integration**: Link financial impact to tasks with ROI tracking
- **Pattern detection**: Automatically identify recurring expenses from history

All finance features are optional and work seamlessly with the offline-first architecture.

## Quick Start: Finance Features

```dart
// 1. Add a transaction
await ref.read(financeProvider.notifier).addTransaction(
  title: 'Grocery shopping',
  amount: 75.50,
  date: DateTime.now(),
  categoryId: 'exp_food',
  type: FinanceCategoryType.expense,
);

// 2. Create a recurring transaction (e.g., monthly salary)
final recurring = RecurringTransaction(
  title: 'Monthly Salary',
  amount: 3000.0,
  categoryId: 'inc_salary',
  type: FinanceCategoryType.income,
  recurrence: RecurrenceRule(
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    dayOfMonth: 1,
  ),
  autoGenerate: true,
);

// 3. Set up a budget with alerts
final budget = Budget(
  name: 'Food Budget',
  categoryId: 'exp_food',
  limit: 500.0,
  period: BudgetPeriod.monthly,
  alertThreshold: 0.8, // Alert at 80%
  rollover: true,
);

// 4. Link task with financial impact
final task = Task(
  title: 'Car maintenance',
  financialCost: 150.0,
  financialCategoryId: 'exp_transport',
  autoGenerateTransaction: true, // Auto-create transaction when completed
);
```

See [Finance System Documentation](docs/finance-system.md) for complete examples.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (multi-platform)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Local Storage**: [Hive](https://docs.hivedb.dev) (offline-first)
- **Backend**: [Firebase](https://firebase.google.com) (Auth & Firestore, optional)
- **Design**: Material Design 3

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later)
- Dart SDK
- Firebase CLI (optional, for web deployment)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Hive adapters:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   ```bash
   flutter run                # Default device
   flutter run -d chrome      # Web
   flutter run -d windows     # Windows
   ```

### Firebase Setup (Optional)

Firebase is optional. The app works fully offline without it.

To enable cloud sync:
1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Firebase config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Web/Desktop: `lib/firebase_options.dart`
3. Run `flutterfire configure` (or configure manually)

## Project Structure

```
lib/
├── models/              # Hive data models (Task, Note, Notebook, etc.)
├── features/
│   └── finance/         # Finance system (transactions, budgets, projections)
│       ├── models/      # Finance data models
│       ├── providers/   # Finance state management
│       ├── services/    # Finance business logic
│       ├── screens/     # Finance UI screens
│       ├── widgets/     # Finance UI components
│       ├── data/        # Local & cloud storage
│       └── repositories/# Data coordination layer
├── services/            # Business logic (DatabaseService, AuthService)
├── providers/           # Riverpod state management
├── screens/             # Main UI screens
├── widgets/             # Reusable UI components
└── core/               # Utilities and platform detection
```

## Build Commands

```bash
# Development
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run                    # Android/iOS

# Release builds
flutter build apk --release --split-per-abi   # Android APK
flutter build appbundle --release             # Android AAB (Play Store)
flutter build windows --release               # Windows
flutter build web --release                   # Web PWA
flutter build ipa --release                   # iOS (Mac only)

# Code quality
flutter analyze                # Static analysis
flutter test                   # Run tests
dart fix --apply               # Auto-fix issues
```

## Documentation

### Core Documentation
- **[CLAUDE.md](CLAUDE.md)** - Development guide for Claude Code
  - Architecture patterns
  - Development commands
  - Slash commands (skills)
  - Build configuration

### Feature Documentation
- **[Finance System](docs/finance-system.md)** - Complete finance system documentation
  - Data models and architecture
  - API reference and examples
  - Integration with tasks
  - Best practices

### Migration & Updates
- **[Migration Guide](docs/MIGRATION_GUIDE.md)** - Upgrade guide to v2.0
  - Breaking changes
  - TypeId assignments
  - Update procedures
  - Troubleshooting

## Design Philosophy

AuraList helps people accomplish what matters without adding stress:
- **Reduce cognitive load** - Simple, clear organization
- **Celebrate progress** - Positive reinforcement, not anxiety
- **Work offline** - All features available without internet
- **Respect attention** - No spam notifications or manipulation

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**AuraList** - Transform your tasks into victories
