@echo off
echo Building Flutter web...
call flutter build web --release

echo Copying Drift database files...
copy /Y "web\sqlite3.wasm" "build\web\sqlite3.wasm"
copy /Y "web\drift_worker.js" "build\web\drift_worker.js"

echo Done! Ready to deploy with: firebase deploy --only hosting
