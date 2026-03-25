# Chat Backend Hardening (Production)

This project now includes a server-mediated chat endpoint:

- Function: `chatProxy`
- Location: `functions/index.js`
- Invocation: Firebase callable function (`us-central1`)

## Security controls implemented

- Auth required (`request.auth.uid`)
- Message length validation (`<= 500` chars)
- Basic crisis keyword interception on server
- Per-user rate limiting in Firestore (`chat_rate_limits/{uid}`)
- Gemini key kept on server via Firebase Secret (`GEMINI_API_KEY`)

## Deploy

1. Install function dependencies:
   - `cd functions`
   - `npm install`
2. Set Firebase secret:
   - `firebase functions:secrets:set GEMINI_API_KEY`
3. Deploy:
   - `firebase deploy --only functions`

## Client behavior

`lib/services/chat_service.dart` now prefers server chat by default:

- `USE_SERVER_CHAT=true` (default)
- Falls back to local Gemini only if server is unavailable and `GEMINI_API_KEY` is present in app runtime.
