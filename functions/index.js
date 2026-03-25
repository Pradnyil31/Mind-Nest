const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { logger } = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const geminiApiKey = defineSecret('GEMINI_API_KEY');

const MAX_MESSAGE_LENGTH = 500;
const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 20;
const DEFAULT_MODEL = 'gemini-1.5-flash';
const FALLBACK_MODELS = [
  DEFAULT_MODEL,
  'gemini-2.0-flash-lite',
  'gemini-2.5-flash',
];

const SYSTEM_PROMPT = `You are a caring and empathetic friend helping someone with their mental wellness journey.
Your tone is warm, supportive, and non-judgmental.

Key traits:
- Use casual, friendly language
- Show empathy and understanding
- Keep responses concise (2-3 sentences)
- Never diagnose or replace professional help
- For serious concerns, suggest professional support`;

const CRISIS_RESPONSE = `I am really concerned about you, and you are not alone.

Please reach out for help right now:
- National Suicide Prevention Lifeline: 988 (US)
- Crisis Text Line: Text HOME to 741741
- International support: findahelpline.com

These services are available to help you immediately. Your safety matters.`;

const CRISIS_KEYWORDS = [
  'suicide',
  'suicidal',
  'kill myself',
  'end my life',
  'hurt myself',
  'self harm',
  'self-harm',
  "don't want to live",
  'better off dead',
  'no reason to live',
];

function containsCrisisKeywords(text) {
  const lower = text.toLowerCase();
  return CRISIS_KEYWORDS.some((keyword) => lower.includes(keyword));
}

async function enforceRateLimit(uid) {
  const nowMs = Date.now();
  const docRef = db.collection('chat_rate_limits').doc(uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);

    if (!snap.exists) {
      tx.set(docRef, {
        windowStartMs: nowMs,
        count: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const data = snap.data() || {};
    const windowStartMs = typeof data.windowStartMs === 'number' ? data.windowStartMs : 0;
    const count = typeof data.count === 'number' ? data.count : 0;

    if (nowMs - windowStartMs >= RATE_LIMIT_WINDOW_MS) {
      tx.set(
        docRef,
        {
          windowStartMs: nowMs,
          count: 1,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return;
    }

    if (count >= RATE_LIMIT_MAX_REQUESTS) {
      throw new HttpsError('resource-exhausted', 'Too many chat requests. Please try again shortly.');
    }

    tx.set(
      docRef,
      {
        count: count + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

async function generateReply(apiKey, message) {
  for (const model of FALLBACK_MODELS) {
    const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const body = {
      systemInstruction: {
        parts: [{ text: SYSTEM_PROMPT }],
      },
      contents: [
        {
          role: 'user',
          parts: [{ text: message }],
        },
      ],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 256,
      },
    };

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        logger.warn('Gemini model request failed', { model, status: response.status });
        continue;
      }

      const payload = await response.json();
      const candidate = payload?.candidates?.[0];
      const parts = candidate?.content?.parts;
      if (!Array.isArray(parts) || parts.length === 0) {
        continue;
      }

      const text = parts
        .map((part) => (typeof part?.text === 'string' ? part.text : ''))
        .join('\n')
        .trim();

      if (text) {
        return text;
      }
    } catch (error) {
      logger.error('Gemini request error', { model, error: String(error) });
    }
  }

  throw new HttpsError('unavailable', 'Chat backend is temporarily unavailable.');
}

exports.chatProxy = onCall(
  {
    region: 'us-central1',
    timeoutSeconds: 30,
    memory: '256MiB',
    secrets: [geminiApiKey],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }

    const rawMessage = typeof request.data?.message === 'string' ? request.data.message : '';
    const message = rawMessage.replace(/[<>]/g, '').trim();

    if (!message) {
      throw new HttpsError('invalid-argument', 'Message is required.');
    }

    if (message.length > MAX_MESSAGE_LENGTH) {
      throw new HttpsError(
        'invalid-argument',
        `Message exceeds ${MAX_MESSAGE_LENGTH} characters.`
      );
    }

    if (containsCrisisKeywords(message)) {
      return {
        reply: CRISIS_RESPONSE,
        source: 'crisis_guard',
      };
    }

    await enforceRateLimit(request.auth.uid);

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError('failed-precondition', 'Server chat key is not configured.');
    }

    const reply = await generateReply(apiKey, message);

    return {
      reply,
      source: 'server',
    };
  }
);

