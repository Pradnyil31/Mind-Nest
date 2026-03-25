import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/logger.dart';

class ChatService {
  // Optional direct model key (fallback only).
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Prefer server-mediated chat for security and abuse control.
  static const bool _preferServerChat = bool.fromEnvironment('USE_SERVER_CHAT', defaultValue: true);
  static const int _maxInputLength = 500;

  final FirebaseFunctions _functions;

  // Fallback local models (only used if server path fails and API key exists).
  final List<String> _fallbackModels = [
    'gemini-1.5-flash',
    'gemini-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-2.0-flash-lite',
    'gemini-exp-1206',
    'gemini-2.5-flash',
  ];

  int _currentModelIndex = 0;
  GenerativeModel? _model;
  ChatSession? _chat;

  bool get _hasApiKey => _apiKey.trim().isNotEmpty;

  ChatService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance {
    if (_hasApiKey) {
      _initModel();
    } else {
      appLogger.w('Gemini API key is not set; local chat fallback is disabled.');
    }
  }

  void _initModel() {
    if (!_hasApiKey) return;

    final modelName = _fallbackModels[_currentModelIndex];
    appLogger.i('Initializing local chat fallback model: $modelName');

    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_getSystemPrompt()),
    );

    _chat ??= _model!.startChat(history: []);
  }

  String _getSystemPrompt() {
    return '''You are a caring and empathetic friend helping someone with their mental wellness journey.
Your tone is warm, supportive, and non-judgmental.

Key traits:
- Use casual, friendly language (like texting a friend)
- Show genuine empathy and understanding
- Offer encouragement without being preachy
- Keep responses concise (2-3 sentences usually)
- Use emojis occasionally to feel more personal
- Never diagnose or replace professional help
- For serious concerns, suggest professional support

You can suggest app features like:
- "Try a 5-minute breathing exercise" for anxiety
- "There's a calming meditation for sleep"
- "Journaling might help process this"
- "Setting a small goal can build momentum"
- "Want to listen to some rain sounds?"

If someone mentions self-harm or suicide, respond with compassion and provide crisis resources immediately.''';
  }

  Future<String> sendMessage(String userMessage) async {
    final sanitizedText = userMessage.replaceAll(RegExp(r'[<>]'), '').trim();

    if (sanitizedText.isEmpty) {
      return 'Tell me what is on your mind, and we can work through it together.';
    }

    if (sanitizedText.length > _maxInputLength) {
      return 'Please keep your message under $_maxInputLength characters so I can respond well.';
    }

    if (_containsCrisisKeywords(sanitizedText)) {
      return _getCrisisResponse();
    }

    if (_preferServerChat) {
      final serverReply = await _sendMessageViaServer(sanitizedText);
      if (serverReply != null && serverReply.isNotEmpty) {
        return serverReply;
      }

      if (!_hasApiKey) {
        return 'I am having trouble connecting right now. Please try again in a moment.';
      }
    }

    if (!_hasApiKey) {
      return 'Chat is not configured yet. Set USE_SERVER_CHAT and deploy chatProxy, or provide GEMINI_API_KEY as fallback.';
    }

    return _sendMessageViaLocalModel(sanitizedText);
  }

  Future<String?> _sendMessageViaServer(String userMessage) async {
    try {
      final callable = _functions.httpsCallable(
        'chatProxy',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );

      final response = await callable.call(<String, dynamic>{
        'message': userMessage,
      });

      final data = response.data;
      if (data is Map && data['reply'] is String) {
        final reply = (data['reply'] as String).trim();
        if (reply.isNotEmpty) {
          return reply;
        }
      }

      return null;
    } on FirebaseFunctionsException catch (e, stackTrace) {
      appLogger.w(
        'Server chat call failed: ${e.code} - ${e.message}',
      );
      appLogger.e('Server chat exception', error: e, stackTrace: stackTrace);

      if (e.code == 'resource-exhausted') {
        return 'I am getting a lot of requests right now. Please try again shortly.';
      }
      if (e.code == 'invalid-argument') {
        return 'I could not process that message. Please try rephrasing it.';
      }
      if (e.code == 'unauthenticated') {
        return 'Please sign in again to continue chatting.';
      }

      return null;
    } catch (e, stackTrace) {
      appLogger.e('Unexpected server chat failure', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<String> _sendMessageViaLocalModel(String userMessage) async {
    try {
      _model ?? _initModel();
      if (_model == null) {
        return 'I am having trouble connecting right now. Please try again in a moment.';
      }

      _chat ??= _model!.startChat(history: []);
      final response = await _chat!.sendMessage(Content.text(userMessage));
      return response.text ?? 'Sorry, I did not quite catch that. Can you try again?';
    } catch (e, stackTrace) {
      appLogger.e(
        'Local chat failed with ${_fallbackModels[_currentModelIndex]}',
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback to next model.
      if (_currentModelIndex < _fallbackModels.length - 1) {
        _currentModelIndex++;
        final history = _chat?.history.toList() ?? <Content>[];
        _model = null;
        _chat = null;
        _initModel();
        if (_model != null) {
          _chat = _model!.startChat(history: history);
          return _sendMessageViaLocalModel(userMessage);
        }
      }

      final err = e.toString();
      if (err.contains('API_KEY_INVALID')) {
        return 'There is an issue with the local chat API key. Please check the configuration.';
      }
      if (err.contains('429') || err.contains('Quota')) {
        return 'Chat quota is currently exhausted. Please try again later.';
      }

      return 'I am having trouble connecting right now. Please try again in a moment.';
    }
  }

  bool _containsCrisisKeywords(String message) {
    final lowerMessage = message.toLowerCase();
    const crisisKeywords = [
      'suicide',
      'suicidal',
      'kill myself',
      'end my life',
      'hurt myself',
      'self harm',
      'self-harm',
      'don\'t want to live',
      'better off dead',
      'no reason to live',
    ];

    return crisisKeywords.any(lowerMessage.contains);
  }

  String _getCrisisResponse() {
    return '''I am really concerned about you, and you are not alone.

Please reach out for help right now:
- National Suicide Prevention Lifeline: 988 (US)
- Crisis Text Line: Text HOME to 741741
- International support: findahelpline.com

These services are available to help you immediately. Your safety matters.''';
  }

  void clearHistory() {
    if (_model != null) {
      _chat = _model!.startChat(history: []);
    }
  }
}
