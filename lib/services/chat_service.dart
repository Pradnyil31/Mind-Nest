import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/logger.dart';

class ChatService {
  // TODO: Replace with your actual Gemini API key
  // Get key from: https://aistudio.google.com/app/apikey
  // OR: https://console.cloud.google.com/ → "Generative Language API"
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // List of models to try in order of preference/likelihood of working
  final List<String> _fallbackModels = [
    'gemini-1.5-flash',
    'gemini-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-2.0-flash-lite',
    'gemini-exp-1206',
    'gemini-2.5-flash',
  ];
  
  int _currentModelIndex = 0;
  late GenerativeModel _model;
  ChatSession? _chat;

  ChatService() {
    _initModel();
  }

  void _initModel() {
    final modelName = _fallbackModels[_currentModelIndex];
    appLogger.i('🤖 Initializing Chat with model: $modelName');
    
    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_getSystemPrompt()),
    );
    
    // If we are re-initializing (fallback), we might want to restore history.
    // Ideally, _chat handles its own history, but here we are replacing _model.
    // For simplicity, we restart chat if it's null, or if we are just starting.
    if (_chat == null) {
      _startNewChat();
    }
  }

  void _startNewChat() {
    _chat = _model.startChat(history: []);
  }

  String _getSystemPrompt() {
    return '''You are a caring and empathetic friend helping someone with their mental wellness journey. 
Your tone is warm, supportive, and non-judgmental.

Key traits:
- Use casual, friendly language (like texting a friend)
- Show genuine empathy and understanding
- Offer encouragement without being preachy
- Keep responses concise (2-3 sentences usually)
- Use emojis occasionally to feel more personal 😊 💙 🌟
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
    try {
      // Check for crisis keywords first
      if (_containsCrisisKeywords(userMessage)) {
        return _getCrisisResponse();
      }

      final response = await _chat!.sendMessage(Content.text(userMessage));
      return response.text ?? 'Sorry, I didn\'t quite catch that. Can you try again?';
    } catch (e, stackTrace) {
      appLogger.e('Error sending message with ${_fallbackModels[_currentModelIndex]}', error: e);
      
      // Check if we can fallback to another model
      if (_currentModelIndex < _fallbackModels.length - 1) {
        _currentModelIndex++;
        appLogger.w('⚠️ Switching to fallback model: ${_fallbackModels[_currentModelIndex]}');
        
        // Save current history before switching
        final history = _chat?.history.toList() ?? [];
        
        // Re-init with new model
        _initModel();
        
        // Restore history in new chat
        _chat = _model.startChat(history: history);
        
        // Recursive retry
        return sendMessage(userMessage);
      }
      
      // If all fallbacks failed:
      if (e.toString().contains('API_KEY_INVALID')) {
        return "Hmm, there's an issue with my API key 🔑 Please check that you've added a valid Gemini API key.";
      } else if (e.toString().contains('429') || e.toString().contains('Quota')) {
        return "Ideally all my brains are busy! 🤯 (Quota exceeded on all models). Please try again later.";
      }
      
      return 'Oops, I\'m having trouble connecting right now 📡 (${e.toString().split('\n').first})';
    }
  }

  bool _containsCrisisKeywords(String message) {
    final lowerMessage = message.toLowerCase();
    final crisisKeywords = [
      'suicide', 'suicidal', 'kill myself', 'end my life',
      'hurt myself', 'self harm', 'don\'t want to live',
      'better off dead', 'no reason to live'
    ];
    
    return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  String _getCrisisResponse() {
    return '''I'm really concerned about you, and I want you to know that you're not alone 💙

Please reach out for help right now:
• National Suicide Prevention Lifeline: 988 (or 1-800-273-8255)
• Crisis Text Line: Text HOME to 741741
• International: findahelpline.com

These people are trained to help and they care. Please call them - your life matters.''';
  }

  void clearHistory() {
    _startNewChat();
  }
}
