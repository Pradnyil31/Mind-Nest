# Chat Configuration Hardening (Free-Tier)

This project now uses local model-based chat from the mobile client runtime.

## Current mode

- No Firebase Cloud Functions dependency
- No callable backend for chat
- Chat uses `GEMINI_API_KEY` passed at runtime

## Security and safety controls still applied in app

- Input length validation (`<= 500` chars)
- Crisis keyword interception with emergency resources
- Error/fallback messaging for quota/connectivity failures

## Run mode

Use:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
```

## Important note

Because chat is now client-side, avoid committing keys and rotate keys regularly.
