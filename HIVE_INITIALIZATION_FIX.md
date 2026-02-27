# Hive Box Opening Sequence Fix

## Problem

The finance module was experiencing race conditions during Hive box initialization, causing errors like "Box not found" or "Box has not been registered". The issue occurred because:

1. **TypeAdapters were registered correctly** in `DatabaseService.init()` (lines 176-219)
2. **However, finance boxes were NEVER opened centrally** - they were only opened lazily when first accessed
3. **Race condition occurred** when multiple storage classes tried to open their boxes simultaneously on first app load
4. **No coordination** existed between the different finance storage initialization sequences

## Root Cause

The finance module has 7 separate Hive storage classes:

1. `CategoryStorage` - box: `finance_categories`
2. `TransactionStorage` - box: `finance_transactions`
3. `RecurringTransactionStorage` - box: `finance_recurring_transactions`
4. `BudgetStorage` - box: `finance_budgets`
5. `CashFlowProjectionStorage` - box: `finance_cash_flow_projections`
6. `FinanceAlertStorage` - box: `finance_alerts`
7. `TaskFinanceLinkStorage` - box: `finance_task_links`

Each storage class had its own `init()` method that would try to open its box lazily:

```dart
Future<void> init() async {
  if (_initialized && _box != null && _box!.isOpen) return;
  try {
    _box = Hive.isBoxOpen(boxName)
        ? Hive.box<Type>(boxName)
        : await Hive.openBox<Type>(boxName);  // <-- Race condition here!
    _initialized = true;
  } catch (e, stack) {
    _errorHandler.handle(e, type: ErrorType.database, stackTrace: stack);
  }
}
```

When the finance screen loads and multiple providers are accessed simultaneously:
- All 7 storage classes call `init()` at roughly the same time
- Multiple `Hive.openBox()` calls execute in parallel
- Hive's internal state gets corrupted
- Some boxes fail to open, causing "Box not found" errors

## Solution

### What Was Fixed

Added centralized finance box initialization in `DatabaseService.init()`:

**File: `lib/services/database_service.dart`**

1. **Added `_initializeFinanceBoxes()` helper method** (lines 277-319):
   - Opens all 7 finance boxes sequentially
   - Runs AFTER TypeAdapters are registered
   - Runs BEFORE DatabaseService is marked as initialized
   - Includes error handling for individual box failures
   - Logs each box opening for debugging

2. **Called during DatabaseService initialization** (line 232):
   - Placed after Hive.initFlutter()
   - Placed after TypeAdapter registration
   - Placed after core boxes (history, user_prefs) are opened
   - Placed before Firebase availability check
   - Placed before repository initialization

### Code Changes

#### Change 1: Added finance box initialization call

```dart
// Open boxes managed directly by DatabaseService
_historyBox = Hive.isBoxOpen(_historyBoxName)
    ? Hive.box<TaskHistory>(_historyBoxName)
    : await Hive.openBox<TaskHistory>(_historyBoxName);
_userPrefsBox = Hive.isBoxOpen(_userPrefsBoxName)
    ? Hive.box<UserPreferences>(_userPrefsBoxName)
    : await Hive.openBox<UserPreferences>(_userPrefsBoxName);

// Open all finance boxes to prevent race conditions
// These must be opened AFTER TypeAdapters are registered
await _initializeFinanceBoxes();  // <-- NEW

// Check if Firebase is available
```

#### Change 2: Added helper method

```dart
/// Initialize all finance boxes in the correct order
/// This prevents race conditions when multiple storage classes try to open boxes simultaneously
Future<void> _initializeFinanceBoxes() async {
  try {
    _logger.debug('Service', '[DatabaseService] Initializing finance boxes...');

    // Open all finance boxes in order
    final financeBoxes = [
      'finance_categories',
      'finance_transactions',
      'finance_recurring_transactions',
      'finance_budgets',
      'finance_cash_flow_projections',
      'finance_alerts',
      'finance_task_links',
    ];

    for (final boxName in financeBoxes) {
      if (!Hive.isBoxOpen(boxName)) {
        try {
          await Hive.openBox(boxName);
          _logger.debug('Service', '[DatabaseService] Opened finance box: $boxName');
        } catch (e) {
          _logger.warning(
            'DatabaseService',
            'Error opening finance box $boxName: $e',
          );
          // Continue with other boxes even if one fails
        }
      }
    }

    _logger.debug('Service', '[DatabaseService] Finance boxes initialized');
  } catch (e, stack) {
    _errorHandler.handle(
      e,
      type: ErrorType.database,
      severity: ErrorSeverity.warning,
      message: 'Error initializing finance boxes',
      stackTrace: stack,
    );
  }
}
```

## Initialization Sequence

The correct initialization order is now:

```
1. Hive.initFlutter()
2. Register ALL TypeAdapters (Task, Note, Notebook, Finance types, etc.)
3. Open core boxes (task_history, user_prefs)
4. Open ALL finance boxes (NEW - prevents race conditions)
5. Check Firebase availability
6. Initialize repositories (task, note, notebook)
7. Mark DatabaseService as initialized
8. Run integrity check
9. Run migrations
```

## Benefits

1. **Eliminates race conditions**: All boxes are opened sequentially before any storage class tries to access them
2. **Predictable initialization**: Clear, deterministic order of operations
3. **Better error handling**: Individual box failures don't crash the entire initialization
4. **Improved debugging**: Detailed logging shows exactly which boxes are opened and when
5. **No changes to storage classes**: The existing lazy initialization in storage classes still works as a backup
6. **Future-proof**: Easy to add new finance boxes by adding their name to the array

## Testing

To verify the fix:

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```

2. **Run the app**:
   ```bash
   flutter run -d windows  # or chrome, android, etc.
   ```

3. **Check logs**: Look for these messages in order:
   ```
   [DatabaseService] Initializing finance boxes...
   [DatabaseService] Opened finance box: finance_categories
   [DatabaseService] Opened finance box: finance_transactions
   [DatabaseService] Opened finance box: finance_recurring_transactions
   [DatabaseService] Opened finance box: finance_budgets
   [DatabaseService] Opened finance box: finance_cash_flow_projections
   [DatabaseService] Opened finance box: finance_alerts
   [DatabaseService] Opened finance box: finance_task_links
   [DatabaseService] Finance boxes initialized
   [DatabaseService] Initialized with repositories
   ```

4. **Navigate to finance screen**: Should load without any "Box not found" errors

## Files Modified

- **`lib/services/database_service.dart`**:
  - Line 232: Added call to `_initializeFinanceBoxes()`
  - Lines 277-319: Added `_initializeFinanceBoxes()` method

## Related Files (No Changes Required)

These files now benefit from the centralized initialization but don't require modifications:

- `lib/features/finance/data/category_storage.dart`
- `lib/features/finance/data/transaction_storage.dart`
- `lib/features/finance/data/recurring_transaction_storage.dart`
- `lib/features/finance/data/budget_storage.dart`
- `lib/features/finance/data/cash_flow_projection_storage.dart`
- `lib/features/finance/data/finance_alert_storage.dart`
- `lib/features/finance/data/task_finance_link_storage.dart`

## Future Considerations

If adding new finance storage classes:

1. Create the storage class with standard lazy initialization
2. Register the TypeAdapter in `DatabaseService.init()` (if needed)
3. Add the box name to the `financeBoxes` array in `_initializeFinanceBoxes()`

That's it! The centralized initialization will handle the rest.
