import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TodaysRoutineCard extends StatelessWidget {
  final List<String> allActivities;
  final List<String> completedActivities;
  final int streak;
  final Function(String) onActivityToggle;

  const TodaysRoutineCard({
    super.key,
    required this.allActivities,
    required this.completedActivities,
    required this.streak,
    required this.onActivityToggle,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = completedActivities.length;
    final totalCount = allActivities.length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      'Today\'s Routine',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$completedCount of $totalCount',
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

          // Activities list
          if (allActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No routine activities set. Add some in settings!',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: allActivities.length,
              itemBuilder: (context, index) {
                final activity = allActivities[index];
                final isCompleted = completedActivities.contains(activity);

                return GestureDetector(
                  onTap: () => onActivityToggle(activity),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF4CAF50)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activity,
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFF757575),
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Streak indicator
          if (streak > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
      ),
    );
  }
}

