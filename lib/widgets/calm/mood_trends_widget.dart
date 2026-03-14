import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget to display mood tracking trends and analytics
class MoodTrendsWidget extends StatelessWidget {
  final Map<String, dynamic> moodTrends;
  final Color primaryColor;

  const MoodTrendsWidget({
    super.key,
    required this.moodTrends,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  Widget build(BuildContext context) {
    final totalSessions = moodTrends['totalSessions'] as int? ?? 0;
    final averageImprovement =
        moodTrends['averageImprovement'] as double? ?? 0.0;
    final improvementTrend =
        moodTrends['improvementTrend'] as List<Map<String, dynamic>>? ?? [];
    final bestTechniques =
        moodTrends['bestTechniques'] as List<Map<String, dynamic>>? ?? [];

    if (totalSessions == 0) {
      return _buildEmptyState(context);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.trending_up, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Mood Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Sessions',
                    totalSessions.toString(),
                    Icons.psychology,
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg Improvement',
                    '${averageImprovement.toStringAsFixed(1)}/10',
                    Icons.mood,
                    _getImprovementColor(averageImprovement),
                  ),
                ),
              ],
            ),

            if (improvementTrend.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Recent Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: _buildImprovementChart(improvementTrend),
              ),
            ],

            if (bestTechniques.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Most Effective Techniques',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...bestTechniques
                  .take(3)
                  .map(
                    (technique) =>
                        _buildTechniqueEffectivenessItem(context, technique),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.mood_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Mood Data Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete techniques with mood tracking to see your progress trends',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementChart(List<Map<String, dynamic>> trendData) {
    final spots = trendData.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final improvement = (entry.value['improvement'] as int? ?? 0).toDouble();
      return FlSpot(index, improvement);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < trendData.length) {
                  return Text(
                    'S${value.toInt() + 1}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: (trendData.length - 1).toDouble(),
        minY: -5,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueEffectivenessItem(
    BuildContext context,
    Map<String, dynamic> technique,
  ) {
    final techniqueId = technique['techniqueId'] as String;
    final averageImprovement = technique['averageImprovement'] as double;
    final sessionCount = technique['sessionCount'] as int;

    // Convert technique ID to display name
    final displayName = _getTechniqueDisplayName(techniqueId);
    final improvementColor = _getImprovementColor(averageImprovement);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: improvementColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$sessionCount sessions',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${averageImprovement.toStringAsFixed(1)}/10',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: improvementColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getImprovementColor(double improvement) {
    if (improvement >= 3) {
      return Colors.green;
    } else if (improvement >= 1) {
      return Colors.orange;
    } else if (improvement >= 0) {
      return Colors.grey;
    } else {
      return Colors.red;
    }
  }

  String _getTechniqueDisplayName(String techniqueId) {
    switch (techniqueId) {
      case '5-4-3-2-1':
        return '5-4-3-2-1 Grounding';
      case 'positive-affirmations':
        return 'Calming Affirmations';
      case 'worry-banking':
        return 'Worry Banking';
      case 'cold-water-visualization':
        return 'Cold Water Reset';
      default:
        return techniqueId
            .replaceAll('-', ' ')
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : word,
            )
            .join(' ');
    }
  }
}
