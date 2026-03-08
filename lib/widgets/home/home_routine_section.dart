import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/routine_config.dart';

class HomeRoutineSection extends StatelessWidget {
  final List<String> selectedActivities;
  final Map<String, String> temporarySchedule;
  final Map<String, String> routineSchedule;
  final TimeOfDay wakeTime;
  final TimeOfDay bedTime;
  final List<String> completedActivities;
  final Color textColor;
  final Function(String, bool) onToggleActivity;
  final int streak;

  const HomeRoutineSection({
    super.key,
    required this.selectedActivities,
    required this.temporarySchedule,
    required this.routineSchedule,
    required this.wakeTime,
    required this.bedTime,
    required this.completedActivities,
    required this.onToggleActivity,
    required this.textColor,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Logic extracted from original _buildInlineRoutineSection
    List<String> activities = selectedActivities;
    if (activities.isEmpty) {
      activities = ['Morning Sunlight', 'Delay Caffeine', 'Dim Lights'];
    }

    final morningItems = <String>[];
    final afternoonItems = <String>[];
    final eveningItems = <String>[];

    for (var activity in activities) {
      // Always recalculate the period from RoutineConfig for known activities.
      // This prevents stale Firestore labels (e.g. old "Evening" string saved
      // before a config fix) from overriding the authoritative period mapping.
      final configPeriod = RoutineConfig.getTimePeriod(activity);

      String category;
      if (configPeriod == 'Morning' ||
          configPeriod == 'Afternoon' ||
          configPeriod == 'Evening') {
        // RoutineConfig returned a valid period — trust it.
        category = configPeriod;
      } else {
        // RoutineConfig returned a time string (edge-case / custom activity).
        // Fall back to parsing the Firestore schedule time string.
        final rawPeriod =
            temporarySchedule[activity] ??
            routineSchedule[activity] ??
            configPeriod;
        try {
          final t = _parseTime(rawPeriod);
          final double val = t.hour + t.minute / 60.0;
          if (val < 12.0) {
            category = 'Morning';
          } else if (val < 17.0)
            category = 'Afternoon';
          else
            category = 'Evening';
        } catch (e) {
          category = 'Morning';
        }
      }

      switch (category) {
        case 'Morning':
          morningItems.add(activity);
          break;
        case 'Afternoon':
          afternoonItems.add(activity);
          break;
        case 'Evening':
          eveningItems.add(activity);
          break;
        default:
          morningItems.add(activity);
      }
    }

    final now = TimeOfDay.now();
    final double currentDouble = now.hour + now.minute / 60.0;
    final double wakeDouble = wakeTime.hour + wakeTime.minute / 60.0;
    bool isMorningUnlocked =
        currentDouble >= wakeDouble && currentDouble < 12.0;
    bool isAfternoonUnlocked = currentDouble >= 12.0 && currentDouble < 17.0;
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
                  color: textColor,
                ),
              ),
              if (activities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${completedActivities.where((a) => activities.contains(a)).length} of ${activities.length}',
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
            context,
            'Morning',
            Icons.wb_sunny_rounded,
            const Color(0xFFFDBB2D),
            morningItems,
            isMorningUnlocked,
          ),
          const SizedBox(height: 20),
        ],
        if (afternoonItems.isNotEmpty) ...[
          _buildRoutineSection(
            context,
            'Afternoon',
            Icons.wb_twilight_rounded,
            const Color(0xFF22C1C3),
            afternoonItems,
            isAfternoonUnlocked,
          ),
          const SizedBox(height: 20),
        ],
        if (eveningItems.isNotEmpty) ...[
          _buildRoutineSection(
            context,
            'Evening',
            Icons.nights_stay,
            const Color(0xFF6C5CE7),
            eveningItems,
            isEveningUnlocked,
          ),
          const SizedBox(height: 20),
        ],

        // Streak indicator
        if (streak > 0)
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
                  '$streak-day streak!',
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

  Widget _buildRoutineSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> items,
    bool isUnlocked,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: !isUnlocked ? Colors.grey : color, size: 20),
            const SizedBox(width: 8),
            Text(
              title + (!isUnlocked ? ' (Locked)' : ''),
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: !isUnlocked ? Colors.grey : textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => _RoutineItemCard(
            title: item,
            subtitle: '',
            textColor: textColor,
            isCompleted: completedActivities.contains(item),
            isEnabled: isUnlocked,
            onInfoTap: RoutineConfig.getTaskInfo(item) != null
                ? () => _showActivityInfo(context, item)
                : null,

            onToggle: (val) {
              if (val) {
                // Confirm dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text(
                      "Complete Task?",
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                    ),
                    content: Text("Mark '$item' as complete?"),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text("Confirm"),
                        onPressed: () {
                          Navigator.pop(context);
                          onToggleActivity(item, true);
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // Assuming uncheck is allowed or handled by parent, but original logic prevented it via confirm?
                // Original logic: "Prevent unchecking" if (!completed) return; inside onToggle.
                // Here val IS the new state (true if checking, false if unchecking).
                // So if val is false, we try to uncheck.
                onToggleActivity(item, false);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Shows the same styled info bottom sheet used in Manage Routine.
  static void _showActivityInfo(BuildContext context, String activity) {
    final info = RoutineConfig.getTaskInfo(activity);
    final description = info?['description'];
    final howTo = info?['howTo'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => Container(
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
                        color: Colors.white.withOpacity(0.2),
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Inter',
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
                          const Text(
                            'What it means',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.6,
                            color: Color(0xFF2D2D2D),
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
                          const Text(
                            'How to do it',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00B89A),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B89A).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          howTo,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.7,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (description == null && howTo == null)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No details available for this activity yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontStyle: FontStyle.italic,
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

  TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final period = parts[1];

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }
}

class _RoutineItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? textColor;
  final bool isCompleted;
  final bool isEnabled;
  final Function(bool) onToggle;
  final VoidCallback? onInfoTap;

  const _RoutineItemCard({
    required this.title,
    required this.subtitle,
    this.textColor,
    required this.isCompleted,
    this.isEnabled = true,
    required this.onToggle,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled
          ? () {
              // Toggle logic handled by parent via callback, but we pass desired state?
              // Actually, best to just signal "I was tapped".
              // But for compatibility with existing logic:
              // note: logic in parent (original code) checks `!completed` to prevent unchecking.
              // so we pass `!isCompleted` as the target state.
              onToggle(!isCompleted);
            }
          : null,
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
                    blurRadius: 8, // Fixed
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF55EFC4)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF55EFC4)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: !isEnabled && !isCompleted
                        ? const Center(
                            child: Icon(
                              Icons.lock,
                              size: 14,
                              color: Colors.grey,
                            ),
                          )
                        : (isCompleted
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )
                              : null),
                  ),
                  const SizedBox(width: 16),
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
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
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
                  // Info icon — only for known activities (not user-created ones)
                  if (onInfoTap != null)
                    GestureDetector(
                      onTap: onInfoTap,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
