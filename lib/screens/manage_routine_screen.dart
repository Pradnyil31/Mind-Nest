import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/logger.dart';
import '../providers/app_providers.dart';
import '../config/motive_config.dart';
import '../config/notification_content.dart';
import '../config/routine_config.dart';

class ManageRoutineScreen extends ConsumerStatefulWidget {
  const ManageRoutineScreen({super.key});

  @override
  ConsumerState<ManageRoutineScreen> createState() =>
      _ManageRoutineScreenState();
}

class _ManageRoutineScreenState extends ConsumerState<ManageRoutineScreen> {
  String? _userMotive;
  Map<String, String> _activitySchedule = {}; // activity -> time period
  List<String> _customActivities = [];
  bool _isLoading = true;
  bool _isFirstTimeSetup = false;

  // User's personalized schedule (default fallback)
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);

  // All available activities
  final List<String> _allActivities = [
    // Sleep-related
    'Evening wind-down ritual',
    'Limit screens 1hr before bed',
    'Progressive muscle relaxation',
    'Sleep meditation',
    'Consistent sleep schedule',
    'Caffeine cutoff (2pm)',
    'Bedroom environment check',
    // Stress-related
    'Morning mindfulness',
    'Stress check-in',
    'Physical activity',
    'Breathing breaks',
    'Gratitude journaling',
    'Evening reflection',
    'Digital detox time',
    'Self-care moment',
    // Anxiety-related
    'Grounding exercises',
    'Worry journaling',
    'Gentle movement',
    'Mindful breathing',
    'Positive affirmations',
    'Safe space meditation',
    'Anxiety check-in',
    'Self-compassion practice',
    // Focus-related
    'Morning intention setting',
    'Focus sessions (Pomodoro)',
    'Digital detox periods',
    'Concentration meditation',
    'Task prioritization',
    'Energy management',
    'Mindful breaks',
    'Evening review',
    // Habit Building
    'Daily habit tracking',
    'Morning routine',
    'Evening routine',
    'Habit stacking practice',
    'Progress review',
    'Consistency check-in',
    'Celebration moments',
    'Reflection journaling',
    // General wellness
    'Drink water',
    'Healthy eating',
    'Exercise',
    'Nature time',
    'Social connection',
    'Creative activity',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRoutine();
  }

  Map<String, String> _initialSchedule = {};

  Future<void> _loadUserRoutine() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final doc = await ref
          .read(firestoreServiceProvider)
          .getUserStream(user.uid)
          .first;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        _userMotive = data['primaryMotive'] as String?;

        List<String> pool = [];
        if (data.containsKey('customActivitiesPool')) {
          pool = List<String>.from(data['customActivitiesPool']);
        }

        if (data.containsKey('routineActivities')) {
          // Load activity list and recalculate ALL periods fresh from RoutineConfig
          // (never trust stale Firestore period values for known activities)
          final baseList = List<String>.from(data['routineActivities']);
          final schedule = <String, String>{};
          for (var activity in baseList) {
            schedule[activity] = RoutineConfig.getTimePeriod(activity);
          }

          setState(() {
            _activitySchedule = schedule;

            // Merge temporarySchedule ONLY for custom activities that RoutineConfig
            // doesn't know about — so user's manual period choices are preserved,
            // but known activities always use the fresh RoutineConfig period.
            if (data.containsKey('temporarySchedule')) {
              final temp = Map<String, String>.from(data['temporarySchedule']);
              temp.forEach((activity, period) {
                // Only override if it's a custom activity (not in our known set)
                if (!_allActivities.contains(activity)) {
                  _activitySchedule[activity] = period;
                }
              });
            }

            _initialSchedule = Map.from(_activitySchedule);
            var custom = baseList
                .where((a) => !_allActivities.contains(a))
                .toList();
            for (var activity in pool) {
              if (!custom.contains(activity) &&
                  !_allActivities.contains(activity)) {
                custom.add(activity);
              }
            }
            _customActivities = custom;
          });
        } else if (data.containsKey('routineSchedule')) {
          // Recalculate all known activity periods fresh — don't trust stale Firestore periods
          final firestoreSchedule = Map<String, String>.from(
            data['routineSchedule'],
          );
          final recalculated = <String, String>{};
          for (final activity in firestoreSchedule.keys) {
            if (_allActivities.contains(activity)) {
              // Known activity → always use the authoritative RoutineConfig period
              recalculated[activity] = RoutineConfig.getTimePeriod(activity);
            } else {
              // Custom activity → preserve the user's saved period
              recalculated[activity] = firestoreSchedule[activity]!;
            }
          }
          final custom = recalculated.keys
              .where((a) => !_allActivities.contains(a))
              .toList();

          setState(() {
            _activitySchedule = recalculated;
            _initialSchedule = Map.from(recalculated);

            for (var activity in pool) {
              if (!custom.contains(activity) &&
                  !_allActivities.contains(activity)) {
                custom.add(activity);
              }
            }
            _customActivities = custom;

            // Parse user's sleep/wake times if available
            if (data.containsKey('routine')) {
              final routine = data['routine'] as Map<String, dynamic>;
              if (routine.containsKey('wakeUpTime')) {
                _wakeTime = _parseTime(routine['wakeUpTime']);
              }
              if (routine.containsKey('bedTime')) {
                _bedTime = _parseTime(routine['bedTime']);
              }
            }
          });
        } else if (data.containsKey('routineActivities')) {
          // Old format migration
          final oldActivities = List<String>.from(data['routineActivities']);
          final schedule = <String, String>{};

          for (var activity in oldActivities) {
            schedule[activity] = _suggestTimePeriod(activity);
          }

          setState(() {
            _activitySchedule = schedule;
            _initialSchedule = Map.from(schedule);

            var custom = oldActivities
                .where((a) => !_allActivities.contains(a))
                .toList();
            for (var activity in pool) {
              if (!custom.contains(activity) &&
                  !_allActivities.contains(activity)) {
                custom.add(activity);
              }
            }
            _customActivities = custom;
          });
        } else {
          // First time setup
          _isFirstTimeSetup = true;
          // ... (rest of logic)
          // After setting schedule:
          // _initialSchedule = Map.from(schedule);
        }
      }
    }
    setState(() => _isLoading = false);
  }

  String _suggestTimePeriod(String activity) {
    if (activity.toLowerCase().contains('caffeine')) return 'Afternoon';
    return RoutineConfig.getTimePeriod(activity);
  }

  Future<void> _saveRoutine() async {
    setState(() => _isLoading = true);
    final user = ref.read(authServiceProvider).currentUser;

    if (user != null) {
      try {
        // 1. Identify newly added activities (to reset their completion status if previously checked today)
        final newActivities = _activitySchedule.keys
            .where((a) => !_initialSchedule.containsKey(a))
            .toList();

        // 2. Unmark them in Firestore so they appear as "To Do"
        for (final activity in newActivities) {
          try {
            await ref
                .read(routineServiceProvider)
                .unmarkActivityComplete(user.uid, activity);
          } catch (e, stackTrace) {
            // Ignore individual unmark failures to prevent blocking save
            appLogger.e(
              'Failed to unmark $activity',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }

        // 3. Build the final schedule:
        //    The user sees and selects period labels (Morning / Afternoon / Evening).
        //    We translate each label into a precise clock time using getOptimalTimeSlot,
        //    passing the user's chosen period as `periodOverride` so that if the user
        //    moved an activity to a different period, the clock time reflects that choice.
        final newActivitiesList = _activitySchedule.keys.toList();
        final Map<String, String> newSchedule = {};
        for (final activity in newActivitiesList) {
          // _activitySchedule holds the user-selected period label, e.g. 'Evening'.
          // Pass it as an override so the optimal time is anchored to that period.
          final userPeriod = _activitySchedule[activity]; // 'Morning'/'Afternoon'/'Evening'
          newSchedule[activity] = RoutineConfig.getOptimalTimeSlot(
            activity,
            wakeHour   : _wakeTime.hour,
            wakeMinute : _wakeTime.minute,
            bedHour    : _bedTime.hour,
            bedMinute  : _bedTime.minute,
            periodOverride: userPeriod,
          );
        }

        // 4. Save new format
        final now = DateTime.now();
        await ref.read(firestoreServiceProvider).updateUser(user.uid, {
          'routineSchedule': newSchedule,
          'temporarySchedule': newSchedule, // Sync temp schedule too
          // Update both baseRoutine and routineActivities to stay in sync
          'baseRoutine': newActivitiesList,
          'routineActivities': newActivitiesList,
          'customActivitiesPool': _customActivities,

          // Stamp today's date so the daily generator doesn't overwrite this
          // customization until tomorrow's fresh generation.
          'lastGeneratedDate': now.toIso8601String(),
        });

        // 5. Schedule Notifications
        try {
          final userDoc = await ref
              .read(firestoreServiceProvider)
              .getUserOnce(user.uid);
          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data() as Map<String, dynamic>;
            final name = data['displayName'] ?? 'there';
            final motive = data['primaryMotive'] ?? 'Wellness';
            final notificationService = ref.read(notificationServiceProvider);

            await notificationService.init();
            await notificationService.requestPermissions();
            
            // Only cancel routine-specific notifications (IDs 1-4)
            // instead of wiping EVERYTHING (Achievements, Calm reminders, etc.)
            for (int i = 1; i <= 4; i++) {
              await notificationService.cancel(i);
            }

            // Wake Up
            await notificationService.scheduleDailyNotification(
              id: 1,
              title: 'Good Morning!',
              body: NotificationContent.getMorningMessage(name, motive),
              hour: _wakeTime.hour,
              minute: _wakeTime.minute,
            );

            // Midday (Wake + 6 hours)
            final midday = _wakeTime.hour + 6;
            final middayHour = midday >= 24 ? midday - 24 : midday;
            await notificationService.scheduleDailyNotification(
              id: 2,
              title: 'Check In',
              body: NotificationContent.getAfternoonMessage(name),
              hour: middayHour,
              minute: _wakeTime.minute,
            );

            // Evening (Bed - 2 hours)
            final evening = _bedTime.hour - 2;
            final eveningHour = evening < 0 ? evening + 24 : evening;
            await notificationService.scheduleDailyNotification(
              id: 3,
              title: 'Wind Down',
              body: NotificationContent.getEveningMessage(name),
              hour: eveningHour,
              minute: _bedTime.minute,
            );

            // Bedtime
            await notificationService.scheduleDailyNotification(
              id: 4,
              title: 'Sweet Dreams',
              body: NotificationContent.getBedtimeMessage(name),
              hour: _bedTime.hour,
              minute: _bedTime.minute,
            );
          }
        } catch (e, stackTrace) {
          appLogger.e(
            'Notification scheduling failed',
            error: e,
            stackTrace: stackTrace,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFirstTimeSetup
                    ? '✨ Your personalized routine is set!'
                    : '✓ Routine updated successfully!',
              ),
              backgroundColor: const Color(0xFF6C63FF),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save routine: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleActivity(String activity) {
    // Check if time period is locked
    String targetPeriod =
        _activitySchedule[activity] ?? _suggestTimePeriod(activity);

    bool isLocked = false;

    // Personalized Locking Logic
    final nowTime = TimeOfDay.now();
    final double currentDouble = nowTime.hour + nowTime.minute / 60.0;

    // Morning: Ends at 12:00 PM
    if (targetPeriod == 'Morning') {
      // Locked if it's past 12:00 PM
      if (currentDouble >= 12.0) isLocked = true;
    }

    // Afternoon: Starts 12:00 PM, Ends 5:00 PM
    if (targetPeriod == 'Afternoon') {
      // Locked if it's past 5:00 PM
      if (currentDouble >= 17.0) isLocked = true;
    }

    // Evening: Starts 5:00 PM
    // (No lock for evening generally, as it's the last phase)

    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit past routines today.')),
      );
      return;
    }

    setState(() {
      if (_activitySchedule.containsKey(activity)) {
        _activitySchedule.remove(activity);
      } else {
        // Add with default time period
        _activitySchedule[activity] = _suggestTimePeriod(activity);
      }
    });
  }

  Future<void> _changeTimePeriod(String activity) async {
    final currentPeriod =
        _activitySchedule[activity] ?? _suggestTimePeriod(activity);
    final newPeriod = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('When do you do this?', style: GoogleFonts.lato()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimePeriodOption(
              'Morning',
              Icons.wb_sunny_rounded,
              const Color(0xFFFDBB2D),
              currentPeriod,
            ),
            const SizedBox(height: 8),
            _buildTimePeriodOption(
              'Afternoon',
              Icons.wb_twilight_rounded,
              const Color(0xFF22C1C3),
              currentPeriod,
            ),
            const SizedBox(height: 8),
            _buildTimePeriodOption(
              'Evening',
              Icons.nights_stay_rounded,
              const Color(0xFF6C5CE7),
              currentPeriod,
            ),
          ],
        ),
      ),
    );

    if (newPeriod != null && newPeriod != currentPeriod) {
      setState(() {
        _activitySchedule[activity] = newPeriod;
      });
    }
  }

  Widget _buildTimePeriodOption(
    String period,
    IconData icon,
    Color color,
    String? currentPeriod,
  ) {
    final isSelected = period == currentPeriod;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        period,
        style: GoogleFonts.lato(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF6C63FF))
          : null,
      tileColor: isSelected ? color.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => Navigator.pop(context, period),
    );
  }

  Future<void> _showAddCustomActivityDialog() async {
    String newActivity = '';
    String selectedPeriod = 'Morning';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_task,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Custom Activity',
                              style: GoogleFonts.lato(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create your own routine activity',
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Activity name input
                      Text(
                        'Activity Name',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'e.g., Read a Book, Practice Piano',
                          hintStyle: GoogleFonts.lato(
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF667EEA),
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF667EEA),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: GoogleFonts.lato(fontSize: 15),
                        onChanged: (value) => newActivity = value,
                      ),

                      const SizedBox(height: 24),

                      // Time period selection
                      Text(
                        'When will you do this?',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePeriodChip(
                              'Morning',
                              Icons.wb_sunny_rounded,
                              const Color(0xFFFDBB2D),
                              selectedPeriod == 'Morning',
                              () => setDialogState(
                                () => selectedPeriod = 'Morning',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTimePeriodChip(
                              'Afternoon',
                              Icons.wb_twilight_rounded,
                              const Color(0xFF22C1C3),
                              selectedPeriod == 'Afternoon',
                              () => setDialogState(
                                () => selectedPeriod = 'Afternoon',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTimePeriodChip(
                              'Evening',
                              Icons.nights_stay_rounded,
                              const Color(0xFF6C5CE7),
                              selectedPeriod == 'Evening',
                              () => setDialogState(
                                () => selectedPeriod = 'Evening',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (newActivity.trim().isNotEmpty) {
                              setState(() {
                                _customActivities.add(newActivity.trim());
                                _activitySchedule[newActivity.trim()] =
                                    selectedPeriod;
                              });
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF667EEA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add Activity',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  Widget _buildTimePeriodChip(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motiveProfile = MotiveConfig.getProfile(_userMotive);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF4),
      appBar: AppBar(
        title: Text(
          _isFirstTimeSetup ? 'Set Up Your Routine' : 'Manage Routine',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: Text(
              'Save',
              style: GoogleFonts.lato(
                color: const Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddCustomActivityDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: Text(
            'Add Custom',
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Motive header
                if (motiveProfile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667EEA).withValues(alpha: 0.1),
                          const Color(0xFF764BA2).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          motiveProfile.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                motiveProfile.displayName,
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isFirstTimeSetup
                                    ? 'Tap activities to add them, then set when you\'ll do them'
                                    : 'Tap time badges to change when you do each activity',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                _buildRecommendedSection(),
                _buildOtherActivitiesSection(),
                if (_customActivities.isNotEmpty) _buildCustomSection(),

                const SizedBox(height: 80),
              ],
            ),
    );
  }

  Widget _buildRecommendedSection() {
    final recommended = MotiveConfig.getRoutineActivities(_userMotive);
    final profile = MotiveConfig.getProfile(_userMotive);

    if (recommended.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFF6C63FF),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Recommended for ${profile?.displayName ?? "You"}',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...recommended.map(
          (activity) => _buildActivityTile(
            activity,
            const Color(0xFF6C63FF),
            isRecommended: true,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOtherActivitiesSection() {
    final recommended = MotiveConfig.getRoutineActivities(_userMotive);
    final otherActivities = _allActivities
        .where((a) => !recommended.contains(a))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.grid_view_rounded,
              color: Color(0xFF95A5A6),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Other Activities',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...otherActivities.map(
          (activity) => _buildActivityTile(activity, const Color(0xFF95A5A6)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFF7675)),
            const SizedBox(width: 8),
            Text(
              'My Custom Activities',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._customActivities.map(
          (activity) => _buildActivityTile(activity, const Color(0xFFFF7675)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showTaskInfoSheet(String activity) {
    final info = RoutineConfig.getTaskInfo(activity);
    final description = info?['description'];
    final howTo = info?['howTo'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDFCF4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Gradient header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        activity,
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (description != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Color(0xFF6C63FF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What it means',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C63FF),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6C63FF,
                          ).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          description,
                          style: GoogleFonts.lato(
                            fontSize: 14.5,
                            height: 1.6,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (howTo != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.checklist_rounded,
                            color: Color(0xFF00B89A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to do it',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00B89A),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00B89A,
                          ).withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          howTo,
                          style: GoogleFonts.lato(
                            fontSize: 14.5,
                            height: 1.8,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                    ],
                    if (description == null && howTo == null) ...[
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This is your custom activity!',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You defined this activity yourself.\nMake it meaningful and repeat it daily.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Got it!',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(
    String activity,
    Color color, {
    bool isRecommended = false,
  }) {
    final isSelected = _activitySchedule.containsKey(activity);

    // Determine time period (either scheduled or default)
    final timePeriod =
        _activitySchedule[activity] ?? _suggestTimePeriod(activity);

    // Check lock state
    bool isLocked = false;
    final nowTime = TimeOfDay.now();
    final double currentDouble = nowTime.hour + nowTime.minute / 60.0;

    if (timePeriod == 'Morning' && currentDouble >= 12.0) isLocked = true;
    if (timePeriod == 'Afternoon' && currentDouble >= 17.0) isLocked = true;

    // Dynamic Naming for Caffeine Cutoff
    String displayActivity = activity;
    if (activity.toLowerCase().contains('caffeine cutoff')) {
      // Calculate 10 hours before bed time
      final bedDouble = _bedTime.hour + _bedTime.minute / 60.0;
      double cutoffDouble = bedDouble - 10.0;
      if (cutoffDouble < 0) cutoffDouble += 24.0;

      final cutoffHour = cutoffDouble.floor();
      final cutoffMinute = ((cutoffDouble - cutoffHour) * 60).round();
      final cutoffTime = TimeOfDay(hour: cutoffHour, minute: cutoffMinute);

      displayActivity = 'Caffeine cutoff (${cutoffTime.format(context)})';
    }

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot modify locked routine activities.'),
            ),
          );
        } else {
          _toggleActivity(activity);
        }
      },
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? Colors.grey.shade300
                  : (isSelected ? color : Colors.transparent),
              width: isRecommended && isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              if (!isSelected && !isLocked)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLocked
                        ? Colors.grey.shade400
                        : (isSelected ? color : Colors.grey.shade400),
                    width: 2,
                  ),
                ),
                child: isLocked
                    ? const Icon(Icons.lock, size: 14, color: Colors.grey)
                    : (isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayActivity,
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: isRecommended
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isLocked ? Colors.grey : const Color(0xFF2D2D2D),
                      ),
                    ),
                    if (isLocked)
                      Text(
                        'Locked ($timePeriod passed)',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: Colors.red.shade300,
                        ),
                      ),
                  ],
                ),
              ),
              // Info icon — only for known activities (not user-created ones)
              if (RoutineConfig.getTaskInfo(activity) != null)
                GestureDetector(
                  onTap: () => _showTaskInfoSheet(activity),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              // Time Badge & Edit Button
              InkWell(
                onTap: isLocked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot edit past routines today.'),
                          ),
                        );
                      }
                    : () => _changeTimePeriod(activity),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.grey.shade200
                        : _getTimePeriodColor(
                            timePeriod,
                          ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLocked
                          ? Colors.grey
                          : _getTimePeriodColor(timePeriod),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLocked ? Icons.lock : _getTimePeriodIcon(timePeriod),
                        size: 14,
                        color: isLocked
                            ? Colors.grey
                            : _getTimePeriodColor(timePeriod),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLocked ? 'Locked' : timePeriod,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLocked
                              ? Colors.grey
                              : _getTimePeriodColor(timePeriod),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isRecommended && !isSelected && !isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('⭐', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTimePeriodColor(String period) {
    switch (period) {
      case 'Morning':
        return const Color(0xFFFDBB2D);
      case 'Afternoon':
        return const Color(0xFF22C1C3);
      case 'Evening':
        return const Color(0xFF6C5CE7);
      default:
        return Colors.grey;
    }
  }

  IconData _getTimePeriodIcon(String period) {
    switch (period) {
      case 'Morning':
        return Icons.wb_sunny_rounded;
      case 'Afternoon':
        return Icons.wb_twilight_rounded;
      case 'Evening':
        return Icons.nights_stay_rounded;
      default:
        return Icons.access_time;
    }
  }

  // Helper to parse "7:30 AM" string to TimeOfDay
  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(
        RegExp(r'[:\s]'),
      ); // Splitting by colon or space
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      bool isPM = timeString.toUpperCase().contains('PM');

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0; // Midnight

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

}

