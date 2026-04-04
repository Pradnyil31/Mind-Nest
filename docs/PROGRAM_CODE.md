# 5. PROGRAM CODE

## 5.1) main.dart
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_branding.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _error = null;
      _initialized = false;
    });

    try {
      await dotenv.load(fileName: ".env");
      await _initializeFirebase().timeout(const Duration(seconds: 15));
      await _initializeNotifications().timeout(const Duration(seconds: 8));
      await _configureFirestore().timeout(const Duration(seconds: 6));
      // ROLLBACK P1: offline service init disabled
      // await _initializeOfflineService().timeout(const Duration(seconds: 5));
      await _configureSystemUi();

      if (!mounted) return;
      setState(() {
        _initialized = true;
      });
    } catch (e, stackTrace) {
      debugPrint('App bootstrap failed: $e');
      debugPrint('Bootstrap stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Firebase already initialized');
      return;
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      debugPrint('Firebase default app already exists; continuing.');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<void> _configureFirestore() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore settings failed: $e');
    }
  }


  Future<void> _configureSystemUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    } catch (e) {
      debugPrint('System UI settings failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const ProviderScope(child: MindNestApp());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BrandedBootScreen(error: _error, onRetry: _initialize),
    );
  }
}

class _BrandedBootScreen extends StatelessWidget {
  final String? error;
  final Future<void> Function() onRetry;

  const _BrandedBootScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEEF8F6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppBranding.logoAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppBranding.logoAssetPathAlt,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppBranding.logoAssetPathFallback,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.spa_rounded,
                            size: 66,
                            color: Color(0xFF6A8DFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppBranding.appName,
                    style: GoogleFonts.lato(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2530),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppBranding.tagline,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (error == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Starting app...',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Startup failed',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF7F1D1D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MindNestApp extends StatelessWidget {
  const MindNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }

        final userProfile = ref.watch(userProfileProvider);

        return userProfile.when(
          data: (profile) {
            if (profile == null) {
              return const WelcomeScreen();
            }

            if (profile.onboardingCompleted) {
              return const HomeScreen();
            }
            return const OnboardingFlowScreen();
          },
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          ),
          error: (error, stack) {
            debugPrint('User profile error: $error');
            debugPrint('Stack trace: $stack');
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text('Error loading profile'),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(userProfileProvider),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const WelcomeScreen(),
                            ),
                          );
                        },
                        child: const Text('Go to Welcome'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        debugPrint('Auth state error: $error');
        debugPrint('Stack trace: $stack');
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Authentication Error'),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(authStateProvider),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                      );
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

```

## 5.2) Routine Management Module (home_routine_engine.dart)
```dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../config/routine_config.dart';

class HomeRoutineEngine {
  static List<String> generateBalancedRoutine(List<String> pool, int count) {
    final rng = Random(_seedFromNow());

    final morningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Morning')
        .toList();
    final afternoonPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Afternoon')
        .toList();
    final eveningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Evening')
        .toList();

    if (morningPool.length < 4) {
      morningPool.addAll(RoutineConfig.getActivitiesForPeriod('Morning'));
    }
    if (afternoonPool.length < 4) {
      afternoonPool.addAll(RoutineConfig.getActivitiesForPeriod('Afternoon'));
    }
    if (eveningPool.length < 4) {
      eveningPool.addAll(RoutineConfig.getActivitiesForPeriod('Evening'));
    }

    morningPool.shuffle(rng);
    afternoonPool.shuffle(rng);
    eveningPool.shuffle(rng);

    // Equal distribution: divide activities equally across three periods
    final base = count ~/ 3;
    final rem = count % 3;

    // Distribute remainder evenly: first period gets +1, then second, then third
    final mCount = base + (rem >= 1 ? 1 : 0);
    final aCount = base + (rem >= 2 ? 1 : 0);
    final eCount = base + (rem >= 3 ? 1 : 0);

    final result = <String>{};

    void pickFrom(List<String> src, int needed) {
      int taken = 0;
      for (final a in src) {
        if (taken >= needed) break;
        if (result.add(a)) taken++;
      }
    }

    pickFrom(morningPool, mCount);
    pickFrom(afternoonPool, aCount);
    pickFrom(eveningPool, eCount);

    if (result.length < count) {
      final all = [...morningPool, ...afternoonPool, ...eveningPool]
        ..shuffle(rng);
      for (final a in all) {
        if (result.length >= count) break;
        result.add(a);
      }
    }

    return result.take(count).toList();
  }

  static Map<String, String> calculateDynamicSchedule(
    List<String> activities,
    TimeOfDay wakeTime,
    TimeOfDay bedTime,
  ) {
    final schedule = <String, String>{};

    int wakeMin = wakeTime.hour * 60 + wakeTime.minute;
    int bedMin = bedTime.hour * 60 + bedTime.minute;
    if (bedMin < wakeMin) bedMin += 24 * 60;

    int morningOffset = 0;
    int afternoonOffset = 0;
    int eveningOffset = 0;
    int afternoonStart = 12 * 60;
    int eveningStart = 17 * 60;
    if (wakeMin > afternoonStart) afternoonStart = wakeMin + 60;
    if (wakeMin > eveningStart) eveningStart = wakeMin + 180;

    // Calculate available time and spacing for even distribution
    int totalAvailableMinutes = bedMin - wakeMin;
    int activityCount = activities.length;
    int baseSpacing = activityCount > 0
        ? totalAvailableMinutes ~/ activityCount
        : 60;
    if (baseSpacing < 30) baseSpacing = 30; // Minimum 30 min spacing
    if (baseSpacing > 120) baseSpacing = 120; // Maximum 2 hour spacing

    for (final activity in activities) {
      final lower = activity.toLowerCase();
      String timeString;

      if (lower.contains('sunlight')) {
        timeString = minToTime(wakeMin + 15);
      } else if (lower.contains('caffeine') && lower.contains('delay')) {
        timeString = minToTime(wakeMin + 90);
      } else if (lower.contains('caffeine') &&
          (lower.contains('cut') || lower.contains('off'))) {
        if (bedMin - wakeMin >= 12 * 60) {
          timeString = minToTime(wakeMin + 90);
        } else {
          timeString = minToTime(bedMin - 10 * 60);
        }
      } else if (lower.contains('sleep') || lower.contains('bed time')) {
        timeString = _formatTimeOfDay(bedTime);
      } else if (lower.contains('wind down')) {
        timeString = minToTime(bedMin - 60);
      } else {
        final period = RoutineConfig.getTimePeriod(activity);
        if (period == 'Morning') {
          timeString = minToTime(wakeMin + 15 + morningOffset);
          morningOffset += baseSpacing;
        } else if (period == 'Afternoon') {
          timeString = minToTime(afternoonStart + afternoonOffset);
          afternoonOffset += baseSpacing;
        } else {
          // Evening - distribute with proper spacing
          timeString = minToTime(eveningStart + eveningOffset);
          eveningOffset += baseSpacing;
        }
      }

      schedule[activity] = timeString;
    }

    return schedule;
  }

  static String minToTime(int totalMinutes) {
    totalMinutes = totalMinutes % (24 * 60);
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  static List<String> generateDailyFromBase(
    List<String> baseRoutine,
    List<String> pool,
    int targetCount,
  ) {
    final rng = Random(_seedFromNow());

    // Calculate exact distribution across periods
    final basePerPeriod = targetCount ~/ 3;
    final remainder = targetCount % 3;

    // Distribute remainder: first 'remainder' periods get +1
    final targetMorning = basePerPeriod + (remainder > 0 ? 1 : 0);
    final targetAfternoon = basePerPeriod + (remainder > 1 ? 1 : 0);
    final targetEvening = basePerPeriod;

    // Group pool by time period
    final morningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Morning')
        .toList();
    final afternoonPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Afternoon')
        .toList();
    final eveningPool = pool
        .where((a) => RoutineConfig.getTimePeriod(a) == 'Evening')
        .toList();

    morningPool.shuffle(rng);
    afternoonPool.shuffle(rng);
    eveningPool.shuffle(rng);

    final result = <String>[];
    final added = <String>{};

    // Add base routine activities first, respecting period targets
    for (final activity in baseRoutine) {
      if (activity.trim().isEmpty || added.contains(activity)) continue;

      final period = RoutineConfig.getTimePeriod(activity);
      int currentInPeriod = result
          .where((a) => RoutineConfig.getTimePeriod(a) == period)
          .length;

      // Only add if we haven't hit the target for this period
      int targetForPeriod = period == 'Morning'
          ? targetMorning
          : period == 'Afternoon'
          ? targetAfternoon
          : targetEvening;

      if (currentInPeriod < targetForPeriod) {
        result.add(activity);
        added.add(activity);
      }
    }

    // Fill each period to exact target from pool
    void fillPeriod(List<String> periodPool, int target) {
      int current = result
          .where(
            (a) =>
                periodPool.isEmpty ||
                RoutineConfig.getTimePeriod(a) ==
                    (periodPool == morningPool
                        ? 'Morning'
                        : periodPool == afternoonPool
                        ? 'Afternoon'
                        : 'Evening'),
          )
          .length;

      for (final activity in periodPool) {
        if (result.length >= targetCount) break;
        if (current >= target) break;
        if (added.add(activity)) {
          result.add(activity);
          current++;
        }
      }
    }

    fillPeriod(morningPool, targetMorning);
    fillPeriod(afternoonPool, targetAfternoon);
    fillPeriod(eveningPool, targetEvening);

    // If still under target, fill remaining from all pools
    if (result.length < targetCount) {
      final allRemaining = [...morningPool, ...afternoonPool, ...eveningPool]
        ..shuffle(rng);
      for (final activity in allRemaining) {
        if (result.length >= targetCount) break;
        if (added.add(activity)) {
          result.add(activity);
        }
      }
    }

    return result;
  }

  static int _seedFromNow() {
    final now = DateTime.now();
    return now.year + now.month + now.day;
  }
}

```

## 5.3) AI Chat Module (chat_service.dart)
```dart
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

  /// Clear user context (call on logout)
  void clearUserContext() {
    _userId = null;
    _userContext = {};
    clearHistory();
    appLogger.i('ChatService user context cleared');
  }
}

```
