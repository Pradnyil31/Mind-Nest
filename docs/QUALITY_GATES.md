# Quality Gates

This project has automated quality gates in CI:

- `.github/workflows/flutter-quality-gate.yml`

## Gate 1: Flutter quality checks

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test --coverage`

CI uploads `coverage/lcov.info` as artifact `coverage-lcov`.

## Gate 2: Firestore security-rules checks

Rules tests are in:

- `firestore_rules_tests/tests/firestore.rules.test.js`

Critical collection coverage includes:

- `daily_checkins`
- `journal_entries`
- `meditation_sessions`
- `focus_sessions`
- `routine_completions`

Each collection is tested for:

- owner-only create/read/update/delete behavior
- immutable `userId` on update
- unauthenticated write denial
- user profile immutability checks (`uid`, `createdAt`)
- backend-only `chat_rate_limits` deny-all client access

CI runs rules tests using Firestore Emulator via package script:

- `npm --prefix firestore_rules_tests test`

Java 21+ is recommended for Firebase emulators locally (Java 17 still works today, but firebase-tools is deprecating <21).

## Run locally

Windows (PowerShell)

```powershell
.\tools\quality_gate.ps1
.\tools\firestore_rules_test.ps1
```

macOS/Linux

```bash
./tools/quality_gate.sh
./tools/firestore_rules_test.sh
```

## Why this matters for publication readiness

- Prevents regressions before merge.
- Provides reproducible validation for viva/demo.
- Produces machine-generated evidence of correctness and security posture.

