# Contributing to AuraList

Thank you for your interest in contributing to AuraList! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

1. [Getting Started](#getting-started)
2. [Development Workflow](#development-workflow)
3. [Code Style](#code-style)
4. [Testing](#testing)
5. [Documentation](#documentation)
6. [Submitting Changes](#submitting-changes)

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.19+ ([install](https://flutter.dev/docs/get-started/install))
- **Dart SDK** 3.3+ (included with Flutter)
- **Git** for version control
- **IDE**: VS Code or Android Studio (recommended)

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/your-username/auralist.git
cd auralist

# Install dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test
```

### Project Structure

```
lib/
├── models/          # Hive data models
├── providers/       # Riverpod providers
├── screens/        # App screens
├── services/       # Business logic (database, auth)
└── widgets/        # Reusable widgets

docs/               # Documentation
test/              # Test files
assets/            # Images, fonts, etc.
```

For complete details, see [CLAUDE.md](./CLAUDE.md).

---

## 🔄 Development Workflow

### Branch Naming

- **Features:** `feature/feature-name`
- **Bug fixes:** `fix/bug-description`
- **Documentation:** `docs/what-changed`
- **Refactoring:** `refactor/area-name`

### Example Workflow

```bash
# Create feature branch
git checkout -b feature/add-dark-mode

# Make changes and commit
git add .
git commit -m "feat: Add dark mode toggle"

# Push and create pull request
git push origin feature/add-dark-mode
```

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(guides): Add new guide character Luna-Vacía
fix(sync): Resolve offline sync queue issue
docs(avatars): Update generation guide with ComfyUI instructions
refactor(providers): Simplify task provider logic
```

---

## 🎨 Code Style

### Dart/Flutter Conventions

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

```dart
// Good: Clear naming, proper formatting
class TaskProvider extends StateNotifier<List<Task>> {
  TaskProvider() : super([]);

  void addTask(Task task) {
    state = [...state, task];
  }
}

// Bad: Unclear naming, poor formatting
class TP extends StateNotifier<List<Task>> {
TP():super([]);
void a(Task t){state=[...state,t];}}
```

### Formatting

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Apply suggested fixes
dart fix --apply
```

### Widget Structure

- **Prefer ConsumerWidget** over StatelessWidget for Riverpod integration
- **Extract widgets** when they exceed ~100 lines
- **Use const** constructors where possible
- **Avoid nesting** beyond 3-4 levels

```dart
// Good: Flat structure with extracted widgets
class TaskScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _TaskList(),
      floatingActionButton: _AddTaskButton(),
    );
  }
}

// Bad: Deep nesting
class TaskScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: [
            Container(
              child: Row(
                children: [
                  // Too deep...
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/providers/task_provider_test.dart

# Run tests with coverage
flutter test --coverage
```

### Writing Tests

```dart
// providers/task_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('TaskProvider', () {
    test('should add task to state', () {
      final container = ProviderContainer();
      final provider = container.read(taskProviderProvider.notifier);

      final task = Task(id: '1', title: 'Test task');
      provider.addTask(task);

      expect(
        container.read(taskProviderProvider),
        contains(task),
      );
    });
  });
}
```

### Test Coverage

- **Unit tests:** Test individual functions and classes
- **Widget tests:** Test widget rendering and interactions
- **Integration tests:** Test complete user flows

Aim for **>80% coverage** for critical paths.

---

## 📚 Documentation

### When to Document

- **New features:** Create/update relevant docs
- **API changes:** Update API reference
- **Bug fixes:** Add to troubleshooting if applicable
- **Architecture changes:** Update architecture docs

### Documentation Structure

- **Root:** Only README.md, CLAUDE.md, CONTRIBUTING.md
- **docs/features/:** Feature-specific guides
- **docs/architecture/:** Technical design docs
- **docs/development/:** Development guides

See [docs/README.md](./docs/README.md) for complete structure.

### Inline Documentation

```dart
/// Adds a new task to the user's task list.
///
/// The task is first saved to local Hive storage, then synced
/// to Firebase if the user is authenticated. If Firebase sync
/// fails, the task is queued for retry.
///
/// Parameters:
///   - [task]: The task to add
///
/// Throws:
///   - [DatabaseException]: If local save fails
///
/// Example:
/// ```dart
/// await databaseService.addTask(
///   Task(title: 'Buy groceries', type: 'daily'),
/// );
/// ```
Future<void> addTask(Task task) async {
  // Implementation...
}
```

---

## 🚀 Submitting Changes

### Pull Request Process

1. **Update documentation** for any user-facing changes
2. **Add tests** for new functionality
3. **Run all tests** and ensure they pass
4. **Format code** with `dart format .`
5. **Create pull request** with clear description

### PR Description Template

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How this was tested

## Screenshots (if applicable)
Visual changes

## Checklist
- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests passing
- [ ] No breaking changes (or documented if yes)
```

### Review Process

1. **Automated checks** run (tests, linting)
2. **Code review** by maintainers
3. **Requested changes** addressed
4. **Merge** when approved

---

## 🌐 Localization

AuraList is primarily in Spanish. When adding user-facing text:

1. **Add Spanish text directly** in widgets
2. **Document English translation** in comments
3. **Consider i18n** for multi-language support in future

```dart
// Good: Spanish with English comment
Text('Tareas Pendientes'), // "Pending Tasks"

// Future: Using i18n
Text(AppLocalizations.of(context).pendingTasks)
```

---

## 🎨 Design Guidelines

### UI/UX Principles

- **Simple and calming** - Reduce cognitive load
- **Celebrate progress** - Positive reinforcement without anxiety
- **Offline-first** - Works seamlessly without connection
- **Respect attention** - Minimal notifications and interruptions

### Color Palette

Follow Material 3 design with custom guide colors:

```dart
// Example guide colors
static const lunaVacia = Color(0xFF4A148C);  // Deep purple
static const helioforja = Color(0xFF8B2500); // Crimson
static const leonaNova = Color(0xFFB8860B);  // Gold
```

---

## 🐛 Bug Reports

### Before Submitting

1. **Search existing issues** - May already be reported
2. **Test on latest version** - Bug may be fixed
3. **Isolate the problem** - Minimal reproduction steps

### Bug Report Template

```markdown
**Describe the bug**
Clear description of what the bug is

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen

**Screenshots**
If applicable

**Environment**
- Device: [e.g. Pixel 6]
- OS: [e.g. Android 13]
- App Version: [e.g. 1.2.0]

**Additional context**
Any other relevant information
```

---

## 💡 Feature Requests

Use [Improvements Roadmap](./docs/development/IMPROVEMENTS_ROADMAP.md) to:

1. **Check existing requests** - May already be planned
2. **Describe use case** - Why this feature is needed
3. **Propose solution** - How you envision it working

---

## 📞 Getting Help

- **Development questions:** See [CLAUDE.md](./CLAUDE.md)
- **Documentation:** Check [docs/README.md](./docs/README.md)
- **Community:** Open a discussion
- **Urgent issues:** Open an issue with `[urgent]` tag

---

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

## 🙏 Thank You!

Your contributions make AuraList better for everyone. We appreciate your time and effort!

**Happy coding! 🚀**
