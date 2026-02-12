import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/progress_insights_service.dart';
import '../screens/progress_chart_screen.dart';

class ProgressMiniChart extends StatelessWidget {
  final String userId;

  const ProgressMiniChart({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final insightsService = ProgressInsightsService();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProgressChartScreen(userId: userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Activity',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 7 days',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded, // Changed icon to chart line
                    color: Color(0xFFAB47BC), // Soft Purple
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Line Chart
            SizedBox(
              height: 180,
              child: FutureBuilder<Map<DateTime, double>>(
                future: insightsService.getCompletionHistory(userId, 7),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Start completing tasks to see data!',
                        style: GoogleFonts.lato(
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final sortedEntries = data.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key));

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < 0 || value.toInt() >= sortedEntries.length) {
                                return const SizedBox();
                              }
                              final date = sortedEntries[value.toInt()].key;
                              final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dayName,
                                  style: GoogleFonts.lato(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (sortedEntries.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: sortedEntries
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                              .toList(),
                          isCurved: true,
                          preventCurveOverShooting: true,
                          curveSmoothness: 0.35,
                          color: const Color(0xFFAB47BC), // Soft Purple
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: const Color(0xFFAB47BC),
                              );
                            },
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
