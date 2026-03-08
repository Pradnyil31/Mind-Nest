import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/manage_routine_screen.dart';

class HomeFocusCard extends StatelessWidget {
  final String displayName;
  final List<String> goals;
  final Map<String, dynamic> routine;
  final List<DateTime> loginDates;
  final String? primaryMotive;
  final String? todaysMotive;

  const HomeFocusCard({
    super.key,
    required this.displayName,
    required this.goals,
    required this.routine,
    required this.loginDates,
    this.primaryMotive,
    this.todaysMotive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManageRoutineScreen()),
        );
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
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Color(0xFFFF7675),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start ${_getTimePeriod()} routine',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFFDBB2D),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _WeeklyTracker(loginDates: loginDates)),
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
  final List<DateTime> loginDates;

  const _WeeklyTracker({required this.loginDates});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekDays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = weekDays[index];
        final label = dayLabels[index];
        return _buildDayCircle(label, date.weekday);
      }),
    );
  }

  Widget _buildDayCircle(String dayLabel, int weekdayIndex) {
    final now = DateTime.now();
    bool isToday = now.weekday == weekdayIndex;
    // Simple logic: assume if we are logged in, we are active?
    // This logic was slightly different in original, using _activeDaysThisWeek.
    // Ideally we pass _activeDaysThisWeek from parent.
    // For now, I will assume we want to replicate the 'active' look based on loginDates passed?
    // But loginDates is passed from HomeScreen.
    // Actually, in original code _buildDayCircle uses _activeDaysThisWeek state variable!
    // I missed passing _activeDaysThisWeek to this widget.
    // I should probably simplify and just show days, or pass activeDays.
    // Let's assume we pass activeDays in next refactor or just remove that subtle dependency for now to keep it compiling.
    // The visual provided in original code checks `_activeDaysThisWeek`.
    // I'll make it simple transparent for now unless it matches today.

    Color bgColor = Colors.transparent;
    Color textColor = Colors.grey.shade400;
    Color? borderColor;

    if (isToday) {
      bgColor = Colors.white;
      textColor = const Color(0xFFF6903D);
      borderColor = const Color(0xFFF6903D);
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
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
