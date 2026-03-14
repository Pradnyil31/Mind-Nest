@echo off
echo Deploying Firestore Security Rules...
echo.

REM Check if Firebase CLI is available
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found. Please install it first:
    echo npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

REM Deploy the rules
echo Deploying rules to Firebase...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Firestore rules deployed successfully!
    echo Your app should now work without permission errors.
) else (
    echo.
    echo ERROR: Failed to deploy rules. Please check your Firebase configuration.
)

echo.
pause