# /build - Build Flutter App

Build the checklist app for the specified platform.

## Arguments
- `$ARGUMENTS` - Platform: `apk`, `appbundle`, `ios`, `web`, `windows` (default: `apk`)

## Instructions

1. Run `flutter pub get` to ensure dependencies are up to date
2. Run `dart run build_runner build --delete-conflicting-outputs` for generated files
3. Run `flutter build $ARGUMENTS` (use `apk` if no argument)
4. Report build result and output location
5. If build fails, analyze errors and suggest fixes

## Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Web: `build/web/`
- Windows: `build/windows/runner/Release/`
