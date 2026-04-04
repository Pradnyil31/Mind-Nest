import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';

class ChatService {
  // Local model key only (free-tier friendly configuration).
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const int _maxInputLength = 500;

  // Local fallback models.
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

  // User context for personalization
  String? _userId;
  Map<String, dynamic> _userContext = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get _hasApiKey => _apiKey.trim().isNotEmpty;

  ChatService({String? userId}) : _userId = userId {
    if (_hasApiKey) {
      _initModel();
    } else {
      appLogger.w('Gemini API key is not set; chat is disabled.');
    }
  }

  /// Set user ID for personalized context
  void setUserId(String userId) {
    _userId = userId;
    appLogger.i('ChatService user ID set: $userId');
  }

  /// Fetch user context data from Firestore
  Future<void> _fetchUserContext() async {
    if (_userId == null) return;

    try {
      // Fetch today's mood
      final today = DateTime.now();
      final moodDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('mood_logs')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: DateTime(
              today.year,
              today.month,
              today.day,
            ),
          )
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String? todayMood;
      if (moodDoc.docs.isNotEmpty) {
        todayMood = moodDoc.docs.first.data()['mood'] as String?;
      }

      // Fetch routine completion status
      final routineDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('routines')
          .doc('current')
          .get();

      int completedActivities = 0;
      int totalActivities = 0;
      if (routineDoc.exists) {
        final data = routineDoc.data();
        if (data != null) {
          final activities = data['activities'] as List<dynamic>?;
          final completionStatus =
              data['completionStatus'] as Map<String, dynamic>?;
          if (activities != null) {
            totalActivities = activities.length;
            if (completionStatus != null) {
              completedActivities = completionStatus.values
                  .where((v) => v == true)
                  .length;
            }
          }
        }
      }

      // Fetch last sleep data
      final sleepDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('sleep_logs')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      double? lastSleepHours;
      if (sleepDoc.docs.isNotEmpty) {
        final sleepData = sleepDoc.docs.first.data();
        final durationMinutes = sleepData['durationMinutes'] as int?;
        if (durationMinutes != null) {
          lastSleepHours = durationMinutes / 60.0;
        }
      }

      _userContext = {
        'todayMood': todayMood,
        'completedActivities': completedActivities,
        'totalActivities': totalActivities,
        'lastSleepHours': lastSleepHours,
        'userId': _userId,
      };

      appLogger.i(
        'User context fetched: mood=$todayMood, routine=$completedActivities/$totalActivities, sleep=${lastSleepHours?.toStringAsFixed(1)}h',
      );
    } catch (e) {
      appLogger.e('Error fetching user context: $e');
    }
  }

  /// Build personalized system prompt with user context
  String _buildPersonalizedSystemPrompt() {
    final basePrompt =
        '''You are a caring and empathetic friend helping someone with their mental wellness journey.
Your tone is warm, supportive, and non-judgmental.

Key traits:
- Use casual, friendly language (like texting a friend)
- Show genuine empathy and understanding
- Offer encouragement without being preachy
- Keep responses concise (2-3 sentences usually)
- Use emojis occasionally to feel more personal
- Never diagnose or replace professional help
- For serious concerns, suggest professional support''';

    // Add user context if available
    final contextParts = <String>[];

    if (_userContext['todayMood'] != null) {
      contextParts.add("User's mood today: ${_userContext['todayMood']}");
    }

    if (_userContext['completedActivities'] != null &&
        _userContext['totalActivities'] != null) {
      final completed = _userContext['completedActivities'] as int;
      final total = _userContext['totalActivities'] as int;
      if (total > 0) {
        contextParts.add(
          "Today's routine: $completed of $total activities completed",
        );
        if (completed < total / 2) {
          contextParts.add(
            "User may need encouragement to complete their routine",
          );
        }
      }
    }

    if (_userContext['lastSleepHours'] != null) {
      final sleepHours = _userContext['lastSleepHours'] as double;
      contextParts.add(
        "Last night's sleep: ${sleepHours.toStringAsFixed(1)} hours",
      );
      if (sleepHours < 6) {
        contextParts.add("User may be sleep-deprived and need energy support");
      }
    }

    if (contextParts.isNotEmpty) {
      final contextString = contextParts.join('\n');
      return '''$basePrompt

Current User Context:
$contextString

Use this context to provide personalized, relevant support. If user seems stressed with low sleep, suggest rest. If routine is incomplete, offer gentle encouragement. Always be supportive and never judgmental.

You can suggest app features like:
- "Try a 5-minute breathing exercise" for anxiety
- "There's a calming meditation for sleep"
- "Journaling might help process this"
- "Setting a small goal can build momentum"
- "Want to listen to some rain sounds?"

If someone mentions self-harm or suicide, respond with compassion and provide crisis resources immediately.''';
    }

    return '''$basePrompt

You can suggest app features like:
- "Try a 5-minute breathing exercise" for anxiety
- "There's a calming meditation for sleep"
- "Journaling might help process this"
- "Setting a small goal can build momentum"
- "Want to listen to some rain sounds?"

If someone mentions self-harm or suicide, respond with compassion and provide crisis resources immediately.''';
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

  /// Reinitialize model with personalized system prompt
  Future<void> _reinitModelWithPersonalization() async {
    if (!_hasApiKey) return;

    await _fetchUserContext();

    final modelName = _fallbackModels[_currentModelIndex];
    appLogger.i('Reinitializing model with personalization: $modelName');

    _model = GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_buildPersonalizedSystemPrompt()),
    );

    // Start fresh chat with personalized context
    _chat = _model!.startChat(history: []);
  }

  String _getSystemPrompt() {
    return _buildPersonalizedSystemPrompt();
  }

  Future<String> sendMessage(
    String userMessage, {
    bool usePersonalization = true,
  }) async {
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

    if (!_hasApiKey) {
      return 'Chat is not configured yet. Please add GEMINI_API_KEY to enable local chat.';
    }

    // Reinitialize with personalization if needed
    if (usePersonalization && _userId != null) {
      await _reinitModelWithPersonalization();
    }

    return _sendMessageViaLocalModel(sanitizedText);
  }

  Future<String> _sendMessageViaLocalModel(String userMessage) async {
    try {
      _model ?? _initModel();
      if (_model == null) {
        return 'I am having trouble connecting right now. Please try again in a moment.';
      }

      _chat ??= _model!.startChat(history: []);
      final response = await _chat!.sendMessage(Content.text(userMessage));
      return response.text ??
          'Sorry, I did not quite catch that. Can you try again?';
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

  /// Get personalized suggestions based on user context
  List<String> getPersonalizedSuggestions() {
    final suggestions = <String>[];

    final mood = _userContext['todayMood'] as String?;
    final completed = _userContext['completedActivities'] as int? ?? 0;
    final total = _userContext['totalActivities'] as int? ?? 0;
    final sleepHours = _userContext['lastSleepHours'] as double?;

    // Mood-based suggestions
    if (mood == 'Stressed' || mood == 'Anxious') {
      suggestions.add('Try a 5-minute breathing exercise');
      suggestions.add('Listen to calming rain sounds');
    } else if (mood == 'Sad' || mood == 'Down') {
      suggestions.add('Journal about what is on your mind');
      suggestions.add('Try a gratitude exercise');
    } else if (mood == 'Happy' || mood == 'Calm') {
      suggestions.add('Set a small goal for today');
      suggestions.add('Practice a new meditation technique');
    }

    // Routine-based suggestions
    if (total > 0 && completed < total / 2) {
      suggestions.add('Complete your next routine activity');
    }

    // Sleep-based suggestions
    if (sleepHours != null && sleepHours < 6) {
      suggestions.add('Try a sleep meditation tonight');
      suggestions.add('Take a short nap if possible');
    }

    // Default suggestions if no specific triggers
    if (suggestions.isEmpty) {
      suggestions.add('Try a 5-minute breathing exercise');
      suggestions.add('Journal about your day');
      suggestions.add('Set a small wellness goal');
    }

    return suggestions.take(3).toList();
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
- Tele MANAS (Govt Mental Health Helpline): 14416
- Kiran (24/7 Helpline): 1800-599-0019
- Vandrevala Foundation: +91 9999 666 555
- International support: findahelpline.com

These services are available to help you immediately. Your safety matters.''';
  }

  void clearHistory() {
    if (_model != null) {
      _chat = _model!.startChat(history: []);
    }
  }

  /// Clear user context (call on logout)
  void clearUserContext() {
    _userId = null;
    _userContext = {};
    clearHistory();
    appLogger.i('ChatService user context cleared');
  }
}
