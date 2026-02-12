@echo off
REM Build script for AuraList - Windows
REM Builds for Android, Web, and Windows platforms

echo ========================================
echo    Building AuraList - All Platforms
echo ========================================
echo.

REM Check if Flutter is available
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter not found in PATH
    exit /b 1
)

echo [1/6] Cleaning previous builds...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter clean failed
    exit /b 1
)

echo [2/6] Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter pub get failed
    exit /b 1
)

echo [3/6] Generating code (Hive adapters)...
call dart run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Code generation failed
    exit /b 1
)

echo [4/6] Building Android APKs (split by ABI)...
call flutter build apk --release --split-per-abi
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Android APK build failed
) else (
    echo Android APKs built successfully!
    echo Location: build\app\outputs\flutter-apk\
)

echo [5/6] Building Web (PWA)...
call flutter build web --release --base-href="/" --pwa-strategy=offline-first
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Web build failed
) else (
    echo Web build completed successfully!
    echo Location: build\web\
)

echo [6/6] Building Windows...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Windows build failed
) else (
    echo Windows build completed successfully!
    echo Location: build\windows\x64\runner\Release\
)

echo.
echo ========================================
echo    Build Process Completed!
echo ========================================
echo.
echo Build outputs:
echo   - Android APKs: build\app\outputs\flutter-apk\
echo   - Web: build\web\
echo   - Windows: build\windows\x64\runner\Release\
echo.
pause
