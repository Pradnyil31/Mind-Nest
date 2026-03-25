import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../screens/manage_routine_screen.dart';

class HomeFocusCard extends StatelessWidget {
  final String displayName;
  final List<String> goals;
  final Map<String, dynamic> routine;
  final List<DateTime> loginDates;
  final String? primaryMotive;
  final String? todaysMotive;
  final Set<int> activeDaysThisWeek;
  final String? title;
  final String? subtitle;
  final String? hint;

  const HomeFocusCard({
    Key? key,
    required this.displayName,
    required this.goals,
    required this.routine,
    required this.loginDates,
    this.primaryMotive,
    this.todaysMotive,
    this.activeDaysThisWeek = const {},
    this.title,
    this.subtitle,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String todaysFocus = 'General Wellness';

    if (todaysMotive != null) {
      todaysFocus = todaysMotive!;
    } else if (primaryMotive != null) {
      todaysFocus = primaryMotive!;
    } else if (goals.isNotEmpty) {
      final index = DateTime.now().day % goals.length;
      todaysFocus = goals[index];
    }

    final String resolvedTitle = title ?? 'Start ${_getTimePeriod()} routine';
    final String? resolvedSubtitle = subtitle ?? 'Focus: $todaysFocus';

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ManageRoutineScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF8F0),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEAA7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: Color(0xFFFF7675), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedTitle,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                      if (resolvedSubtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          resolvedSubtitle,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: const Color(0xFF5E5E5E),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFFDBB2D), size: 20),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hint!,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _WeeklyTracker(
                    activeDaysThisWeek: activeDaysThisWeek,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _WeeklyTracker extends StatelessWidget {
  final Set<int> activeDaysThisWeek;

  const _WeeklyTracker({required this.activeDaysThisWeek});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start from Sunday of the current week
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekDays =
        List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekDays[index];
        final label = dayLabels[index];
        return _buildDayCircle(label, date.weekday, now);
      }),
    );
  }

  Widget _buildDayCircle(String dayLabel, int weekdayIndex, DateTime now) {
    final isToday = now.weekday == weekdayIndex;
    // A past or today day counts as active if it appears in activeDaysThisWeek
    final isActive = activeDaysThisWeek.contains(weekdayIndex);

    Color bgColor;
    Color textColor;
    Border? border;

    if (isToday && isActive) {
      // Today + completed: solid brand colour
      bgColor = const Color(0xFFF6903D);
      textColor = Colors.white;
      border = null;
    } else if (isToday) {
      // Today but not yet completed: orange outline
      bgColor = Colors.white;
      textColor = const Color(0xFFF6903D);
      border = Border.all(color: const Color(0xFFF6903D), width: 2);
    } else if (isActive) {
      // Previous day with completions: green fill
      bgColor = AppColors.primary.withOpacity(0.15);
      textColor = AppColors.primary;
      border = Border.all(color: AppColors.primary, width: 1.5);
    } else {
      // Inactive / future day
      bgColor = Colors.transparent;
      textColor = Colors.grey.shade400;
      border = null;
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: border,
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
}
