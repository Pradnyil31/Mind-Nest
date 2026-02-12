import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calm_screen.dart';
import 'meditation_library_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:ui';
import 'sleep_recovery_screen.dart';
import 'breathing_screen.dart';
import 'smart_goals_screen.dart';
import 'journaling_screen.dart';
import 'mood_tracking_screen.dart';
import 'focus_screen.dart';
import 'manage_routine_screen.dart';
import 'daily_checkin_screen.dart';
import '../services/checkin_service.dart';
import '../services/routine_tracking_service.dart';
import '../services/progress_insights_service.dart';
import '../config/routine_config.dart';
import '../widgets/todays_routine_card.dart';
import '../widgets/progress_trend_card.dart';
import '../widgets/progress_mini_chart.dart';
import '../widgets/badge_notification.dart';
import 'badges_screen.dart';
import '../core/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final CheckInService _checkInService = CheckInService();
  bool _checkInCompleted = false;

  final List<Widget> _screens = [
    const HomeContent(),
    const CalmScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  Color _getBackgroundColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return const Color(0xFF87CEEB); // Morning Sky Blue
    } else if (hour >= 12 && hour < 17) {
      return const Color(0xFFFDB813).withOpacity(0.5); // Afternoon sunny/warm
    } else if (hour >= 17 && hour < 20) {
      return const Color(0xFF2C3E50); // Evening Dark Blue
    } else {
      return const Color(0xFF0F2027); // Night Very Dark
    }
  }

  String _getBackgroundImage() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'assets/images/background_morning.png';
    } else if (hour >= 12 && hour < 17) {
      return 'assets/images/background_afternoon.png';
    } else if (hour >= 17 && hour < 20) {
      return 'assets/images/background_evening.png';
    } else {
      return 'assets/images/background_night.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Solid background color fallback (prevents white-on-white text during image load)
        Container(color: _getBackgroundColor()),
        Positioned(
          top: -100, // Force extend upwards
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset(
            _getBackgroundImage(),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDFCF4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFFFDFCF4),
                selectedItemColor: const Color(0xFFA78BFA),
                unselectedItemColor: const Color(0xFFBDBDBD),
                selectedLabelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.spa_outlined),
                    activeIcon: Icon(Icons.spa_rounded),
                    label: 'Calm',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline),
                    activeIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Chat',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _todaysMotive;
  bool _hasCheckedMotive = false;
  final AuthService _authService = AuthService();
  final CheckInService _checkInService = CheckInService();
  bool _checkInCompleted = false;
  
  // Routine tracking
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);

  final RoutineTrackingService _routineService = RoutineTrackingService();
  final ProgressInsightsService _insightsService = ProgressInsightsService();
  // _completedActivities removed - using Stream now
  int _streak = 0;
  Set<int> _activeDaysThisWeek = {}; // Track which days have activity
  String _encouragingMessage = '✨ Keep going!';
  String _trendDirection = 'stable';
  List<String> _highlights = [];

  @override
  @override
  void initState() {
    super.initState();
    _checkCheckInStatus();
    
    // Listen for auth state availability before loading data
    _authService.authStateChanges.listen((user) {
      if (user != null && mounted) {
        _loadRoutineData();
        _loadActiveDaysThisWeek();
        _setupRoutineListener();
      }
    });

    // Try initial load in case auth is already ready
    if (_authService.currentUser != null) {
        _loadRoutineData();
        _loadActiveDaysThisWeek();
        _setupRoutineListener();
    }
  }
  
  void _setupRoutineListener() {
    final user = _authService.currentUser;
    if (user != null) {
      // Listen to user doc for 'lastGeneratedDate' changes
      FirestoreService().getUserStream(user.uid).listen((snapshot) {
        if (snapshot.exists && mounted) {
           final data = snapshot.data() as Map<String, dynamic>;
           final lastGen = data['lastGeneratedDate'] as String?;
            
           // If lastGen changed to yesterday (or just changed), we might need to regenerate
           // The _checkAndRegenerateDailyRoutine handles the date check logic.
           // We just need to trigger it.
           _checkAndRegenerateDailyRoutine(user.uid).then((_) {
              if (mounted) {
                 // Reload local state to reflect new routine
                 _loadRoutineData();
              }
           });
        }
      });
    }
  }
  
  Future<void> _loadRoutineData() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // Load completed activities and streak in parallel
        final results = await Future.wait([
          _routineService.getTodayCompletedActivities(user.uid),
          _routineService.getCompletionStreak(user.uid),
          _insightsService.getTrendDirection(user.uid),
          _insightsService.getWeeklyHighlights(user.uid),
          _insightsService.generateEncouragingMessage(user.uid),
        ]);
        
        // Check for daily routine regeneration
        await _checkAndRegenerateDailyRoutine(user.uid);

        // Also load user routine for time settings
        final doc = await FirestoreService().getUserStream(user.uid).first;
            
        if (mounted) {
          setState(() {
            // _completedActivities = results[0] as List<String>; // Removed
            _streak = results[1] as int;
            _trendDirection = results[2] as String;
            _highlights = results[3] as List<String>;
            _encouragingMessage = results[4] as String;
            
            if (doc.exists) {
               final data = doc.data() as Map<String, dynamic>;
               if (data.containsKey('routine')) {
                 final routine = data['routine'] as Map<String, dynamic>;
                 if (routine.containsKey('wakeUpTime')) {
                    _wakeTime = _parseTime(routine['wakeUpTime']);
                 }
                 if (routine.containsKey('bedTime')) {
                    _bedTime = _parseTime(routine['bedTime']);
                 }
               }
            }
          });
        }
      } catch (e) {
        // Silent fail - user will see empty state
      }
    }
  }
  
  Future<void> _checkAndRegenerateDailyRoutine(String uid) async {
    try {
      final doc = await FirestoreService().getUserStream(uid).first;
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final lastGenerated = data['lastGeneratedDate'] as String?;
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}"; // YYYY-MM-DD

      bool needsRegeneration = false;
      if (lastGenerated == null) {
        needsRegeneration = true;
      } else {
        final lastDate = DateTime.parse(lastGenerated);
        final lastDateStr = "${lastDate.year}-${lastDate.month}-${lastDate.day}";
        if (lastDateStr != todayStr) {
          needsRegeneration = true;
        }
      }

        // Parse wake/bed times early for self-correction too
        TimeOfDay currentWake = const TimeOfDay(hour: 7, minute: 0);
        TimeOfDay currentBed = const TimeOfDay(hour: 22, minute: 0);
        
        if (data.containsKey('routine')) {
           final r = data['routine'] as Map<String, dynamic>;
           if (r.containsKey('wakeUpTime')) currentWake = _parseTime(r['wakeUpTime']);
           if (r.containsKey('bedTime')) currentBed = _parseTime(r['bedTime']);
        }

        if (needsRegeneration) {
        
        List<String> baseRoutine = [];
        if (data.containsKey('baseRoutine')) {
           baseRoutine = List<String>.from(data['baseRoutine']);
        } else if (data.containsKey('routineActivities')) {
           // Fallback if base not set yet
           baseRoutine = List<String>.from(data['routineActivities']); 
        }

        final commitment = data['dailyCommitment'] as String? ?? '10 minutes';
        int limit = 5;
        if (commitment.startsWith('5 minutes')) limit = 3;
        else if (commitment.startsWith('10 minutes')) limit = 5;
        else if (commitment.startsWith('15 minutes')) limit = 6;
        else if (commitment.startsWith('30+ minutes')) limit = 8;
        
        // Take top N tasks
        final newDaily = baseRoutine.take(limit).toList();
        
        // Generate new schedule with specific times
        final newSchedule = _calculateDynamicSchedule(newDaily, currentWake, currentBed);
        
        // Save to Firestore
        await FirestoreService().updateUser(uid, {
          'routineActivities': newDaily,
          'routineSchedule': newSchedule, // Save the calculated times!
          'temporarySchedule': {}, // Clear temporary overrides for the new day
          'lastGeneratedDate': now.toIso8601String(),
        });
        
        print("Regenerated daily routine with $limit tasks");
      } else {
        // SELF-HEALING: Check for incorrect "Caffeine Cutoff" logic in existing schedule
        // If it's calculated as Wake + 10h (Evening), fix it to Bed - 10h (Afternoon)
        if (data.containsKey('routineSchedule')) {
          final schedule = Map<String, String>.from(data['routineSchedule']);
          bool needsFix = false;
          
          int bedMin = currentBed.hour * 60 + currentBed.minute;
          int wakeMin = currentWake.hour * 60 + currentWake.minute;
          if (bedMin < wakeMin) bedMin += 24 * 60; // handle midnight wrap

          schedule.forEach((activity, time) {
              if (activity.toLowerCase().contains('caffeine') && 
                  (activity.toLowerCase().contains('cut') || activity.toLowerCase().contains('off'))) {
                  
                  // Expected correct time: Bed - 10h
                  final correctTime = _minToTime(bedMin - 10 * 60); // e.g. 10pm -> 12pm
                  
                  // If current time is Evening (e.g. > 5pm) or just different, fix it
                  if (time != correctTime) {
                      print("🩹 Self-healing Caffeine Cutoff: $time -> $correctTime");
                      schedule[activity] = correctTime;
                      needsFix = true;
                  }
              }
          });
          
          if (needsFix) {
             await FirestoreService().updateUser(uid, {
               'routineSchedule': schedule,
             });
             print("✅ Applied self-healing fix to schedule.");
          }
        }
      }
    } catch (e) {
      print("Error regenerating routine: $e");
    }
  }

  Future<void> _toggleActivity(String activity, List<String> allActivities, bool isCompleted) async {
    final user = _authService.currentUser;
    if (user == null) return;
    
    try {
      // Update Firestore (Stream will update UI automatically)
      if (isCompleted) {
        await _routineService.unmarkActivityComplete(user.uid, activity);
      } else {
        await _routineService.markActivityComplete(user.uid, activity, allActivities);
        
        // Check for new badges after marking complete
        if (mounted) {
          _checkForNewBadges(user.uid);
        }
      }
      
      // Update stats (streak)
      _routineService.getCompletionStreak(user.uid).then((streak) {
         if (mounted) setState(() => _streak = streak);
      });
      
    } catch (e) {
      appLogger.e('Error toggling activity', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update activity')),
        );
      }
    }
  }

  
  Future<void> _loadActiveDaysThisWeek() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      
      final snapshot = await FirebaseFirestore.instance
          .collection('routine_completions')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();
      
      final activeDays = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['completedActivities'] != null && 
            (data['completedActivities'] as List).isNotEmpty) {
          final date = (data['date'] as Timestamp).toDate();
          activeDays.add(date.weekday);
        }
      }
      
      if (mounted) {
        setState(() {
          _activeDaysThisWeek = activeDays;
        });
      }
    } catch (e) {
      appLogger.e('Error loading active days', error: e);
    }
  }
  
  /// Check for newly earned badges and show notification
  Future<void> _checkForNewBadges(String userId) async {
    try {
      print('🔍 Checking for new badges for user: $userId');
      final badges = await _insightsService.detectNewBadges(userId);
      print('🏆 Detected badges: ${badges.length}');
      
      // Show notification for newly earned badges
      if (badges.isNotEmpty && mounted) {
        for (final badge in badges) {
          print('📋 Badge: ${badge.name}, earnedDate: ${badge.earnedDate}');
          // Only show if just earned (earnedDate is today)
          if (badge.earnedDate != null) {
            final now = DateTime.now();
            final earnedDate = badge.earnedDate!;
            final isToday = earnedDate.year == now.year &&
                           earnedDate.month == now.month &&
                           earnedDate.day == now.day;
            
            print('📅 Is today? $isToday (now: $now, earned: $earnedDate)');
            
            if (isToday && mounted) {
              print('🎉 Showing badge notification: ${badge.name}');
              showBadgeNotification(context, badge);
              // Only show first new badge to avoid spam
              break;
            }
          }
        }
      } else {
        print('❌ No badges detected or widget unmounted');
      }
    } catch (e) {
      print('⛔ Error checking badges: $e');
    }
  }

  Future<void> _checkCheckInStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      final hasCheckedIn = await _checkInService.hasCheckedInToday(user.uid);
      if (mounted) {
        setState(() {
          _checkInCompleted = hasCheckedIn;
        });
      }
    }
  }

  Future<void> _handleMotiveCheck(BuildContext context, List<String> goals, String? primaryMotive) async {
    if (_hasCheckedMotive) {
      print('⚠️ Motive already checked. Skipping.');
      return;
    }
    _hasCheckedMotive = true;

    final user = AuthService().currentUser;
    if (user != null) {
      print('🔍 Checking daily motive for user: ${user.uid}');
      final motive = await FirestoreService().getDailyMotive(user.uid);
      print('📝 Existing motive: $motive');
      
      if (motive != null) {
        if (mounted) {
          setState(() {
            _todaysMotive = motive;
          });
        }
      } else {
        print('🚀 No motive found. Showing popup.');
        // Show if we have goals OR a primary motive OR just to force it (fallback options)
        if (mounted) {
           // Delay slightly to ensure UI is ready
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                print('✨ Calling _showDailyMotivePrompt');
                _showDailyMotivePrompt(context, goals, primaryMotive);
              } else {
                print('❌ Widget unmounted before popup could show');
              }
            });
        }
      }
    }
  }

  void _showDailyMotivePrompt(BuildContext context, List<String> goals, String? primaryMotive) {
    // Generate options based on goals and primary motive
    final options = _generateMotiveOptions(goals, primaryMotive);
    
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to choose
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon or illustration
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
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
                  fontFamily: 'Inter', // Assuming Inter or Lato is used
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'What is your main focus for today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF757575),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final user = AuthService().currentUser;
                      if (user != null) {
                        try {
                          await FirestoreService().saveDailyMotive(user.uid, option);
                          if (mounted) {
                            setState(() {
                               _todaysMotive = option;
                            });
                          }
                        } catch (e) {
                          print('Error saving motive: $e');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
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
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMotiveColor(String motive) {
    if (motive.contains('Sleep') || motive.contains('Rest')) return const Color(0xFF818CF8);
    if (motive.contains('Stress') || motive.contains('Calm')) return const Color(0xFF34D399);
    if (motive.contains('Focus') || motive.contains('Work')) return const Color(0xFFF472B6);
    return const Color(0xFFFBBF24); // Default
  }

  List<String> _generateMotiveOptions(List<String> goals, String? primaryMotive) {
    // Map goals/motives to daily specific motives
    final Map<String, List<String>> motiveMap = {
      'Improve Sleep': ['Sleep by 10 PM', 'No screens after 9 PM', 'Read a calming book'],
      'Sleep': ['Sleep by 10 PM', 'No screens after 9 PM', 'Relaxing breathing'],
      
      'Reduce Stress': ['Deep breathing breaks', 'Walk in nature', 'Start the day slowly'],
      'Stress': ['Deep breathing breaks', 'Walk in nature', 'Start the day slowly'],
      
      'Manage Anxiety': ['Grounding exercises', 'Journal my worries', 'Limit calming tea'],
      'Anxiety': ['Grounding exercises', 'Journal my worries', 'Positive affirmations'],
      
      'Improve Mood': ['Find one joy', 'Smile more', 'Connect with a friend'],
      'Improve Focus': ['Deep work block', 'Clear my workspace', 'Single-tasking today'],
      'Focus': ['Deep work block', 'Clear my workspace', 'Single-tasking today'],
      
      'Build Confidence': ['Speak up today', 'Wear something nice', 'Celebrate small wins'],
      'Habit Building': [' Stick to the plan', 'Review progress', 'Small steps today'],
      
      'Control Overthinking': ['Write it down', 'Focus on the present', 'Let go of what-ifs'],
    };

    final Set<String> options = {};
    
    // Add from goals
    for (final goal in goals) {
      if (motiveMap.containsKey(goal)) {
        options.addAll(motiveMap[goal]!);
      }
    }
    
    // Add from primary motive if needed
    if (primaryMotive != null && motiveMap.containsKey(primaryMotive)) {
       options.addAll(motiveMap[primaryMotive]!);
    }
    
    // Fallback if still empty
    if (options.isEmpty) {
      options.addAll(['Find balance', 'Be present', 'Take it easy', 'Focus on today']);
    }
    
    // Pick up to 3 random unique options
    final list = options.toList()..shuffle();
    return list.take(3).toList();
  }



  Color _getTextColor() {
    final now = TimeOfDay.now();
    final double currentDouble = now.hour + now.minute / 60.0;
    final double bedDouble = _bedTime.hour + _bedTime.minute / 60.0;
    
    // Check if it's "Night" (between bedtime and 5am)
    // Handle midnight crossing
    bool isNight = false;
    if (bedDouble < 5.0) { 
        // Example: Bed at 1 AM. Night is 1 AM to 5 AM.
        if (currentDouble >= bedDouble && currentDouble < 5.0) isNight = true;
    } else {
        // Normal case: Bed at 10 PM. Night is 10 PM to 24 or 0 to 5.
        if (currentDouble >= bedDouble || currentDouble < 5.0) isNight = true;
    }
    
    if (isNight) return Colors.white;
    
    // Also late evening fallback (8 PM+)
    if (currentDouble >= 20.0) return Colors.white;

    return const Color(0xFF2D2D2D);
  }

  String _getGreeting() {
    final now = TimeOfDay.now();
    final double currentDouble = now.hour + now.minute / 60.0;
    final double wakeDouble = _wakeTime.hour + _wakeTime.minute / 60.0;
    
    if (currentDouble < 12.0) {
       // It's morning, but is it "Early Morning" or "Good Morning"?
       if (currentDouble < wakeDouble) return 'Early Bird,';
       return 'Good Morning,';
    }
    if (currentDouble < 17.0) return 'Good Afternoon,';
    if (currentDouble < 21.0) return 'Good Evening,';
    return 'Good Night,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true, 
      body: SafeArea(
          child: StreamBuilder<User?>(
            stream: AuthService().authStateChanges,
            builder: (context, authSnapshot) {
              final currentUser = authSnapshot.data;
              if (currentUser == null) {
                 return const SizedBox(); // Empty instead of loader
              }
              return StreamBuilder<DocumentSnapshot>(
                key: ValueKey(currentUser.uid),
                stream: FirestoreService().getUserStream(currentUser.uid),
                builder: (context, snapshot) {
              List<String> goals = [];

              Map<String, dynamic> routine = {};
              List<String> additionalActivities = [];
              List<DateTime> loginDates = [];
              Map<String, dynamic> sleepDataAll = {};
              
              String displayName = 'User';
              
              if (!snapshot.hasData || !snapshot.data!.exists) {
                // Show empty state instead of loader
                return const SizedBox();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              goals = List<String>.from(data['primaryGoals'] ?? []);
              routine = Map<String, dynamic>.from(data['routine'] ?? {});
              final routineActivities = List<String>.from(data['routineActivities'] ?? []);
              additionalActivities = List<String>.from(data['additionalActivities'] ?? []);
              final temporarySchedule = Map<String, String>.from(data['temporarySchedule'] ?? {});
                
                // Parse Wake/Bed times from stream for accurate locking
                TimeOfDay currentWakeTime = const TimeOfDay(hour: 7, minute: 0);
                TimeOfDay currentBedTime = const TimeOfDay(hour: 22, minute: 0);
                if (routine.containsKey('wakeUpTime')) {
                    currentWakeTime = _parseTime(routine['wakeUpTime']);
                }
                if (routine.containsKey('bedTime')) {
                    currentBedTime = _parseTime(routine['bedTime']);
                }
                
                // Force include favorites
                final requiredFavorites = [
                  'Journaling',
                  'Focus Sessions',
                  'Breathing', 
                  'Meditation', 
                  'Smart Goals'
                ];
                
                // Ensure removed items are gone
                final itemsToRemove = ['Affirmations', 'Mood Tracking', 'Gentle Reminders', 'Recommendations'];
                for (var item in itemsToRemove) {
                   if (additionalActivities.contains(item)) {
                      additionalActivities.remove(item);
                   }
                }

                for (var item in requiredFavorites.reversed) {
                  if (!additionalActivities.contains(item)) {
                    additionalActivities.insert(0, item);
                  }
                }
                
                // Ensure it's removed if completed (in case it stuck in local state)
                if (_checkInCompleted) {
                  additionalActivities.remove('Daily Check-ins');
                }
                if (data['loginDates'] != null) {
                  loginDates = (data['loginDates'] as List<dynamic>)
                      .map((e) => (e as Timestamp).toDate())
                      .toList();
                }
                if (data['sleepData'] != null) {
                  sleepDataAll = Map<String, dynamic>.from(data['sleepData']);
                }
                displayName = data['displayName'] ?? 'User';
                

  
                String? primaryMotive = data['primaryMotive'] as String?;
  
                // Trigger checks
                if (!_hasCheckedMotive) {
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleMotiveCheck(context, goals, primaryMotive);
                   });
                }
              // }  <-- REMOVED closing brace


              // Check for sleep recovery condition
              final now = DateTime.now();
              final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
              final todaySleep = sleepDataAll[dateKey];
              
              // DEBUG: Uncomment next line to force show screen for testing
              // return SleepRecoveryScreen(sleepData: {'durationMinutes': 300, 'qualityScore': 45}, displayName: displayName);

              if (todaySleep != null) {
                final duration = todaySleep['durationMinutes'] as int? ?? 0;
                // Less than 6 hours (360 mins)
                if (duration < 360) {
                  return SleepRecoveryScreen(
                    sleepData: todaySleep,
                    displayName: displayName,
                  );
                }
              }
  
              return StreamBuilder<List<String>>(
                stream: RoutineTrackingService().getTodayCompletedActivitiesStream(currentUser.uid),
                builder: (context, completionSnapshot) {
                  final completedActivities = completionSnapshot.data ?? [];
                  
                  // Extract routineSchedule for display
                  Map<String, String> routineSchedule = {};
                  if (data['routineSchedule'] != null) {
                     routineSchedule = Map<String, String>.from(data['routineSchedule']);
                  }

                  return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100), 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Top Bar with Badges Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: _getTextColor().withOpacity(0.8),
                                  ),
                                ),
                                Text(
                                  displayName,
                                  style: GoogleFonts.lato(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _getTextColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badges Icon
                          IconButton(
                            onPressed: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BadgesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.emoji_events_rounded),
                            iconSize: 28,
                            color: const Color(0xFFFFA726),
                            tooltip: 'My Badges',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Favorites / Additional Activities (Moved to Top)
                       if (additionalActivities.isNotEmpty) ...[
                        Text(
                          'My Favorites',
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFavoritesList(additionalActivities, routine),
                        const SizedBox(height: 32),
                      ],
              const SizedBox(height: 20),


                      // Focus Card
                      _buildFocusCard(context, displayName, goals, routine, loginDates, primaryMotive),
                      
                      const SizedBox(height: 24),

                      // Daily Routine Section (Enhanced with completion tracking + streak)
                      // PASS LIVE COMPLETED ACTIVITIES AND SCHDEULE
                      _buildInlineRoutineSection(routineActivities, temporarySchedule, routineSchedule, currentWakeTime, currentBedTime, completedActivities),
                      
                      const SizedBox(height: 32),
   

  
                      // Progress Chart Section
                      ProgressMiniChart(userId: currentUser.uid),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
                }
              );
            },
          );
        },
      ),
    ),
  );
  }

  // Helper to parse "7:30 AM" string to TimeOfDay
  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts[1]; // AM or PM

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 7, minute: 0); // Default fallback
    }
  }



  Widget _buildRelaxingSoundsSection() {
    return Container(
      width: double.infinity,
      height: 200, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: AssetImage('assets/images/relaxing_sounds_bg.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3), 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                'New Collection',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Relaxing Sounds',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.headphones_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Drift off with calming audio',
                style: GoogleFonts.lato(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [
                     Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                     BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded, color: Color(0xFF5B54CC), size: 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String displayName) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFA78BFA), Color(0xFFF48FB1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFF3E5F5),
                child: Icon(Icons.person, color: Color(0xFFAB47BC)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
                style: GoogleFonts.lato(
                fontSize: 16,
                color: _getTextColor().withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              displayName,
              style: GoogleFonts.lato(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _getTextColor(),
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
             // Notification logic in future
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D2D2D), size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildIconCounter(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF555555)),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList(List<String> activities, Map<String, dynamic> routine) {
    if (activities.isEmpty) {
      // Fallback if no activities selected
      return SizedBox(
        height: 130,
        child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
               _buildFavoriteItem(
                label: 'Journaling', 
                icon: Icons.book_outlined,
                iconColor: const Color(0xFF4DB6AC),
              ),
              const SizedBox(width: 16),
              _buildFavoriteItem(
                label: 'Mood\nTracking', 
                icon: Icons.mood,
                iconColor: const Color(0xFFFFB74D),
              ),
              const SizedBox(width: 16),
               _buildFavoriteItem(label: 'Bamboo Forest', assetPath: 'assets/images/bamboo_forest_icon.png'),
            ],
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(activity, routine);
        },
      ),
    );
  }

  Widget _buildActivityItem(String activity, Map<String, dynamic> routine) {
    IconData icon;
    Color color;
    String label = activity;

    // Mapping logic
    switch (activity) {
      case 'Daily Check-ins':
        icon = Icons.calendar_today_outlined;
        color = const Color(0xFF6C63FF).withOpacity(0.8);
        label = 'Daily\nCheck-ins';
        break;

      case 'Journaling':
        icon = Icons.book_outlined;
        color = const Color(0xFF4DB6AC);
        break;

      case 'Focus Sessions':
        icon = Icons.timer_outlined;
        color = const Color(0xFF7986CB);
        label = 'Focus\nSessions';
        break;

      case 'Breathing':
        icon = Icons.air_rounded;
        color = const Color(0xFF4DD0E1);
        label = 'Breathe';
        break;
      case 'Meditation':
        icon = Icons.self_improvement_rounded;
        color = const Color(0xFF9575CD);
        label = 'Meditate';
        break;
      case 'Smart Goals':
        icon = Icons.flag_rounded;
        color = const Color(0xFF81C784);
        label = 'Goals';
        break;
      default:
        icon = Icons.star_outline;
        color = const Color(0xFFA78BFA);
    }

    return _buildFavoriteItem(
      label: label, 
      icon: icon, 
      iconColor: color,
      onTap: () async {
        Widget? screen;
        switch (activity) {
          case 'Focus Sessions':
             screen = const FocusScreen();
            break;

          case 'Breathing':
            screen = const BreathingScreen();
            break;
          case 'Meditation':
            screen = const MeditationLibraryScreen();
            break;
          case 'Smart Goals':
             screen = const SmartGoalsScreen();
            break;
          case 'Journaling':
            screen = const JournalingScreen();
            break;

          case 'Daily Check-ins':
            screen = const DailyCheckInScreen();
            break;
          // Add more cases as screens are built
        }
        
        if (screen != null) {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
          if (result == true && activity == 'Daily Check-ins') {
            await _checkCheckInStatus(); // Refresh status to hide button
            setState(() {}); // Trigger rebuild to update favorites list
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label feature coming soon!')),
          );
        }
      }
    );
  }

  Widget _buildFavoriteItem({
    required String label, 
    String? assetPath, 
    IconData? icon, 
    Color? iconColor,
    bool isMissing = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), // Increased opacity for better visibility
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2), // Cleaner white border
                  boxShadow: [
                    BoxShadow(
                      color: (iconColor ?? Colors.grey).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0), // Slightly smaller icon padding
                  child: assetPath != null && assetPath.isNotEmpty
                      ? Image.asset(assetPath, fit: BoxFit.contain)
                      : Icon(
                          icon ?? Icons.circle, 
                          color: iconColor ?? Colors.grey, 
                          size: 30
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard(BuildContext context, String displayName, List<String> goals, Map<String, dynamic> routine, List<DateTime> loginDates, String? primaryMotive) {
    // Determine today's focus based on date and goals
    String todaysFocus = 'General Wellness';
    String focusTitle = 'Be Present';
    
    if (_todaysMotive != null) {
       todaysFocus = _todaysMotive!; 
    } else if (primaryMotive != null) {
       todaysFocus = primaryMotive;
       // Map motive to title
       if (todaysFocus == 'Sleep') focusTitle = 'Rest Well';
       else if (todaysFocus == 'Stress') focusTitle = 'Calm Mind';
       else if (todaysFocus == 'Anxiety') focusTitle = 'Inner Peace';
       else if (todaysFocus == 'Focus') focusTitle = 'Deep Work';
       else if (todaysFocus == 'Habit Building') focusTitle = 'Build Habits';
       else focusTitle = todaysFocus;
       
    } else if (goals.isNotEmpty) {
      // Use day of year to rotate through goals
      final index = DateTime.now().day % goals.length;
      todaysFocus = goals[index];
      
      // Map goal to a punchy title
      if (todaysFocus.contains('Sleep')) focusTitle = 'Rest Well';
      else if (todaysFocus.contains('Stress')) focusTitle = 'Calm Mind';
      else if (todaysFocus.contains('Anxiety')) focusTitle = 'Inner Peace';
      else if (todaysFocus.contains('Focus')) focusTitle = 'Deep Work';
      else if (todaysFocus.contains('Mood')) focusTitle = 'Find Joy';
      else focusTitle = todaysFocus;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageRoutineScreen()));
      },
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8F0), // Beige background
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon Placeholder (Strawberry-like)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEAA7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_rounded, color: Color(0xFFFF7675), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start morning routine', // Static title as per reference or user Focus
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3436),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFDBB2D), size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildWeeklyTracker(loginDates)),

            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildDayCircle(String dayLabel, int weekdayIndex) {
    final now = DateTime.now();
    bool isToday = now.weekday == weekdayIndex;
    bool hasActivity = _activeDaysThisWeek.contains(weekdayIndex);
    
    Color bgColor = Colors.transparent;
    Color textColor = Colors.grey.shade400;
    Color? borderColor;

    if (isToday) {
      bgColor = Colors.white; // Current day has circle
      textColor = const Color(0xFFF6903D);
      borderColor = const Color(0xFFF6903D);
    } else if (hasActivity) {
      // Past/future days with activity get a subtle circle
      bgColor = Colors.white.withOpacity(0.3);
      textColor = Colors.black;
      borderColor = Colors.black;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
      ),
      child: Center(
        child: Text(
          dayLabel,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }



  Widget _buildBanner(List<DateTime> loginDates) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF4B8F98), // Teal color
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Build your routine and receive',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Special Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.spa, color: Color(0xFFF5C9D6), size: 24), // Flower placeholder
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildWeeklyTracker(loginDates),
                 const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6903D), // Orange
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Learn more',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPondSection() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFA5D687), // Grass green
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/pond_scene_bg.png'), // Will fail gracefully if missing? No, need error builder or placeholder
          fit: BoxFit.cover,
        ),
      ),
      // Use child for content overlay
      child: Stack(
        children: [
           // Check if image loads? We'll assume the Container color is the fallback unless Image throws.
           // Better to use a Stack with a fallback color container behind the image.
           
           // Pond graphic placeholder if image missing
           Positioned(
             top: 40,
             right: 20,
             child: Container(
               width: 200,
               height: 120,
               decoration: BoxDecoration(
                 color: const Color(0xFF88CCDD), // Water blue
                 borderRadius: const BorderRadius.all(Radius.elliptical(200, 120)),
               ),
             ),
           ),

           // 1/5 Badge
           Positioned(
             top: 20,
             left: 20,
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: const Color(0xFFF6903D),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: const Row(
                 children: [
                   Icon(Icons.water_drop, color: Colors.white, size: 16),
                   SizedBox(width: 4),
                   Text(
                     '1/5',
                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             ),
           ),

           // Duck Character on map
           Positioned(
             top: 150,
             left: 150,
             child: Container(
               width: 30,
               height: 30,
               decoration: const BoxDecoration(
                 color: Colors.white,
                 shape: BoxShape.circle,
               ),
               child: const Icon(Icons.catching_pokemon, size: 20, color: Colors.orange), // Duck placeholder
             ),
           ),

           // Free Trial Button
           Align(
             alignment: Alignment.bottomCenter,
             child: Padding(
               padding: const EdgeInsets.only(bottom: 20.0),
               child: Container(
                 width: double.infinity,
                 margin: const EdgeInsets.symmetric(horizontal: 40),
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF6903D), // Orange
                   borderRadius: BorderRadius.circular(30),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.1),
                       blurRadius: 10,
                       offset: const Offset(0, 4),
                     ),
                   ],
                 ),
                 child: const Text(
                   'Start 7-day FREE trial',
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             ),
           ),
           
           // Forward arrow
            Positioned(
             bottom: 80,
             right: 20,
             child: Container(
               width: 48,
               height: 48,
               decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.2),
                 shape: BoxShape.circle,
               ),
               child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
             ),
           ),
        ],
      ),
    );
  }
  Widget _buildCheckInCard() {
    return GestureDetector(
      onTap: _checkInCompleted ? null : () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyCheckInScreen()),
        );
        if (result == true) {
          setState(() {
            _checkInCompleted = true;
          });
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _checkInCompleted 
            ? LinearGradient(colors: [Colors.green.shade50, Colors.green.shade100])
            : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B9DFF)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
               color: const Color(0xFF6C63FF).withOpacity(0.3),
               blurRadius: 10,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _checkInCompleted ? Icons.check : Icons.wb_sunny,
                color: _checkInCompleted ? Colors.green : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _checkInCompleted ? 'Morning Check-in Complete' : 'Review your Morning',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _checkInCompleted ? Colors.green.shade800 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _checkInCompleted ? 'Have a great day!' : 'Log sleep & mood to adapt routine.',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: _checkInCompleted ? Colors.green.shade600 : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!_checkInCompleted)
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTracker(List<DateTime> loginDates) {
    // Determine the start of the current week (Sunday)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    
    // Create list of 7 days
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekDays[index];
        final label = dayLabels[index];

        // Adjusted logic for real-time highlighting
        // 1=Mon, ..., 7=Sun.
        // weekDays generated starting from Sunday (index 0).
        // So index 0 is Sunday. index 1 is Monday.
        
        // Correct weekday index for Sunday is 7 in Dart.
        // But our labels are S M T W T F S? 
        // We need to match label to day.
        // If we generate from Sunday:
        // index 0: Sunday.
        // index 1: Monday.
        
        // This helper uses weekdayIndex match.
        // Let's pass the actual weekday integer to the helper.
        return _buildDayCircle(label, date.weekday);
      }),
    );
  }

  // Available activities for categorization
  // Available activities map removed in favor of RoutineConfig

  Widget _buildInlineRoutineSection(List<String> selectedActivities, Map<String, String> temporarySchedule, Map<String, String> routineSchedule, TimeOfDay wakeTime, TimeOfDay bedTime, List<String> completedActivities) {
    if (selectedActivities.isEmpty) {
      // Default fallback if nothing selected
      selectedActivities = ['Morning Sunlight', 'Delay Caffeine', 'Dim Lights'];
    }

    // Categorize activities using centralized config + temporary overrides
    final morningItems = <String>[];
    final afternoonItems = <String>[];
    final eveningItems = <String>[];
    
    // We should also check if the user has a specific schedule override in the future.
    // For now, we use the centralized config.
    
    for (var activity in selectedActivities) {
        // Use temp schedule -> then generated routineSchedule -> then config
        String rawPeriod = temporarySchedule[activity] ?? routineSchedule[activity] ?? RoutineConfig.getTimePeriod(activity);
        String category = 'Morning'; // Default

        if (rawPeriod == 'Morning' || rawPeriod == 'Afternoon' || rawPeriod == 'Evening') {
           category = rawPeriod;
        } else {
           // Try to parse time
           try {
             // Use locally defined _parseTime or just quick parse if simple
             // We can reuse the _parseTime helper in this class
             final t = _parseTime(rawPeriod);
             final double val = t.hour + t.minute / 60.0;
             
             if (val < 12.0) category = 'Morning';
             else if (val < 17.0) category = 'Afternoon';
             else category = 'Evening';
           } catch (e) {
             category = 'Morning';
           }
        }
        
        // --- FORCE OVERRIDES (Fix for miscategorization regardless of time) ---
        final lower = activity.toLowerCase();
        if (lower.contains('caffeine')) {
             if (lower.contains('delay')) {
                 category = 'Morning';
             } else {
                 category = 'Afternoon';
             }
        } else if (lower.contains('morning') || lower.contains('wake') || lower.contains('breakfast')) {
             category = 'Morning';
        } else if (lower.contains('wind down') || lower.contains('sleep') || lower.contains('bed') || lower.contains('evening')) {
             category = 'Evening';
        }
        // ---------------------------------------------------------------------
        
        
        switch (category) {
            case 'Morning': morningItems.add(activity); break;
            case 'Afternoon': afternoonItems.add(activity); break;
            case 'Evening': eveningItems.add(activity); break;
            default: morningItems.add(activity); 
        }
    }

    final customItems = <String>[]; // RoutineConfig handles everything, but keep for fallback

    // Time checks
    // Strict Time Locking
    final now = TimeOfDay.now();
    final double currentDouble = now.hour + now.minute / 60.0;
    
    // Morning Window: WakeTime to 12:00 PM
    final double wakeDouble = wakeTime.hour + wakeTime.minute / 60.0;
    bool isMorningUnlocked = currentDouble >= wakeDouble && currentDouble < 12.0;
    
    // Afternoon Window: 12:00 PM to 5:00 PM
    bool isAfternoonUnlocked = currentDouble >= 12.0 && currentDouble < 17.0;
    
    // Evening Window: 5:00 PM onwards (until end of day)
    bool isEveningUnlocked = currentDouble >= 17.0;

    return Column(
      mainAxisSize: MainAxisSize.min, 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Routine',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(),
                ),
              ),
              // Progress counter
              if (selectedActivities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${completedActivities.where((a) => selectedActivities.contains(a)).length} of ${selectedActivities.length}',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
              if (morningItems.isNotEmpty) ...[
                  _buildRoutineSection(
                    'Morning', 
                    Icons.wb_sunny_rounded, 
                    const Color(0xFFFDBB2D), 
                    morningItems.map((title) => _buildRoutineItem(title, '', isEnabled: isMorningUnlocked, isCompleted: completedActivities.contains(title))).toList(),
                    isLocked: !isMorningUnlocked // Locked if not in window
                  ),
                 const SizedBox(height: 20),
              ],
              if (afternoonItems.isNotEmpty) ...[
                  _buildRoutineSection(
                    'Afternoon', 
                    Icons.wb_twilight_rounded, 
                    const Color(0xFF22C1C3), 
                    afternoonItems.map((title) => _buildRoutineItem(title, '', isEnabled: isAfternoonUnlocked, isCompleted: completedActivities.contains(title))).toList(),
                    isLocked: !isAfternoonUnlocked
                  ),
                 const SizedBox(height: 20),
              ],
              if (eveningItems.isNotEmpty) ...[
                  _buildRoutineSection(
                    'Evening', 
                    Icons.nights_stay, 
                    const Color(0xFF6C5CE7), 
                    eveningItems.map((title) => _buildRoutineItem(title, '', isEnabled: isEveningUnlocked, isCompleted: completedActivities.contains(title))).toList(),
                    isLocked: !isEveningUnlocked
                  ),
                 const SizedBox(height: 20),
              ],
              if (customItems.isNotEmpty) ...[
                 _buildRoutineSection(
                    'My Custom', 
                    Icons.star_rounded, 
                    const Color(0xFFFF7675), 
                    customItems.map((title) => _buildRoutineItem(title, '', isEnabled: true, isCompleted: completedActivities.contains(title))).toList(),
                    isLocked: false
                  ),
                 const SizedBox(height: 20),
              ],
              
              // Streak indicator
              if (_streak > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        '$_streak-day streak!',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
      ],
    );
  }

  Widget _buildRoutineSection(String title, IconData icon, Color color, List<Widget> items, {bool isLocked = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: isLocked ? Colors.grey : color, size: 20),
            const SizedBox(width: 8),
            Text(
              // Simple "Locked" label, or nothing if unlocked. 
              // We removed "Passed" because we now lock future too.
              title + (isLocked ? ' (Locked)' : ''),
              style: GoogleFonts.lato(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: isLocked ? Colors.grey : _getTextColor()
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildRoutineItem(String title, String subtitle, {bool isEnabled = true, bool isCompleted = false}) {
    return _RoutineItemCard(
      title: title, 
      subtitle: subtitle,
      textColor: _getTextColor(),
      // Pass isCompleted directly
      isCompleted: isCompleted,
      isEnabled: isEnabled,
      onToggle: (completed) {
        if (!isEnabled) return; 
        
        // Prevent unchecking
        if (!completed) { 
           return; 
        }

        // Confirm before checking
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  "Complete Task?",
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  "Are you sure you want to mark '$title' as complete? You cannot undo this action.",
                  style: GoogleFonts.lato(),
                ),
                actions: [
                    TextButton(
                      child: Text("Cancel", style: GoogleFonts.lato(color: Colors.grey)), 
                      onPressed: () => Navigator.pop(context)
                    ),
                    TextButton(
                      child: Text("Confirm", style: GoogleFonts.lato(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)), 
                      onPressed: () {
                        Navigator.pop(context);
                        // Mark as complete
                        _toggleActivity(title, [], false); 
                      }
                    ),
                ]
            )
        );
      },
    );
  }

  Map<String, String> _calculateDynamicSchedule(List<String> activities, TimeOfDay wakeTime, TimeOfDay bedTime) {
    final schedule = <String, String>{};
    
    // Convert to minutes for easier calculation
    int wakeMin = wakeTime.hour * 60 + wakeTime.minute;
    int bedMin = bedTime.hour * 60 + bedTime.minute;
    if (bedMin < wakeMin) bedMin += 24 * 60; // Handle past midnight
    
    int morningOffset = 0;
    int afternoonOffset = 0;
    
    // Afternoon starts at 12:00 PM or 5 hours after wake, whichever is later (to avoid cramping)
    int afternoonStart = 12 * 60; 
    if (afternoonStart < wakeMin + 4 * 60) afternoonStart = wakeMin + 4 * 60;
    
    // Evening starts at 6:00 PM
    int eveningStart = 18 * 60;
    
    for (var activity in activities) {
      String timeString = "";
      final lower = activity.toLowerCase();
      
      // 1. Fixed / Special Rules
      if (lower.contains('morning sun') || lower.contains('wake')) {
        timeString = _formatTimeOfDay(wakeTime);
      } else if (lower.contains('caffeine') && (lower.contains('cut') || lower.contains('delay'))) {
         // Delay Caffeine = Wake + 90 mins
         if (lower.contains('delay')) {
            timeString = _minToTime(wakeMin + 90);
         } 
         else {
            // Caffeine Cutoff = 10 hours before bed
            // e.g. Bed 10pm -> Cutoff 12pm
            timeString = _minToTime(bedMin - 10 * 60);
         }
      } else if (lower.contains('sleep') || lower.contains('bed time')) {
         timeString = _formatTimeOfDay(bedTime);
      } else if (lower.contains('wind down')) {
         timeString = _minToTime(bedMin - 60);
      } 
      
      // 2. Period Based Distribution
      else {
         final period = RoutineConfig.getTimePeriod(activity);
         if (period == 'Morning') {
            timeString = _minToTime(wakeMin + 15 + morningOffset);
            morningOffset += 30; // Spaced 30 mins
         } else if (period == 'Afternoon') {
            timeString = _minToTime(afternoonStart + afternoonOffset);
            afternoonOffset += 60; // Spaced 60 mins
         } else {
             // Evening - work backwards from bed? or forwards from 6pm?
             // Let's go forwards from 6pm
             timeString = _minToTime(eveningStart + (afternoonOffset > 0 ? 0 : 0)); 
             // Actually just stack them at 8pm?
             timeString = _minToTime(eveningStart + 60); // 7 PM default
         }
      }
      
      schedule[activity] = timeString;
    }
    
    return schedule;
  }
  
  String _minToTime(int totalMinutes) {
    // Normalize to 24h
    totalMinutes = totalMinutes % (24 * 60);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return "$h12:${m.toString().padLeft(2, '0')} $period";
  }
  
  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return "$h:$m $period";
  }
}

class _RoutineItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? textColor;
  final bool isCompleted;
  final bool isEnabled;
  final Function(bool) onToggle;

  const _RoutineItemCard({
    required this.title,
    required this.subtitle,
    this.textColor,
    required this.isCompleted,
    this.isEnabled = true,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? () {
        onToggle(!isCompleted);
      } : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Adaptive glass color based on completion
                color: isCompleted 
                    ? const Color(0xFF55EFC4).withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted 
                      ? const Color(0xFF55EFC4).withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF55EFC4) : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? const Color(0xFF55EFC4) : Colors.grey.shade400,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: !isEnabled && !isCompleted
                  ? const Center(
                      child: Icon(Icons.lock, size: 14, color: Colors.grey),
                    )
                  : (isCompleted
                      ? const Center(
                          child: Icon(Icons.check, size: 16, color: Colors.white),
                        )
                      : null),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted 
                          ? Colors.grey 
                          : (textColor ?? const Color(0xFF2D3436)),
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
      ),
    );
  }


}
