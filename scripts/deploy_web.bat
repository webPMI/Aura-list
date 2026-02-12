@echo off
REM Deploy AuraList Web to Firebase Hosting

echo ========================================
echo    Deploying AuraList to Firebase
echo ========================================
echo.

REM Check if Firebase CLI is available
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Firebase CLI not found
    echo Install with: npm install -g firebase-tools
    exit /b 1
)

REM Check if Flutter is available
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter not found in PATH
    exit /b 1
)

echo [1/4] Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter pub get failed
    exit /b 1
)

echo [2/4] Generating code...
call dart run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Code generation failed
    exit /b 1
)

echo [3/4] Building web release...
call flutter build web --release --base-href="/" --pwa-strategy=offline-first
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Web build failed
    exit /b 1
)

echo [4/4] Deploying to Firebase Hosting...
call firebase deploy --only hosting
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Firebase deployment failed
    exit /b 1
)

echo.
echo ========================================
echo    Deployment Successful!
echo ========================================
echo.
echo Your app is live at: https://aura-list.web.app
echo.
pause
