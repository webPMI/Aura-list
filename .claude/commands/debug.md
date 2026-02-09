# /debug - Debug Common Issues

Diagnose and fix common issues in the checklist app.

## Arguments
- `$ARGUMENTS` - Issue type: `build`, `firebase`, `hive`, `riverpod`, `state`

## Instructions

### For `build`:
1. Check for Dart analysis errors
2. Verify pubspec.yaml syntax
3. Check for missing generated files
4. Suggest running `/clean` if needed

### For `firebase`:
1. Verify Firebase configuration files exist
2. Check google-services.json (Android)
3. Check GoogleService-Info.plist (iOS)
4. Verify firebase_options.dart is up to date

### For `hive`:
1. Check if all TypeAdapters are registered
2. Verify .g.dart files are generated
3. Check for typeId conflicts
4. Suggest running `/generate`

### For `riverpod`:
1. Check ProviderScope is at root
2. Look for common provider issues
3. Verify ConsumerWidget usage

### For `state`:
1. Analyze state flow in providers
2. Check for state management anti-patterns
3. Suggest improvements
