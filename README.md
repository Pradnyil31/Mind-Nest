# MindNest

MindNest is a Flutter wellness application for daily routines, journaling, meditation/focus sessions, and progress tracking. It uses Firebase Auth + Firestore for identity/data and supports a server-mediated AI chat companion via Firebase Functions.

## Core capabilities

- Email/password and Google sign-in
- Guided onboarding and personalized wellness goals
- Daily routine generation and completion tracking
- Daily check-ins, journaling, meditation, and focus sessions
- Progress insights and badges
- Server-mediated AI chat (`chatProxy`) with rate limiting and crisis-keyword guard

## Tech stack

- Frontend: Flutter (Dart)
- State management: Riverpod
- Backend: Firebase Auth, Firestore, Cloud Functions
- Notifications: `flutter_local_notifications`

## Prerequisites

- Flutter SDK
- Node.js 20+ (for functions and rules tests)
- Firebase CLI
- Firebase project credentials for native platforms

## Setup

1. Install app dependencies:

```bash
flutter pub get
```

2. Install function dependencies:

```bash
cd functions
npm install
cd ..
```

3. Configure native Firebase:

- Android: place `android/app/google-services.json`
- iOS: place `ios/Runner/GoogleService-Info.plist`

4. Configure function secret for server chat:

```bash
firebase functions:secrets:set GEMINI_API_KEY
```

5. Run app (server chat by default):

```bash
flutter run --dart-define=USE_SERVER_CHAT=true
```

## Optional web setup

Web builds require explicit Firebase web defines:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_WEB_API_KEY=... \
  --dart-define=FIREBASE_WEB_APP_ID=... \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_WEB_PROJECT_ID=... \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=...
```

## Security and quality gates

- Firestore rules enforce owner-only access and immutable ownership fields.
- Rules tests cover critical collections and user profile immutability.
- CI workflow: `.github/workflows/flutter-quality-gate.yml`

Local checks:

```bash
./tools/quality_gate.sh
./tools/firestore_rules_test.sh
```

(Windows PowerShell equivalents are in `tools/*.ps1`.)

## Publication runbook

Use `docs/publication_readiness_playbook.md` as the pre-submission checklist.
