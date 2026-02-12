import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ProgressMiniChart extends StatelessWidget {
  final String userId;

  const ProgressMiniChart({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('routine_completions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(7)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final docs = snapshot.data!.docs;
        final completionData = <int, double>{}; // weekday -> completion %

        for (var doc in docs) {
           final data = doc.data() as Map<String, dynamic>;
           final date = (data['date'] as Timestamp).toDate();
           
           int completed = 0;
           int total = 1; // avoid divide by zero
           
           if (data['completedActivities'] != null) {
              completed = (data['completedActivities'] as List).length;
           }
           if (data['totalActivities'] != null) {
              total = (data['totalActivities'] as num).toInt();
           }
           if (total == 0) total = 1;
           
           completionData[date.weekday] = (completed / total).clamp(0.0, 1.0);
        }

        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
        final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                 'Consistency',
                 style: GoogleFonts.lato(
                   fontSize: 16,
                   fontWeight: FontWeight.bold,
                   color: AppColors.textPrimary,
                 ),
               ),
               const SizedBox(height: 16),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: List.generate(7, (index) {
                    final date = weekDays[index];
                    final label = dayLabels[index];
                    // Correct weekday mapping
                    // weekDays[0] is Sunday. date.weekday is 7 for Sunday.
                    // completionData key is 1..7 (Mon..Sun)
                    final completion = completionData[date.weekday] ?? 0.0;
                    
                    return Column(
                      children: [
                        Container(
                          width: 8,
                          height: 40,
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            heightFactor: completion > 0 ? completion : 0.0, // avoid 0 height crash if any logic issues
                            child: Container(
                              decoration: BoxDecoration(
                                color: completion > 0.8 ? AppColors.success : 
                                       (completion > 0.4 ? AppColors.warning : AppColors.error),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: date.day == now.day ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                 }),
               ),
            ],
          ),
        );
      },
    );
  }
}
