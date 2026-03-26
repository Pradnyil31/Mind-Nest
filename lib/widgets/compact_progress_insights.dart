import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import 'dart:math' as math;

/// Compact progress insights widget - single card with dynamic content that auto-updates
class CompactProgressInsights extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic>? todayCheckInData;

  const CompactProgressInsights({
    super.key,
    required this.userId,
    this.todayCheckInData,
  });

  @override
  ConsumerState<CompactProgressInsights> createState() =>
      _CompactProgressInsightsState();
}

class _CompactProgressInsightsState
    extends ConsumerState<CompactProgressInsights>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _streak = 0;
  int _bestStreak = 0;
  int _weeklyActivities = 0;
  int _totalActivities = 0;
  double _completionRate = 0.0;

  // Enhanced with calm progress data
  int _calmSessions = 0;
  int _calmStreak = 0;
  String _displayTitle = '';
  String _displayMessage = '';
  String _progressColor = '#6B7280';

  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  // Prevent build-triggered reload loops when the stream updates.
  int? _lastTodayCompletionsCount;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to routine completions stream for real-time updates
    return StreamBuilder<List<String>>(
      stream: ref
          .watch(routineServiceProvider)
          .getTodayCompletedActivitiesStream(widget.userId),
      builder: (context, completionSnapshot) {
        // Reload only when the completion count actually changes.
        final currentCount = completionSnapshot.data?.length;
        if (currentCount != null && currentCount != _lastTodayCompletionsCount) {
          _lastTodayCompletionsCount = currentCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadData();
          });
        }

        if (_isLoading) {
          return _buildLoadingSkeleton();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayTitle.isNotEmpty
                              ? _displayTitle
                              : _getTitle(),
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _displayMessage.isNotEmpty
                              ? _displayMessage
                              : _getMessage(),
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildProgressRing(),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('🔥', _streak.toString(), 'Streak'),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _buildStat('📊', _weeklyActivities.toString(), 'This Week'),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _buildStat('🧘', _calmSessions.toString(), 'Calm'),
                ],
              ),
              if (widget.todayCheckInData != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Mood', widget.todayCheckInData!['mood'] ?? '-'),
                      _buildMiniStat('Sleep', '${widget.todayCheckInData!['sleepQuality'] ?? '-'}/10', icon: '🌙'),
                      _buildMiniStat('Energy', '${widget.todayCheckInData!['energyLevel'] ?? '-'}/10', icon: '⚡'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadData() async {
    try {
      final routineService = ref.read(routineServiceProvider);
      final weekCompletions = await routineService.getWeekCompletions(widget.userId);
      final todaySummary = await routineService.getTodayCompletionSummary(widget.userId);
      final allCompletions = await routineService.getAllCompletions(widget.userId);

      final weeklyCount = weekCompletions.fold<int>(
        0,
        (sum, completion) => sum + completion.completedActivities.length,
      );
      final todayCompleted = todaySummary['completed'] ?? 0;
      final todayTotal = todaySummary['total'] ?? 0;
      final allTimeTotal = allCompletions.fold<int>(
        0,
        (sum, completion) => sum + completion.completedActivities.length,
      );

      final currentStreak = await routineService.getCompletionStreak(widget.userId);

      int maxStreak = 0;
      int tempStreak = 0;
      final sortedCompletions = allCompletions.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      DateTime? lastDate;
      for (final completion in sortedCompletions) {
        final date = completion.date;
        final completed = completion.completedActivities.length;

        if (completed > 0) {
          if (lastDate == null || date.difference(lastDate).inDays == 1) {
            tempStreak++;
            maxStreak = math.max(maxStreak, tempStreak);
          } else if (date.difference(lastDate).inDays > 1) {
            tempStreak = 1;
          }
          lastDate = date;
        } else {
          tempStreak = 0;
        }
      }

      final rate = todayTotal > 0 ? todayCompleted / todayTotal : 0.0;

      final calmInsights = await ref
          .read(ecosystemIntegrationServiceProvider)
          .getCalmInsightsForDashboard(widget.userId);

      if (mounted) {
        setState(() {
          _streak = currentStreak;
          _bestStreak = maxStreak;
          _weeklyActivities = weeklyCount;
          _totalActivities = allTimeTotal;
          _completionRate = rate;

          _calmSessions = calmInsights['totalSessions'] as int? ?? 0;
          _calmStreak = calmInsights['currentStreak'] as int? ?? 0;
          _displayTitle = calmInsights['displayTitle'] as String? ?? _getTitle();
          _displayMessage = calmInsights['displayMessage'] as String? ?? _getMessage();
          _progressColor = calmInsights['progressColor'] as String? ?? '#6B7280';

          _isLoading = false;
        });

        _progressAnimation =
            Tween<double>(begin: _progressAnimation.value, end: rate).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
          ),
        );
        _animController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProgressRing() {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(70, 70),
                painter: _ProgressRingPainter(
                  progress: _progressAnimation.value,
                  color: _getProgressColor(),
                ),
              );
            },
          ),
          Text(
            '${(_completionRate * 100).toInt()}%',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 10,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    if (_streak >= 7) return '🔥 $_streak-Day Streak!';
    if (_streak >= 3) return '💪 $_streak Days Strong!';
    if (_streak == 0 && _bestStreak > 0) return '🌟 Ready for a Comeback?';
    if (_completionRate >= 0.8) return '⭐ Outstanding Week!';
    if (_totalActivities == 0) return '👋 Welcome!';
    return '📈 Keep Building!';
  }

  String _getMessage() {
    if (_streak >= 7) return 'Amazing consistency! Keep the momentum going.';
    if (_streak >= 3) return 'Great progress! You\'re building strong habits.';
    if (_streak == 0 && _bestStreak > 0) {
      return 'Your best was $_bestStreak days. Start fresh today!';
    }
    if (_completionRate >= 0.8) return 'You\'re crushing it this week!';
    if (_totalActivities == 0) {
      return 'Start your journey to better habits today.';
    }
    return 'Every step counts. Keep going!';
  }

  Color _getProgressColor() {
    // Use enhanced color from calm insights if available
    if (_progressColor != '#6B7280') {
      return Color(
        int.parse(_progressColor.substring(1), radix: 16) + 0xFF000000,
      );
    }

    // Fallback to original logic
    if (_completionRate >= 0.71) return const Color(0xFF10B981);
    if (_completionRate >= 0.31) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              3,
              (index) => Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {String? icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF374151),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 10,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}


