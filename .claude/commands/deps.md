# /deps - Manage Dependencies

Check and update project dependencies.

## Arguments
- `$ARGUMENTS` - Action: `check`, `update`, `add {package}`, `remove {package}`

## Instructions

### For `check` or no argument:
1. Run `flutter pub outdated`
2. List packages that can be updated
3. Categorize by: resolvable, latest, and breaking changes

### For `update`:
1. Run `flutter pub upgrade`
2. Report what was updated
3. Run `flutter analyze` to check for breaking changes

### For `add {package}`:
1. Run `flutter pub add {package}`
2. Report success and new version
3. Suggest common usage patterns

### For `remove {package}`:
1. Run `flutter pub remove {package}`
2. Check for unused imports and clean up
