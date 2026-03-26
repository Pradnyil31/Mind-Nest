import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/motive_config.dart';
import '../../../providers/app_providers.dart';
import '../../../services/personalization_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/badge_notification.dart';
import '../../../widgets/home/home_check_in_card.dart';
import '../../../widgets/home/home_favorites_list.dart';
import '../../../widgets/home/home_focus_card.dart';
import '../../../widgets/home/home_header.dart';
import '../../../widgets/home/home_routine_section.dart';
import '../../../widgets/home/personalized_recommendation_card.dart';
import '../../../widgets/home/home_ai_coach_card.dart';
import '../../../widgets/compact_progress_insights.dart';
import '../../../screens/daily_checkin_screen.dart';
import '../../../screens/breathing_screen.dart';
import '../../../screens/grounding_exercise_screen.dart';
import '../../../screens/meditation_library_screen.dart';
import '../../../screens/meditation_player_screen.dart';
import '../../../screens/journaling_screen.dart';
import '../../../screens/smart_goals_screen.dart';
import '../../../screens/calm_screen.dart';
import '../../../screens/sleep_recovery_screen.dart';
import '../../../screens/chat_screen.dart';
import '../../home/application/home_controller.dart';
import '../../home/application/home_routine_engine.dart';

/// Extracted Home content widget for the main Home tab.
///
/// This is largely the original implementation from `home_screen.dart`,
/// now living in the Home feature's presentation layer so that we can
/// progressively move logic into `HomeController` and `HomeState`.
class HomeContentView extends ConsumerStatefulWidget {
  const HomeContentView({super.key});

  @override
  ConsumerState<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends ConsumerState<HomeContentView> {
  String? _todaysMotive;
  bool _hasCheckedMotive = false;
  bool _checkInCompleted = false;
  Map<String, dynamic>? _todayCheckInData;

  // Routine tracking
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);

  Set<int> _activeDaysThisWeek = {};
  StreamSubscription<DocumentSnapshot>? _routineSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  void _initialLoad() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(homeControllerProvider.notifier).loadInitial(user.uid);
      _checkCheckInStatus(user.uid);
      _setupRoutineListener(user.uid);
      _loadActiveDaysThisWeek(user.uid);
    }
  }

  void _setupRoutineListener(String uid) {
    _routineSubscription?.cancel();
    _routineSubscription = ref
        .read(firestoreServiceProvider)
        .getUserStream(uid)
        .listen((snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data() as Map<String, dynamic>;
            _checkAndRegenerateDailyRoutine(uid, data);
          }
        });
  }

  Future<void> _loadActiveDaysThisWeek(String uid) async {
    try {
      final activeDays = await ref
          .read(routineServiceProvider)
          .getActiveDaysThisWeek(uid);

      if (mounted) {
        setState(() {
          _activeDaysThisWeek = activeDays;
        });
      }
    } catch (_) {
      // Ignore for now
    }
  }

  Future<void> _checkAndRegenerateDailyRoutine(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final lastGenerated = data['lastGeneratedDate'] as String?;
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    bool isNewDay = lastGenerated == null;
    if (!isNewDay) {
      final lastDate = DateTime.parse(lastGenerated);
      final lastDateStr = "${lastDate.year}-${lastDate.month}-${lastDate.day}";
      if (lastDateStr != todayStr) isNewDay = true;
    }

    // Always parse wake/bed times from Firestore
    if (data.containsKey('routine')) {
      final routine = data['routine'] as Map<String, dynamic>;
      if (routine.containsKey('wakeUpTime')) {
        _wakeTime = _parseTime(routine['wakeUpTime']);
      }
      if (routine.containsKey('bedTime')) {
        _bedTime = _parseTime(routine['bedTime']);
      }
    }

    if (isNewDay) {
      final motive = data['primaryMotive'] as String?;
      final commitment = data['dailyCommitment'] as String? ?? '10 minutes';

      int taskCount = 5;
      if (commitment.startsWith('5')) {
        taskCount = 3;
      } else if (commitment.startsWith('10')) {
        taskCount = 5;
      } else if (commitment.startsWith('15')) {
        taskCount = 6;
      } else if (commitment.startsWith('30')) {
        taskCount = 8;
      }

      final pool = MotiveConfig.getFullActivityPool(motive);
      final newDaily = HomeRoutineEngine.generateBalancedRoutine(pool, taskCount);
      final newSchedule = HomeRoutineEngine.calculateDynamicSchedule(
        newDaily,
        _wakeTime,
        _bedTime,
      );

      await ref.read(firestoreServiceProvider).updateUser(uid, {
        'routineActivities': newDaily,
        'routineSchedule': newSchedule,
        'temporarySchedule': {},
        'lastGeneratedDate': now.toIso8601String(),
      });
    } else {
      if (data.containsKey('routineSchedule')) {
        final schedule = Map<String, String>.from(data['routineSchedule']);
        bool needsFix = false;
        int bedMin = _bedTime.hour * 60 + _bedTime.minute;
        int wakeMin = _wakeTime.hour * 60 + _wakeTime.minute;
        if (bedMin < wakeMin) bedMin += 24 * 60;

        schedule.forEach((activity, time) {
          if (activity.toLowerCase().contains('caffeine') &&
              (activity.toLowerCase().contains('cut') ||
                  activity.toLowerCase().contains('off'))) {
            final correctTime = HomeRoutineEngine.minToTime(bedMin - 10 * 60);
            if (time != correctTime) {
              schedule[activity] = correctTime;
              needsFix = true;
            }
          }
        });
        if (needsFix) {
          await ref.read(firestoreServiceProvider).updateUser(uid, {
            'routineSchedule': schedule,
          });
        }
      }
    }
  }

  Future<void> _toggleActivity(
    String userId,
    String activity,
    bool isCompleted,
  ) async {
    try {
      if (!isCompleted) {
        await ref
            .read(routineServiceProvider)
            .unmarkActivityComplete(userId, activity);
      } else {
        final userDoc = await ref.read(firestoreServiceProvider).getUserOnce(userId);
        List<String> currentRoutine = [];
        if (userDoc.exists) {
          final data = userDoc.data();
          final mapData = data is Map<String, dynamic> ? data : <String, dynamic>{};
          currentRoutine = List<String>.from(mapData['routineActivities'] ?? []);
        }

        await ref
            .read(routineServiceProvider)
            .markActivityComplete(userId, activity, currentRoutine);
        if (mounted) _checkForNewBadges(userId);
      }

      // Refresh streak in the controller so HomeRoutineSection sees the updated value.
      await ref.read(homeControllerProvider.notifier).refreshStreak(userId);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update activity')),
      );
    }
  }

  Future<void> _checkForNewBadges(String userId) async {
    final badges = await ref
        .read(insightsServiceProvider)
        .detectNewBadges(userId);
    if (badges.isNotEmpty && mounted) {
      for (final badge in badges) {
        if (badge.earnedDate != null) {
          final now = DateTime.now();
          final isToday =
              badge.earnedDate!.year == now.year &&
              badge.earnedDate!.month == now.month &&
              badge.earnedDate!.day == now.day;

          if (isToday) {
            showBadgeNotification(context, badge);
            break;
          }
        }
      }
    }
  }

  Future<void> _checkCheckInStatus(String uid) async {
    final checkInService = ref.read(checkInServiceProvider);
    final hasCheckedIn = await checkInService.hasCheckedInToday(uid);
    Map<String, dynamic>? checkInData;
    if (hasCheckedIn) {
      checkInData = await checkInService.getTodayCheckIn(uid);
    }
    if (mounted) {
      setState(() {
        _checkInCompleted = hasCheckedIn;
        _todayCheckInData = checkInData;
      });
    }
  }

  String _buildRecommendationSubtitle({
    String? primaryMotive,
    String? experienceLevel,
    String? mood,
  }) {
    if (mood != null && mood.isNotEmpty) {
      return 'Based on your check-in: feeling $mood today.';
    }
    if (primaryMotive != null && primaryMotive.isNotEmpty) {
      return 'Picked for your ${primaryMotive.toLowerCase()} focus.';
    }
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      return 'Matched to where you are right now.';
    }
    return 'A calm pick to support your day.';
  }

  void _openRecommendation(RecommendedExercise recommendation) {
    Widget? target;
    switch (recommendation.routeKey) {
      case 'breathing':
        target = const BreathingScreen();
        break;
      case 'grounding':
        target = const GroundingExerciseScreen();
        break;
      case 'journaling':
        target = const JournalingScreen();
        break;
      case 'meditation':
        if (recommendation.meditation != null) {
          target = MeditationPlayerScreen(meditation: recommendation.meditation!);
        } else {
          target = const MeditationLibraryScreen();
        }
        break;
      case 'goals':
        target = const SmartGoalsScreen();
        break;
      case 'calm':
        target = const CalmScreen();
        break;
      case 'checkin':
        target = const DailyCheckInScreen();
        break;
      default:
        target = null;
    }

    if (target == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => target!));
  }

  Future<void> _handleMotiveCheck(
    BuildContext context,
    List<String> goals,
    String? primaryMotive,
  ) async {
    if (_hasCheckedMotive) return;
    _hasCheckedMotive = true;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final motive = await ref
          .read(firestoreServiceProvider)
          .getDailyMotive(user.uid);

      if (motive != null) {
        if (mounted) {
          setState(() {
            _todaysMotive = motive;
          });
        }
      } else {
        if (mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _showDailyMotivePrompt(context, goals, primaryMotive);
          });
        }
      }
    }
  }

  void _showDailyMotivePrompt(
    BuildContext context,
    List<String> goals,
    String? primaryMotive,
  ) {
    final options = _generateMotiveOptions(goals, primaryMotive);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Text('✨', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Good Morning!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'What is your main focus for today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        final user = ref.read(currentUserProvider);
                        if (user != null) {
                          try {
                            await ref
                                .read(firestoreServiceProvider)
                                .saveDailyMotive(user.uid, option);
                            if (mounted) {
                              setState(() {
                                _todaysMotive = option;
                              });
                            }
                          } catch (_) {
                            // Ignore
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getMotiveColor(option),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMotiveColor(String motive) {
    if (motive.contains('Sleep') || motive.contains('Rest')) {
      return const Color(0xFF818CF8);
    }
    if (motive.contains('Stress') || motive.contains('Calm')) {
      return const Color(0xFF34D399);
    }
    if (motive.contains('Focus') || motive.contains('Work')) {
      return const Color(0xFFF472B6);
    }
    return const Color(0xFFFBBF24);
  }

  List<String> _generateMotiveOptions(
    List<String> goals,
    String? primaryMotive,
  ) {
    final Map<String, List<String>> motiveMap = {
      'Improve Sleep': [
        'Sleep by 10 PM',
        'No screens after 9 PM',
        'Read a calming book',
      ],
      'Sleep': [
        'Sleep by 10 PM',
        'No screens after 9 PM',
        'Relaxing breathing',
      ],
      'Reduce Stress': [
        'Deep breathing breaks',
        'Walk in nature',
        'Start the day slowly',
      ],
      'Stress': [
        'Deep breathing breaks',
        'Walk in nature',
        'Start the day slowly',
      ],
      'Manage Anxiety': [
        'Grounding exercises',
        'Journal my worries',
        'Limit calming tea',
      ],
      'Anxiety': [
        'Grounding exercises',
        'Journal my worries',
        'Positive affirmations',
      ],
      'Improve Mood': ['Find one joy', 'Smile more', 'Connect with a friend'],
      'Improve Focus': [
        'Deep work block',
        'Clear my workspace',
        'Single-tasking today',
      ],
      'Focus': [
        'Deep work block',
        'Clear my workspace',
        'Single-tasking today',
      ],
      'Build Confidence': [
        'Speak up today',
        'Wear something nice',
        'Celebrate small wins',
      ],
      'Habit Building': [
        ' Stick to the plan',
        'Review progress',
        'Small steps today',
      ],
      'Control Overthinking': [
        'Write it down',
        'Focus on the present',
        'Let go of what-ifs',
      ],
    };

    final Set<String> options = {};
    for (final goal in goals) {
      if (motiveMap.containsKey(goal)) {
        options.addAll(motiveMap[goal]!);
      }
    }
    if (primaryMotive != null && motiveMap.containsKey(primaryMotive)) {
      options.addAll(motiveMap[primaryMotive]!);
    }
    if (options.isEmpty) {
      options.addAll([
        'Find balance',
        'Be present',
        'Take it easy',
        'Focus on today',
      ]);
    }

    final list = options.toList()..shuffle();
    return list.take(3).toList();
  }

  String _getGreetingFor(TimeOfDay wakeTime) {
    final now = TimeOfDay.now();
    final double current = now.hour + now.minute / 60.0;
    final double wake = wakeTime.hour + wakeTime.minute / 60.0;

    if (current < 12.0) {
      if (current < wake) return 'Early Bird,';
      return 'Good Morning,';
    }
    if (current < 17.0) return 'Good Afternoon,';
    if (current < 21.0) return 'Good Evening,';
    return 'Good Night,';
  }

  Color _getTextColorFor(TimeOfDay wakeTime, TimeOfDay bedTime) {
    final now = TimeOfDay.now();
    final double currentDouble = now.hour + now.minute / 60.0;
    final double bedDouble = bedTime.hour + bedTime.minute / 60.0;

    bool isNight = false;
    if (bedDouble < 5.0) {
      if (currentDouble >= bedDouble && currentDouble < 5.0) {
        isNight = true;
      }
    } else {
      if (currentDouble >= bedDouble || currentDouble < 5.0) {
        isNight = true;
      }
    }
    if (isNight) return Colors.white;
    if (currentDouble >= 20.0) return Colors.white;
    return AppColors.textPrimary;
  }

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      if (parts[1] == 'PM' && hour != 12) hour += 12;
      if (parts[1] == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  @override
  void dispose() {
    _routineSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox();

    final homeState = ref.watch(homeControllerProvider);

    return StreamBuilder<DocumentSnapshot>(
      stream: ref.watch(firestoreServiceProvider).getUserStream(user.uid),
      builder: (context, snapshot) {
        String displayName = homeState.displayName;
        List<String> goals = homeState.goals;
        Map<String, dynamic> routine = {};
        List<String> routineActivities = [];
        List<String> additionalActivities = [];
        String? primaryMotive;
        String? experienceLevel;
        List<String> supportAreas = <String>[];
        List<DateTime> loginDates = [];
        Map<String, dynamic> sleepDataAll = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          goals = List<String>.from(data['primaryGoals'] ?? goals);
          routine = Map<String, dynamic>.from(data['routine'] ?? {});

          final rawSchedule = Map<String, String>.from(
            data['routineSchedule'] ?? {},
          );
          if (rawSchedule.isNotEmpty) {
            routineActivities = rawSchedule.keys.toList();
          } else {
            routineActivities = List<String>.from(
              data['routineActivities'] ?? [],
            );
          }
          additionalActivities = List<String>.from(
            data['additionalActivities'] ?? [],
          );

          final requiredFavorites = [
            'Journaling',
            'Focus Sessions',
            'Breathing',
            'Meditation',
            'Smart Goals',
          ];
          final itemsToRemove = [
            'Affirmations',
            'Mood Tracking',
            'Gentle Reminders',
            'Recommendations',
          ];
          for (var item in itemsToRemove) {
            additionalActivities.remove(item);
          }
          for (var item in requiredFavorites.reversed) {
            if (!additionalActivities.contains(item)) {
              additionalActivities.insert(0, item);
            }
          }

          if (_checkInCompleted) {
            additionalActivities.remove('Daily Check-ins');
          }

          primaryMotive = data['primaryMotive'] as String?;
          experienceLevel = data['experienceLevel'] as String?;
          if (data['supportAreas'] != null) {
            supportAreas = List<String>.from(data['supportAreas']);
          }

          if (data['loginDates'] != null) {
            loginDates = (data['loginDates'] as List<dynamic>)
                .map((e) => (e as Timestamp).toDate())
                .toList();
          }
          if (data['sleepData'] != null) {
            sleepDataAll = Map<String, dynamic>.from(data['sleepData']);
          }

          if (!_hasCheckedMotive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleMotiveCheck(context, goals, primaryMotive);
            });
          }

          final now = DateTime.now();
          final dateKey =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          final todaySleep = sleepDataAll[dateKey];
          if (todaySleep != null) {
            final duration = todaySleep['durationMinutes'] as int? ?? 0;
            if (duration < 360) {
              return SleepRecoveryScreen(
                sleepData: todaySleep,
                displayName: displayName,
              );
            }
          }
        }

        return StreamBuilder<List<String>>(
          stream: ref
              .watch(routineServiceProvider)
              .getTodayCompletedActivitiesStream(user.uid),
          builder: (context, completionSnapshot) {
            final completedActivities = completionSnapshot.data ?? [];

            Map<String, String> temporarySchedule = {};
            Map<String, String> routineSchedule = {};
            TimeOfDay effectiveWakeTime = _wakeTime;
            TimeOfDay effectiveBedTime = _bedTime;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              temporarySchedule = Map<String, String>.from(
                data['temporarySchedule'] ?? {},
              );
              routineSchedule = Map<String, String>.from(
                data['routineSchedule'] ?? {},
              );

              if (data.containsKey('routine')) {
                final r = data['routine'] as Map<String, dynamic>;
                if (r.containsKey('wakeUpTime')) {
                  effectiveWakeTime = _parseTime(r['wakeUpTime']);
                }
                if (r.containsKey('bedTime')) {
                  effectiveBedTime = _parseTime(r['bedTime']);
                }
              }
            }

            final textColor = _getTextColorFor(
              effectiveWakeTime,
              effectiveBedTime,
            );

            final topRecommendation = homeState.recommendation ??
                (() {
                  final recommendations = PersonalizationService.getRecommendations(
                    motive: primaryMotive,
                    experienceLevel: experienceLevel,
                    supportAreas: supportAreas,
                  );
                  return recommendations.isNotEmpty ? recommendations.first : null;
                })();
            final recommendationSubtitle = _buildRecommendationSubtitle(
              primaryMotive: primaryMotive,
              experienceLevel: experienceLevel,
              mood: _todayCheckInData?['mood'] as String?,
            );

            final bool hasRoutine = routineActivities.isNotEmpty;
            final String focusTitle =
                hasRoutine ? 'Continue your routine' : 'Start gently today';
            final String focusSubtitle = hasRoutine
                ? 'Pick up right where you left off.'
                : 'Build one calm habit today.';
            final String? focusHint =
                homeState.streak > 0 ? '${homeState.streak}-day streak' : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(
                    displayName: displayName,
                    greeting: _getGreetingFor(effectiveWakeTime),
                    textColor: textColor,
                  ),
                  const SizedBox(height: 20),
                  HomeCheckInCard(
                    isCompleted: _checkInCompleted,
                    checkInData: _todayCheckInData,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyCheckInScreen(),
                        ),
                      );
                      if (result == true) {
                        _checkCheckInStatus(user.uid);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  HomeFocusCard(
                    displayName: displayName,
                    goals: goals,
                    routine: routine,
                    loginDates: loginDates,
                    primaryMotive: primaryMotive,
                    todaysMotive: _todaysMotive,
                    activeDaysThisWeek: _activeDaysThisWeek,
                    title: focusTitle,
                    subtitle: focusSubtitle,
                    hint: focusHint,
                  ),
                  const SizedBox(height: 16),
                  if (topRecommendation != null) ...[
                    PersonalizedRecommendationCard(
                      recommendation: topRecommendation,
                      subtitle: recommendationSubtitle,
                      onTap: () => _openRecommendation(topRecommendation),
                    ),
                    const SizedBox(height: 16),
                  ],
                  HomeRoutineSection(
                    selectedActivities: routineActivities,
                    temporarySchedule: temporarySchedule,
                    routineSchedule: routineSchedule,
                    wakeTime: effectiveWakeTime,
                    bedTime: effectiveBedTime,
                    completedActivities: completedActivities,
                    onToggleActivity: (activity, checked) {
                      _toggleActivity(user.uid, activity, checked);
                    },
                    textColor: textColor,
                    streak: homeState.streak,
                  ),
                  const SizedBox(height: 16),
                  CompactProgressInsights(userId: user.uid),
                  const SizedBox(height: 16),
                  HomeAICoachCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                  ),
                  if (additionalActivities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Quick tools',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    HomeFavoritesList(
                      activities: additionalActivities,
                      routine: routine,
                      textColor: textColor,
                      onCheckInComplete: () {
                        _checkCheckInStatus(user.uid);
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

