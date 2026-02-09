# /fix - Auto-fix Code Issues

Automatically fix common code issues in the project.

## Arguments
- `$ARGUMENTS` - Scope: `all`, `imports`, `format`, or specific file path

## Instructions

1. Run `dart fix --apply` to apply automatic fixes
2. Run `dart format .` to format all Dart files
3. Run `flutter analyze` to check remaining issues
4. Report:
   - Number of files modified
   - Issues fixed automatically
   - Remaining issues that need manual attention

## Specific fixes:
- `imports` - Organize and remove unused imports
- `format` - Format code only (dart format)
- File path - Fix only the specified file
