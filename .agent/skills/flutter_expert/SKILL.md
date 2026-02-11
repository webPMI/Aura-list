---
name: Flutter Expert
description: Expert guidance for Flutter development in the AuraList project.
---

# Flutter Expert Skill

This skill provides expert guidance for developing and maintaining the AuraList Flutter application.

## Core Principles
- **Clean Architecture**: Maintain separation of concerns between UI, providers, and services.
- **Riverpod for State Management**: Use `ConsumerWidget`, `ConsumerStatefulWidget`, and appropriate providers.
- **Responsive Design**: Always use the `Breakpoints` class and `ResponsiveExtension` on `BuildContext`.
- **Material 3**: Follow Material 3 design guidelines and use `ColorScheme` from the theme.

## Best Practices

### 1. UI Components
- Use `AdaptiveNavigation` for main navigation.
- Keep widgets small and focused.
- Prefer `const` constructors where possible.
- Use `Gap` or `SizedBox` for spacing instead of generic margins in simple layouts.

### 2. State Management (Riverpod)
- Use `Provider` for services and static logic.
- Use `StateProvider` for simple states.
- Use `FutureProvider` or `StreamProvider` for asynchronous data.
- Use `NotifierProvider` for complex state logic.

### 3. Error Handling
- Use the centralized `ErrorHandler` for all operations.
- Wrap critical operations in `handleErrors()` extension on `Future`.
- Provide user-friendly messages in Spanish.

### 4. Code Style
- Follow Dart's official lint rules (managed by `analysis_options.yaml`).
- Use informative variable and method names in English (internal) but messages in Spanish (UI).
- Keep formatting consistent using `flutter format`.

## Useful Commands
- `flutter analyze`: Check for lint errors.
- `flutter test`: Run all unit and widget tests.
- `flutter run`: Run the application.
- `flutter pub get`: Update dependencies.
