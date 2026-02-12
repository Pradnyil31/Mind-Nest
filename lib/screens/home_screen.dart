import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:ui';

// Screens
import 'calm_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'badges_screen.dart';
import 'sleep_recovery_screen.dart';
import 'manage_routine_screen.dart';
import 'daily_checkin_screen.dart';

// Services & Providers
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/app_providers.dart';
import '../config/routine_config.dart';

// Theme & Config
import '../theme/app_colors.dart';
import '../widgets/common/safe_image.dart';

// Widgets
import '../widgets/home/home_header.dart';
import '../widgets/home/home_check_in_card.dart';
import '../widgets/home/home_focus_card.dart';
import '../widgets/home/home_routine_section.dart';
import '../widgets/home/home_favorites_list.dart';
import '../widgets/progress_mini_chart.dart';
import '../widgets/badge_notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const CalmScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  Color _getBackgroundColor() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return AppColors.morningSky;
    } else if (hour >= 12 && hour < 17) {
      return AppColors.afternoonSun.withOpacity(0.5);
    } else if (hour >= 17 && hour < 20) {
      return AppColors.eveningDark;
    } else {
      return AppColors.nightDark;
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
        // Background
        Container(color: _getBackgroundColor()),
        Positioned(
          top: -100,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeAssetImage(
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
              color: AppColors.backgroundLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
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
                backgroundColor: AppColors.backgroundLight,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.navBarUnselected,
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

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  String? _todaysMotive;
  bool _hasCheckedMotive = false;
  bool _checkInCompleted = false;
  
  // Routine tracking
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);

  int _streak = 0;
  Set<int> _activeDaysThisWeek = {}; 

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
       _checkCheckInStatus(user.uid);
       _loadRoutineData(user.uid);
       _setupRoutineListener(user.uid);
       _loadActiveDaysThisWeek(user.uid);
    }
  }
  
  void _setupRoutineListener(String uid) {
    ref.read(firestoreServiceProvider).getUserStream(uid).listen((snapshot) {
      if (snapshot.exists && mounted) {
         final data = snapshot.data() as Map<String, dynamic>;
         _checkAndRegenerateDailyRoutine(uid, data);
      }
    });
  }
  
  Future<void> _loadRoutineData(String uid) async {
      try {
        final streak = await ref.read(routineServiceProvider).getCompletionStreak(uid);
        if (mounted) {
          setState(() {
            _streak = streak;
          });
        }
      } catch (e) {
        // Silent fail
      }
  }

  Future<void> _loadActiveDaysThisWeek(String uid) async {
    // Logic to populate _activeDaysThisWeek based on routine completions
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      
      final snapshot = await FirebaseFirestore.instance 
          .collection('routine_completions')
          .where('userId', isEqualTo: uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();
      
      final activeDays = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
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
      // Ignore
    }
  }
  
  Future<void> _checkAndRegenerateDailyRoutine(String uid, Map<String, dynamic> data) async {
      final lastGenerated = data['lastGeneratedDate'] as String?;
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month}-${now.day}"; 

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

      if (data.containsKey('routine')) {
         final routine = data['routine'] as Map<String, dynamic>;
         if (routine.containsKey('wakeUpTime')) {
            _wakeTime = _parseTime(routine['wakeUpTime']);
         }
         if (routine.containsKey('bedTime')) {
            _bedTime = _parseTime(routine['bedTime']);
         }
      }

      if (needsRegeneration) {
        List<String> baseRoutine = [];
        if (data.containsKey('baseRoutine')) {
           baseRoutine = List<String>.from(data['baseRoutine']);
        } else if (data.containsKey('routineActivities')) {
           baseRoutine = List<String>.from(data['routineActivities']); 
        }

        final commitment = data['dailyCommitment'] as String? ?? '10 minutes';
        int limit = 5;
        if (commitment.startsWith('5 minutes')) limit = 3;
        else if (commitment.startsWith('10 minutes')) limit = 5;
        else if (commitment.startsWith('15 minutes')) limit = 6;
        else if (commitment.startsWith('30+ minutes')) limit = 8;
        
        final newDaily = baseRoutine.take(limit).toList();
        final newSchedule = _calculateDynamicSchedule(newDaily, _wakeTime, _bedTime);
        
        await ref.read(firestoreServiceProvider).updateUser(uid, {
          'routineActivities': newDaily,
          'routineSchedule': newSchedule, 
          'temporarySchedule': {}, 
          'lastGeneratedDate': now.toIso8601String(),
        });
      } else {
        // Self-healing check for Caffeine Cutoff
        if (data.containsKey('routineSchedule')) {
          final schedule = Map<String, String>.from(data['routineSchedule']);
          bool needsFix = false;
          
          int bedMin = _bedTime.hour * 60 + _bedTime.minute;
          int wakeMin = _wakeTime.hour * 60 + _wakeTime.minute;
          if (bedMin < wakeMin) bedMin += 24 * 60; 

          schedule.forEach((activity, time) {
              if (activity.toLowerCase().contains('caffeine') && 
                  (activity.toLowerCase().contains('cut') || activity.toLowerCase().contains('off'))) {
                  
                  final correctTime = _minToTime(bedMin - 10 * 60); 
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

  Future<void> _toggleActivity(String userId, String activity, bool isCompleted) async {
    try {
      if (!isCompleted) {
         await ref.read(routineServiceProvider).unmarkActivityComplete(userId, activity);
      } else {
         // Get current routine to pass total
         final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
         List<String> currentRoutine = [];
         if (userDoc.exists) {
            final data = userDoc.data();
            currentRoutine = List<String>.from(data?['routineActivities'] ?? []);
         }
         
         await ref.read(routineServiceProvider).markActivityComplete(userId, activity, currentRoutine);
         if (mounted) _checkForNewBadges(userId);
      }
      
      final streak = await ref.read(routineServiceProvider).getCompletionStreak(userId);
      if (mounted) setState(() => _streak = streak);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update activity')),
      );
    }
  }
  
  Future<void> _checkForNewBadges(String userId) async {
    final badges = await ref.read(insightsServiceProvider).detectNewBadges(userId);
    if (badges.isNotEmpty && mounted) {
       for (final badge in badges) {
          if (badge.earnedDate != null) {
              final now = DateTime.now();
              final isToday = badge.earnedDate!.year == now.year &&
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
    final hasCheckedIn = await ref.read(checkInServiceProvider).hasCheckedInToday(uid);
    if (mounted) {
      setState(() {
        _checkInCompleted = hasCheckedIn;
      });
    }
  }

  Future<void> _handleMotiveCheck(BuildContext context, List<String> goals, String? primaryMotive) async {
    if (_hasCheckedMotive) return;
    _hasCheckedMotive = true;

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final motive = await ref.read(firestoreServiceProvider).getDailyMotive(user.uid);
      
      if (motive != null) {
        if (mounted) setState(() => _todaysMotive = motive);
      } else {
        if (mounted) {
             Future.delayed(const Duration(seconds: 1), () {
               if (mounted) _showDailyMotivePrompt(context, goals, primaryMotive);
             });
        }
      }
    }
  }
  
  void _showDailyMotivePrompt(BuildContext context, List<String> goals, String? primaryMotive) {
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
                color: Colors.black.withOpacity(0.1),
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
              ...options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        try {
                          await ref.read(firestoreServiceProvider).saveDailyMotive(user.uid, option);
                          if (mounted) {
                            setState(() {
                               _todaysMotive = option;
                            });
                          }
                        } catch (e) {
                          // Ignore
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
    return const Color(0xFFFBBF24);
  }

  List<String> _generateMotiveOptions(List<String> goals, String? primaryMotive) {
    // Logic from original
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
    for (final goal in goals) {
      if (motiveMap.containsKey(goal)) {
        options.addAll(motiveMap[goal]!);
      }
    }
    if (primaryMotive != null && motiveMap.containsKey(primaryMotive)) {
       options.addAll(motiveMap[primaryMotive]!);
    }
    if (options.isEmpty) {
      options.addAll(['Find balance', 'Be present', 'Take it easy', 'Focus on today']);
    }
    
    final list = options.toList()..shuffle();
    return list.take(3).toList();
  }
  
  Color _getTextColor() {
     final now = TimeOfDay.now();
     final double currentDouble = now.hour + now.minute / 60.0;
     final double bedDouble = _bedTime.hour + _bedTime.minute / 60.0;
     
     bool isNight = false;
     if (bedDouble < 5.0) { 
         if (currentDouble >= bedDouble && currentDouble < 5.0) isNight = true;
     } else {
         if (currentDouble >= bedDouble || currentDouble < 5.0) isNight = true;
     }
     if (isNight) return Colors.white;
     if (currentDouble >= 20.0) return Colors.white;
     return AppColors.textPrimary;
  }
  
  String _getGreeting() {
    final now = TimeOfDay.now();
    final double current = now.hour + now.minute / 60.0;
    final double wake = _wakeTime.hour + _wakeTime.minute / 60.0;
    
    if (current < 12.0) {
       if (current < wake) return 'Early Bird,';
       return 'Good Morning,';
    }
    if (current < 17.0) return 'Good Afternoon,';
    if (current < 21.0) return 'Good Evening,';
    return 'Good Night,';
  }

  @override
  Widget build(BuildContext context) {
      final user = ref.watch(currentUserProvider);
      
      if (user == null) return const SizedBox();

      return StreamBuilder<DocumentSnapshot>(
        stream: ref.watch(firestoreServiceProvider).getUserStream(user.uid),
        builder: (context, snapshot) {
            String displayName = 'User';
            List<String> goals = [];
            Map<String, dynamic> routine = {};
            List<String> routineActivities = [];
            List<String> additionalActivities = [];
            String? primaryMotive;
            List<DateTime> loginDates = [];
            Map<String, dynamic> sleepDataAll = {};

            if (snapshot.hasData && snapshot.data!.exists) {
               final data = snapshot.data!.data() as Map<String, dynamic>;
               displayName = data['displayName'] ?? 'User';
               goals = List<String>.from(data['primaryGoals'] ?? []);
               routine = Map<String, dynamic>.from(data['routine'] ?? {});
               routineActivities = List<String>.from(data['routineActivities'] ?? []);
               additionalActivities = List<String>.from(data['additionalActivities'] ?? []);
               
               // Force include logic
               final requiredFavorites = ['Journaling', 'Focus Sessions', 'Breathing', 'Meditation', 'Smart Goals'];
               final itemsToRemove = ['Affirmations', 'Mood Tracking', 'Gentle Reminders', 'Recommendations'];
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
               
               if (data['loginDates'] != null) {
                  loginDates = (data['loginDates'] as List<dynamic>)
                      .map((e) => (e as Timestamp).toDate())
                      .toList();
               }
               if (data['sleepData'] != null) {
                  sleepDataAll = Map<String, dynamic>.from(data['sleepData']);
               }
               
               // Motive Check Trigger
               if (!_hasCheckedMotive) {
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleMotiveCheck(context, goals, primaryMotive);
                   });
               }
               
               // Sleep Recovery Logic (simplified view return check)
               final now = DateTime.now();
               final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
            } else {
               // Loading or empty state?
               // Return empty body or loading indicator
               // For now just empty stream builder waits
            }
            
            return StreamBuilder<List<String>>(
               stream: ref.watch(routineServiceProvider).getTodayCompletedActivitiesStream(user.uid),
               builder: (context, completionSnapshot) {
                  final completedActivities = completionSnapshot.data ?? [];
                  
                  // Need to access data from snapshot again safely or lift it
                  // To avoid heavy nesting, I duplicated extraction above. 
                  // But `data` is only available in first stream builder.
                  // Need to pass it down.
                  
                  Map<String, String> temporarySchedule = {};
                  Map<String, String> routineSchedule = {};
                  
                  if (snapshot.hasData && snapshot.data!.exists) {
                     final data = snapshot.data!.data() as Map<String, dynamic>;
                     temporarySchedule = Map<String, String>.from(data['temporarySchedule'] ?? {});
                     routineSchedule = Map<String, String>.from(data['routineSchedule'] ?? {});
                  }
                  
                  final textColor = _getTextColor();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 24.0),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             const SizedBox(height: 20),
                             
                             HomeHeader(
                               displayName: displayName, 
                               greeting: _getGreeting(),
                               textColor: textColor,
                             ),
                             
                             const SizedBox(height: 32),
                             
                             // Favorites
                             if (additionalActivities.isNotEmpty) ...[
                                Text(
                                  'My Favorites',
                                  style: GoogleFonts.lato(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                HomeFavoritesList(
                                  activities: additionalActivities, 
                                  routine: routine,
                                  textColor: textColor,
                                  onCheckInComplete: () {
                                     _checkCheckInStatus(user.uid);
                                  },
                                ),
                                const SizedBox(height: 32),
                             ],
                             
                             // Check In Card
                             if (!_checkInCompleted) ...[
                               HomeCheckInCard(
                                 isCompleted: _checkInCompleted,
                                 onTap: () async {
                                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyCheckInScreen()));
                                    if (result == true) {
                                       _checkCheckInStatus(user.uid);
                                    }
                                 }
                               ),
                               const SizedBox(height: 24),
                             ],
                             
                             HomeFocusCard(
                               displayName: displayName, 
                               goals: goals, 
                               routine: routine, 
                               loginDates: loginDates,
                               primaryMotive: primaryMotive,
                               todaysMotive: _todaysMotive,
                             ),
                             
                             const SizedBox(height: 24),
                             
                             HomeRoutineSection(
                               selectedActivities: routineActivities, 
                               temporarySchedule: temporarySchedule, 
                               routineSchedule: routineSchedule, 
                               wakeTime: _wakeTime, 
                               bedTime: _bedTime, 
                               completedActivities: completedActivities, 
                               onToggleActivity: (activity, checked) {
                                  _toggleActivity(user.uid, activity, checked);
                               }, 
                               textColor: textColor,
                               streak: _streak,
                             ),
                             
                             const SizedBox(height: 32),
                             
                             ProgressMiniChart(userId: user.uid),
                             
                             const SizedBox(height: 32),
                          ],
                       ),
                    ),
                  );
               },
            );
        },
      );
  }
  
  TimeOfDay _parseTime(String timeString) {
      try {
        final parts = timeString.split(' ');
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        if (parts[1] == 'PM' && hour != 12) hour += 12;
        if (parts[1] == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return const TimeOfDay(hour: 7, minute: 0);
      }
  }

  String _minToTime(int totalMinutes) {
    totalMinutes = totalMinutes % (24 * 60);
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return "$h12:${m.toString().padLeft(2, '0')} $period";
  }

  Map<String, String> _calculateDynamicSchedule(List<String> activities, TimeOfDay wakeTime, TimeOfDay bedTime) {
    final schedule = <String, String>{};
    
    int wakeMin = wakeTime.hour * 60 + wakeTime.minute;
    int bedMin = bedTime.hour * 60 + bedTime.minute;
    if (bedMin < wakeMin) bedMin += 24 * 60; 
    
    int morningOffset = 0;
    int afternoonOffset = 0;
    
    int afternoonStart = 12 * 60; 
    if (afternoonStart < wakeMin + 4 * 60) afternoonStart = wakeMin + 4 * 60;
    
    int eveningStart = 18 * 60;
    
    for (var activity in activities) {
      String timeString = "";
      final lower = activity.toLowerCase();
      
      if (lower.contains('morning sun') || lower.contains('wake')) {
        timeString = _formatTimeOfDay(wakeTime);
      } else if (lower.contains('caffeine') && (lower.contains('cut') || lower.contains('delay'))) {
         if (lower.contains('delay')) {
            timeString = _minToTime(wakeMin + 90);
         } 
         else {
            timeString = _minToTime(bedMin - 10 * 60);
         }
      } else if (lower.contains('sleep') || lower.contains('bed time')) {
         timeString = _formatTimeOfDay(bedTime);
      } else if (lower.contains('wind down')) {
         timeString = _minToTime(bedMin - 60);
      } 
      else {
         final period = RoutineConfig.getTimePeriod(activity);
         if (period == 'Morning') {
            timeString = _minToTime(wakeMin + 15 + morningOffset);
            morningOffset += 30; 
         } else if (period == 'Afternoon') {
            timeString = _minToTime(afternoonStart + afternoonOffset);
            afternoonOffset += 60; 
         } else {
             timeString = _minToTime(eveningStart + 60); 
         }
      }
      
      schedule[activity] = timeString;
    }
    
    return schedule;
  }
  
  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return "$h:$m $period";
  }
}
