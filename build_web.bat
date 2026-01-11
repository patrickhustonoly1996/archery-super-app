@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Archery Super App - Web Build
echo ========================================
echo.

:: Generate version timestamp
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set VERSION=%datetime:~0,4%%datetime:~4,2%%datetime:~6,2%.%datetime:~8,2%%datetime:~10,2%
echo Build Version: %VERSION%
echo.

:: Step 1: Build Flutter web
echo [1/5] Building Flutter web (release)...
call flutter build web --release
if errorlevel 1 (
    echo ERROR: Flutter build failed!
    exit /b 1
)
echo       Done.
echo.

:: Step 2: Copy Drift database files
echo [2/5] Copying Drift database files...
copy /Y "web\sqlite3.wasm" "build\web\sqlite3.wasm" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy sqlite3.wasm!
    exit /b 1
)
copy /Y "web\drift_worker.js" "build\web\drift_worker.js" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy drift_worker.js!
    exit /b 1
)
copy /Y "web\drift_worker.js.map" "build\web\drift_worker.js.map" >nul 2>nul
echo       Done.
echo.

:: Step 3: Update version in index.html
echo [3/5] Updating version in index.html...
powershell -Command "(Get-Content 'build\web\index.html') -replace '__APP_VERSION__', '%VERSION%' | Set-Content 'build\web\index.html'"
if errorlevel 1 (
    echo WARNING: Could not update version in index.html
)
echo       Done.
echo.

:: Step 4: Create version.json with build info
echo [4/5] Creating version.json...
echo {"version": "%VERSION%", "build_time": "%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%T%datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%Z"} > "build\web\version.json"
echo       Done.
echo.

:: Step 5: Verify critical files exist
echo [5/5] Verifying build...
set MISSING=0
if not exist "build\web\index.html" (
    echo ERROR: index.html missing!
    set MISSING=1
)
if not exist "build\web\main.dart.js" (
    echo ERROR: main.dart.js missing!
    set MISSING=1
)
if not exist "build\web\flutter_service_worker.js" (
    echo ERROR: flutter_service_worker.js missing!
    set MISSING=1
)
if not exist "build\web\sqlite3.wasm" (
    echo ERROR: sqlite3.wasm missing!
    set MISSING=1
)
if not exist "build\web\drift_worker.js" (
    echo ERROR: drift_worker.js missing!
    set MISSING=1
)
if %MISSING%==1 (
    echo.
    echo BUILD FAILED - Missing critical files!
    exit /b 1
)
echo       All critical files present.
echo.

echo ========================================
echo   BUILD COMPLETE - Version %VERSION%
echo ========================================
echo.
echo To deploy, run:
echo   firebase deploy --only hosting
echo.
echo Or to test locally first:
echo   cd build\web ^&^& python -m http.server 8080
echo.

endlocal
