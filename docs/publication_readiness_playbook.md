# Publication Readiness Playbook

This runbook defines the minimum technical evidence required before claiming publication-grade quality.

## 1) Mandatory gates

Run all gates and archive outputs:

```bash
flutter analyze
flutter test --coverage
npm --prefix firestore_rules_tests test
```

Store artifacts:

- `coverage/lcov.info`
- Firestore rules test console output
- Commit hash and branch name

## 2) Security evidence

Verify all of the following:

- Firestore rules deployed from `firestore.rules`
- Storage rules deployed from `storage.rules`
- Cloud Function `chatProxy` deployed with `GEMINI_API_KEY` Firebase Secret
- No hardcoded API keys in tracked files

## 3) Performance evidence (minimum)

Collect p50/p95 for:

- Login success flow
- Daily check-in submit flow
- Routine activity completion write
- Chat request/response roundtrip

Also collect:

- Firestore reads/writes per session
- Crash-free session rate
- Retry/error rate by feature

## 4) Reliability evidence

Test and record pass/fail for:

- Auth recovery (password reset)
- Offline/online reconnect for core writes
- Permission-denied handling UX
- Empty-state rendering for all main tabs

## 5) Research-paper figures/tables

Generate at least:

- Architecture diagram (client layers + Firebase boundaries + function boundary)
- Security model table (threat, mitigation, residual risk)
- Performance table (p50/p95 and sample size)
- Usability table (task completion rate / SUS or equivalent)

## 6) Claims discipline

Safe claims:

- Feature-complete prototype with owner-scoped data isolation and automated rules checks.
- Server-mediated AI chat with authentication and rate-limiting controls.

Do not claim yet unless evaluated:

- Clinical efficacy
- Internet-scale production readiness
- Formal security certification
