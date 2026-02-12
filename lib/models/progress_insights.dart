class ProgressInsights {
  final DateTime date;
  final String trendDirection; // "improving", "stable", "needs_attention"
  final List<String> recentAchievements;

  ProgressInsights({
    required this.date,
    required this.trendDirection,
    required this.recentAchievements,
  });

  // Helper method to get encouraging message based on trend
  String get encouragingMessage {
    switch (trendDirection) {
      case 'improving':
        return '📈 You\'re on a roll!';
      case 'stable':
        return '🌟 Keeping steady!';
      case 'needs_attention':
        return '💪 Every day counts!';
      default:
        return '✨ Keep going!';
    }
  }

  // Get color for trend indicator
  String get trendColor {
    switch (trendDirection) {
      case 'improving':
        return '#4CAF50'; // Green
      case 'stable':
        return '#FFB74D'; // Yellow/Orange
      case 'needs_attention':
        return '#FF7675'; // Light Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
}
