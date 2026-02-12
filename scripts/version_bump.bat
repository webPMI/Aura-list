@echo off
REM Version bumping script for AuraList
REM Increments the build number in pubspec.yaml

setlocal enabledelayedexpansion

echo ========================================
echo    AuraList Version Bump
echo ========================================
echo.

REM Read current version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr "^version:" pubspec.yaml') do set CURRENT_VERSION=%%a

echo Current version: %CURRENT_VERSION%

REM Split version and build number
for /f "tokens=1,2 delims=+" %%a in ("%CURRENT_VERSION%") do (
    set VERSION=%%a
    set BUILD=%%b
)

REM Increment build number
set /a NEW_BUILD=%BUILD%+1

set NEW_VERSION=%VERSION%+%NEW_BUILD%
echo New version: %NEW_VERSION%

REM Ask for confirmation
set /p CONFIRM="Update pubspec.yaml to %NEW_VERSION%? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Cancelled.
    exit /b 0
)

REM Update pubspec.yaml
powershell -Command "(Get-Content pubspec.yaml) -replace 'version: .*', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"

echo.
echo ========================================
echo    Version updated successfully!
echo ========================================
echo.
echo Old: %CURRENT_VERSION%
echo New: %NEW_VERSION%
echo.
echo Don't forget to commit this change:
echo   git add pubspec.yaml
echo   git commit -m "chore: bump version to %NEW_VERSION%"
echo.
pause
