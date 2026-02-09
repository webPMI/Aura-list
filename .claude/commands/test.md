# /test - Run Tests

Run the test suite for the checklist app.

## Arguments
- `$ARGUMENTS` - Specific test file or directory (optional)

## Instructions

1. If `$ARGUMENTS` provided, run `flutter test $ARGUMENTS`
2. Otherwise run `flutter test` for all tests
3. Parse test results and report:
   - Total tests run
   - Passed/Failed/Skipped counts
   - Details of any failures with file locations
4. For failures, analyze the error and suggest fixes
