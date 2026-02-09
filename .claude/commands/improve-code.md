# /improve-code - Code Quality Agent

Review and improve code architecture, patterns, and maintainability.

## Instructions

1. **Architecture Review**
   - Separation of concerns (UI / Business Logic / Data)
   - Dependency injection patterns
   - Single responsibility principle
   - Module boundaries

2. **State Management Audit**
   - Riverpod best practices
   - Avoid unnecessary rebuilds
   - Proper disposal of resources
   - State immutability

3. **Error Handling**
   - Comprehensive try-catch coverage
   - User-friendly error messages
   - Error recovery strategies
   - Logging for debugging

4. **Performance Review**
   - Widget rebuild optimization
   - List performance (ListView.builder)
   - Image optimization
   - Lazy loading

5. **Code Patterns**
   ```dart
   // Check for:
   - Const constructors where possible
   - Proper widget keys
   - Avoiding BuildContext across async gaps
   - Disposing controllers
   ```

6. **Test Coverage**
   - Unit tests for models and services
   - Widget tests for UI components
   - Integration tests for flows
   - Identify untested critical paths

7. **Security Review**
   - Secure storage of sensitive data
   - Input validation
   - Firebase security rules
   - No hardcoded secrets

## Output
Provide specific refactoring suggestions with before/after code examples.
