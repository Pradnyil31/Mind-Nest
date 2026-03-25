import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../models/routine_completion.dart';
import '../theme/app_colors.dart';

class ProgressMiniChart extends ConsumerWidget {
  final String userId;

  const ProgressMiniChart({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<RoutineCompletion>>(
      future: ref.read(routineServiceProvider).getWeekCompletions(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final completions = snapshot.data ?? const <RoutineCompletion>[];
        final completionData = <int, double>{}; // weekday -> completion %

        for (final completion in completions) {
          var total = completion.totalActivities;
          if (total == 0) total = 1; // Avoid divide-by-zero.
          completionData[completion.date.weekday] =
              (completion.completedActivities.length / total).clamp(0.0, 1.0);
        }

        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        final weekDays = List.generate(
          7,
          (index) => startOfWeek.add(Duration(days: index)),
        );
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
                          heightFactor: completion > 0 ? completion : 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: completion > 0.8
                                  ? AppColors.success
                                  : (completion > 0.4
                                      ? AppColors.warning
                                      : AppColors.error),
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
                          fontWeight: date.day == now.day
                              ? FontWeight.bold
                              : FontWeight.normal,
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


